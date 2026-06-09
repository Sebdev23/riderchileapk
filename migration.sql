-- Tabla de ubicacion en tiempo real de usuarios (tipo Waze)
CREATE TABLE IF NOT EXISTS public.user_locations (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  lat DOUBLE PRECISION NOT NULL,
  lon DOUBLE PRECISION NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.user_locations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rls_ul_select" ON public.user_locations;
CREATE POLICY "rls_ul_select" ON public.user_locations
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "rls_ul_insert" ON public.user_locations;
CREATE POLICY "rls_ul_insert" ON public.user_locations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "rls_ul_update" ON public.user_locations;
CREATE POLICY "rls_ul_update" ON public.user_locations
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "rls_ul_delete" ON public.user_locations;
CREATE POLICY "rls_ul_delete" ON public.user_locations
  FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_user_locations_updated_at
  ON public.user_locations(updated_at);

-- RPC para obtener usuarios cercanos (filtro espacial real)
CREATE OR REPLACE FUNCTION public.nearby_user_locations(
  lat double precision,
  lon double precision,
  radius_km double precision DEFAULT 50,
  limit_count int DEFAULT 50
) RETURNS SETOF public.user_locations AS $$
  SELECT * FROM public.user_locations
  WHERE user_id != auth.uid()
    AND updated_at >= now() - interval '2 minutes'
  ORDER BY updated_at DESC
  LIMIT limit_count;
$$ LANGUAGE sql STABLE SECURITY DEFINER;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'user_locations') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_locations;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'alerts') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.alerts;
  END IF;
END $$;
