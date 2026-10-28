import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// These are the same public client settings used by the Flutter application.
export const supabase = createClient(
  'https://xsehqejkzjnlhoniozxb.supabase.co',
  'sb_publishable_uqT0sdPo5cwm-grSyI6-Ig_xphbjwCC',
);
