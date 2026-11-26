-- ============================================================
-- Educonecta: esquema de base de datos (Supabase / PostgreSQL)
-- Ejecutar en el SQL Editor de un proyecto nuevo.
--
-- Antes, al crear el proyecto en Supabase:
--   * Enable Data API: activado
--   * Automatically expose new tables: DESACTIVADO
--   * Enable automatic RLS: ACTIVADO
-- ============================================================

create extension if not exists vector;

-- ------------------------------------------------------------
-- Tablas
-- ------------------------------------------------------------

-- Perfil del estudiante. El id es el mismo de su cuenta en Supabase Auth.
create table public.usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  nombre text not null,
  edad int not null check (edad > 0),
  pais text not null,
  correo text unique,
  creado_en timestamptz default now()
);

-- Vector del rostro (192 números). No se guardan fotos.
create table public.rostros (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  embedding vector(192) not null,
  creado_en timestamptz default now()
);

-- Mejor resultado de cada lección por usuario.
create table public.progreso (
  usuario_id uuid not null references public.usuarios(id) on delete cascade,
  nivel int not null check (nivel > 0),
  leccion int not null check (leccion > 0),
  aciertos int not null check (aciertos >= 0),
  total int not null check (total > 0),
  actualizado_en timestamptz not null default now(),
  primary key (usuario_id, nivel, leccion),
  check (aciertos <= total)
);

-- ------------------------------------------------------------
-- Seguridad
-- ------------------------------------------------------------

alter table public.usuarios enable row level security;
alter table public.rostros enable row level security;
alter table public.progreso enable row level security;

-- La app (anon / authenticated) no toca usuarios ni rostros directamente.
revoke all on public.usuarios from anon, authenticated;
revoke all on public.rostros from anon, authenticated;

-- Las funciones del servidor (clave secret = rol service_role) sí.
grant select, insert, update, delete on public.usuarios to service_role;
grant select, insert, update, delete on public.rostros to service_role;

-- Un usuario con sesión puede ver su propio perfil.
grant select on public.usuarios to authenticated;
create policy "ver mi perfil"
on public.usuarios for select to authenticated
using (id = (select auth.uid()));

-- Un usuario con sesión solo ve y guarda su propio progreso.
grant select, insert, update on public.progreso to authenticated;

create policy "ver mi progreso"
on public.progreso for select to authenticated
using (usuario_id = (select auth.uid()));

create policy "guardar mi progreso"
on public.progreso for insert to authenticated
with check (usuario_id = (select auth.uid()));

create policy "actualizar mi progreso"
on public.progreso for update to authenticated
using (usuario_id = (select auth.uid()))
with check (usuario_id = (select auth.uid()));

-- ------------------------------------------------------------
-- Funciones
-- ------------------------------------------------------------

-- Busca el rostro más parecido (distancia coseno = 1 - similitud).
-- Solo la usan las funciones del servidor.
create or replace function public.buscar_rostro(
  consulta vector(192),
  umbral float default 0.4
)
returns table (usuario_id uuid, distancia float)
language sql stable
set search_path = public, extensions
as $$
  select r.usuario_id, (r.embedding <=> consulta)::float as distancia
  from rostros r
  where (r.embedding <=> consulta) < umbral
  order by r.embedding <=> consulta
  limit 1;
$$;

revoke execute on function public.buscar_rostro(vector, float) from public, anon, authenticated;
grant execute on function public.buscar_rostro(vector, float) to service_role;

-- Guarda el progreso de una lección conservando el mejor resultado.
create or replace function public.guardar_progreso(
  p_nivel int, p_leccion int, p_aciertos int, p_total int
)
returns void
language sql
set search_path = public
as $$
  insert into progreso (usuario_id, nivel, leccion, aciertos, total)
  values ((select auth.uid()), p_nivel, p_leccion, p_aciertos, p_total)
  on conflict (usuario_id, nivel, leccion)
  do update set
    aciertos = greatest(progreso.aciertos, excluded.aciertos),
    total = excluded.total,
    actualizado_en = now();
$$;

revoke execute on function public.guardar_progreso(int, int, int, int) from public, anon;
grant execute on function public.guardar_progreso(int, int, int, int) to authenticated;
