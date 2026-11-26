// Edge Function "ingresar": reconoce el rostro y entrega un código de un solo uso
// que la app canjea por una sesión de Supabase Auth.
// En Supabase: apagar "Verify JWT with legacy secret" (la clave se valida aquí).
//
// Nota: durante las pruebas la versión desplegada usó un umbral temporal de 0.5.
// El valor recomendado es 0.4; ajústalo con pruebas de varias personas.
import { withSupabase } from 'npm:@supabase/server@1'

// Distancia máxima aceptada (equivale a similitud mínima de 0.6)
const UMBRAL_INGRESO = 0.4

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

    const emb = cuerpo.embedding
    if (
      !Array.isArray(emb) ||
      emb.length !== 192 ||
      !emb.every((n) => typeof n === 'number' && Number.isFinite(n))
    ) {
      return responderError('Datos faciales no válidos', 400)
    }

    const admin = ctx.supabaseAdmin

    const { data: coincidencias, error: errBusqueda } = await admin.rpc('buscar_rostro', {
      consulta: JSON.stringify(emb),
      umbral: UMBRAL_INGRESO,
    })
    if (errBusqueda) {
      console.error('buscar_rostro:', errBusqueda)
      return responderError('No se pudo verificar el rostro', 500)
    }
    if (!coincidencias || coincidencias.length === 0) {
      return responderError('No se reconoció el rostro', 401)
    }

    const { data: usuario, error: errUsuario } = await admin
      .from('usuarios')
      .select('id, nombre, correo')
      .eq('id', coincidencias[0].usuario_id)
      .single()
    if (errUsuario || !usuario) {
      console.error('select usuarios:', errUsuario)
      return responderError('No se pudo obtener el usuario', 500)
    }

    // Código de un solo uso que la app canjea por una sesión (no envía correo)
    const { data: enlace, error: errEnlace } = await admin.auth.admin.generateLink({
      type: 'magiclink',
      email: usuario.correo,
    })
    const tokenHash = enlace?.properties?.hashed_token
    if (errEnlace || !tokenHash) {
      console.error('generateLink:', errEnlace)
      return responderError('No se pudo iniciar la sesión', 500)
    }

    return Response.json({
      ok: true,
      usuario: { id: usuario.id, nombre: usuario.nombre },
      token_hash: tokenHash,
    })
  }),
}
