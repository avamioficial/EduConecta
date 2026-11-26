// Edge Function "registrar": crea la cuenta, el perfil y guarda el vector del rostro.
// En Supabase: apagar "Verify JWT with legacy secret" (la clave se valida aquí).
import { withSupabase } from 'npm:@supabase/server@1'

const UMBRAL_DUPLICADO = 0.4

function responderError(mensaje: string, status: number) {
  return Response.json({ error: mensaje }, { status })
}

export default {
  fetch: withSupabase({ auth: 'publishable' }, async (req, ctx) => {
    if (req.method !== 'POST') return responderError('Método no permitido', 405)

    let cuerpo: any
    try {
      cuerpo = await req.json()
    } catch {
      return responderError('JSON inválido', 400)
    }

    const nombre = String(cuerpo.nombre ?? '').trim()
    const pais = String(cuerpo.pais ?? '').trim()
    const correo = String(cuerpo.correo ?? '').trim().toLowerCase()
    const edad = Number(cuerpo.edad)
    const emb = cuerpo.embedding

    if (nombre.length < 1 || nombre.length > 100) return responderError('Nombre no válido', 400)
    if (pais.length < 1 || pais.length > 60) return responderError('País no válido', 400)
    if (!Number.isInteger(edad) || edad < 1 || edad > 120) return responderError('Edad no válida', 400)
    if (correo.length > 200 || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(correo)) {
      return responderError('Correo no válido', 400)
    }
    if (
      !Array.isArray(emb) ||
      emb.length !== 192 ||
      !emb.every((n) => typeof n === 'number' && Number.isFinite(n))
    ) {
      return responderError('Datos faciales no válidos', 400)
    }

    const vector = JSON.stringify(emb)
    const admin = ctx.supabaseAdmin

    // 1. ¿Este rostro ya está registrado?
    const { data: parecidos, error: errBusqueda } = await admin.rpc('buscar_rostro', {
      consulta: vector,
      umbral: UMBRAL_DUPLICADO,
    })
    if (errBusqueda) {
      console.error('buscar_rostro:', errBusqueda)
      return responderError('No se pudo verificar el rostro', 500)
    }
    if (parecidos && parecidos.length > 0) {
      return responderError('Este rostro ya está registrado', 409)
    }

    // 2. Crear la cuenta de acceso (sin contraseña ni correo de verificación)
    const { data: creado, error: errAuth } = await admin.auth.admin.createUser({
      email: correo,
      email_confirm: true,
    })
    if (errAuth || !creado?.user) {
      console.error('createUser:', errAuth)
      const yaExiste =
        errAuth?.code === 'email_exists' || /already|registered/i.test(errAuth?.message ?? '')
      if (yaExiste) return responderError('Ese correo ya está registrado', 409)
      return responderError('No se pudo crear la cuenta', 500)
    }
    const usuarioId = creado.user.id

    // 3. Perfil del usuario
    const { error: errUsuario } = await admin
      .from('usuarios')
      .insert({ id: usuarioId, nombre, edad, pais, correo })
    if (errUsuario) {
      console.error('insert usuarios:', errUsuario)
      await admin.auth.admin.deleteUser(usuarioId)
      return responderError('No se pudo crear el usuario', 500)
    }

    // 4. Vector del rostro
    const { error: errRostro } = await admin
      .from('rostros')
      .insert({ usuario_id: usuarioId, embedding: vector })
    if (errRostro) {
      console.error('insert rostros:', errRostro)
      await admin.auth.admin.deleteUser(usuarioId) // borra también el perfil
      return responderError('No se pudo guardar el rostro', 500)
    }

    return Response.json({ ok: true, usuario_id: usuarioId })
  }),
}
