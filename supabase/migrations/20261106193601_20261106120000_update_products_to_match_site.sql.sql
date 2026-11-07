-- Update products to match the actual website tiers:
-- Free, LITTX+, LITTX Ultimate (replacing littx-fire)
-- The site has 3 JAR files: free, plus, ultimate

-- Update the "littx-fire" product to "littx-ultimate"
UPDATE products SET slug = 'littx-ultimate', name = 'LITTX Ultimate', description = 'The advanced membership tier with v2.0.0 Ultimate edition client.' WHERE slug = 'littx-fire';

-- Update plans for the ultimate product
UPDATE plans SET 
  duration_type = '30_days',
  price_usd = 15.00,
  display_price = '$15',
  name = 'LITTX Ultimate — 30 Days',
  sort_order = 3
WHERE product_id = (SELECT id FROM products WHERE slug = 'littx-ultimate') AND duration_type = '30_days';

UPDATE plans SET 
  duration_type = 'forever',
  price_usd = 50.00,
  display_price = '$50',
  name = 'LITTX Ultimate — Forever',
  sort_order = 4
WHERE product_id = (SELECT id FROM products WHERE slug = 'littx-ultimate') AND duration_type = 'forever';

-- Update entitlements product_slug references from littx-fire to littx-ultimate
UPDATE entitlements SET product_slug = 'littx-ultimate' WHERE product_slug = 'littx-fire';
UPDATE vouchers SET product_slug = 'littx-ultimate' WHERE product_slug = 'littx-fire';

-- Update the check constraint on releases to allow 'littx-ultimate' instead of 'littx-fire'
ALTER TABLE releases DROP CONSTRAINT IF EXISTS releases_required_plan_check;
ALTER TABLE releases ADD CONSTRAINT releases_required_plan_check 
  CHECK (required_plan IN ('free', 'littx-plus', 'littx-ultimate'));

-- Update any existing releases with littx-fire to littx-ultimate
UPDATE releases SET required_plan = 'littx-ultimate' WHERE required_plan = 'littx-fire';

-- Update the get_release_download_info function to use littx-ultimate
CREATE OR REPLACE FUNCTION get_release_download_info(p_release_id uuid, p_user_id uuid DEFAULT NULL)
RETURNS TABLE (
  id uuid,
  version_number text,
  file_name text,
  storage_path text,
  file_size_bytes bigint,
  required_plan text,
  can_download boolean,
  error text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_release releases%ROWTYPE;
  v_can_download boolean := false;
  v_error text := null;
BEGIN
  SELECT * INTO v_release FROM releases WHERE id = p_release_id AND is_published = true;

  IF NOT FOUND THEN
    RETURN QUERY SELECT NULL::uuid, NULL::text, NULL::text, NULL::text, NULL::bigint, NULL::text, false::boolean, 'Release not found'::text;
    RETURN;
  END IF;

  IF v_release.required_plan = 'free' THEN
    v_can_download := true;
  ELSIF p_user_id IS NULL THEN
    v_can_download := false;
    v_error := 'LOCKED:' || v_release.required_plan;
  ELSE
    IF v_release.required_plan = 'littx-plus' THEN
      SELECT EXISTS(
        SELECT 1 FROM entitlements
        WHERE user_id = p_user_id
          AND product_slug IN ('littx-plus', 'littx-ultimate')
          AND is_active = true
          AND (expires_at IS NULL OR expires_at > now())
      ) INTO v_can_download;
      IF NOT v_can_download THEN
        v_error := 'LOCKED:littx-plus';
      END IF;
    ELSIF v_release.required_plan = 'littx-ultimate' THEN
      SELECT EXISTS(
        SELECT 1 FROM entitlements
        WHERE user_id = p_user_id
          AND product_slug = 'littx-ultimate'
          AND is_active = true
          AND (expires_at IS NULL OR expires_at > now())
      ) INTO v_can_download;
      IF NOT v_can_download THEN
        v_error := 'LOCKED:littx-ultimate';
      END IF;
    END IF;
  END IF;

  RETURN QUERY SELECT
    v_release.id,
    v_release.version_number,
    v_release.file_name,
    CASE WHEN v_can_download THEN v_release.storage_path ELSE NULL END,
    v_release.file_size_bytes,
    v_release.required_plan,
    v_can_download,
    v_error;
END;
$$;

REVOKE EXECUTE ON FUNCTION get_release_download_info(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_release_download_info(uuid, uuid) TO authenticated, anon;
