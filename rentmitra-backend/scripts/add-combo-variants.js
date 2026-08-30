// One-off script: adds the 4 new Combo Plan variants for the redesigned
// Combo Plans page (Smart Living / Family Essentials / Premium Family /
// Ultimate Premium). Idempotent — safe to re-run, skips variants that
// already exist by name under product_id 4 ("Combo Plan").
const pool = require('../src/database.js');

const COMBO_PRODUCT_ID = 4;

const newVariants = [
  { variant_name: 'Smart Living Combo', monthly_rent: 2337 },
  { variant_name: 'Family Essentials Combo', monthly_rent: 2112 },
  { variant_name: 'Premium Family Combo', monthly_rent: 2382 },
  { variant_name: 'Ultimate Premium Combo', monthly_rent: 2607 },
];

async function run() {
  for (const v of newVariants) {
    const result = await pool.query(
      `INSERT INTO product_variants (product_id, variant_name, monthly_rent)
       SELECT $1::int, $2::text, $3::numeric
       WHERE NOT EXISTS (
         SELECT 1 FROM product_variants
         WHERE product_id = $1::int AND variant_name = $2::text
       )
       RETURNING variant_id, variant_name, monthly_rent`,
      [COMBO_PRODUCT_ID, v.variant_name, v.monthly_rent]
    );

    if (result.rows.length > 0) {
      console.log('Inserted:', result.rows[0]);
    } else {
      console.log('Already exists, skipped:', v.variant_name);
    }
  }

  const final = await pool.query(
    'SELECT variant_id, product_id, variant_name, monthly_rent, is_active FROM product_variants WHERE product_id = $1 ORDER BY variant_id',
    [COMBO_PRODUCT_ID]
  );
  console.table(final.rows);
  process.exit(0);
}

run().catch((err) => {
  console.error('Failed:', err.message);
  process.exit(1);
});
