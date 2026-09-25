// EGT backend — development seed script.
// ---------------------------------------------------------------------------
// DEV-ONLY. Refuses to run unless NODE_ENV is unset, "development" or "test".
// Never auto-runs in production (package.json maps `prisma.seed` only for
// `prisma migrate dev` / explicit `npm run prisma:seed`).
//
// Product data comes EXCLUSIVELY from docs/site-audit.md (Phase 0). The three
// unverified compliance claims flagged in the audit ("ISO 9001 & GMP",
// "FSSAI, APEDA & Phytosanitary", "APEDA & Global G.A.P.") are NOT seeded —
// the audit explicitly forbids propagating them into the app.
import { PrismaClient, RoleName } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient();

const NODE_ENV = process.env.NODE_ENV || 'development';
if (NODE_ENV === 'production') {
  console.error('REFUSING to seed: NODE_ENV=production. Seeds are dev-only.');
  process.exit(1);
}

type SeedProduct = {
  name: string;
  category: string;
  specs: string[];
  orderVolume: string;
  image?: string;
  imageAlt?: string;
};

// Categories — exact names as shown on the live site (site-audit.md §3).
const CATEGORIES = [
  'Industrial Supplies & Textiles',
  'Commercial Kitchen & FMCG',
  'Automotive Cleaning & Detailing',
  'Automotive Care & Detailing',
  'Industrial & Heavy Maintenance',
  'Commercial Floor & Facility Care',
  'Sanitary & Commercial Hygiene',
  'Commercial & Consumer Laundry',
  'Agricultural & Energy Commodities',
  'Food & Agricultural Commodities',
  'Fresh Produce & Agri Commodities',
  'Organic Farming & Soil Nutrition',
];

// Products — names, categories, spec bullets and order volumes are VERBATIM
// from the live site audit (site-audit.md §3). No prices are published on the
// site, so none are seeded. Certification bullets flagged as unverified in the
// audit are excluded (see header comment).
const PRODUCTS: SeedProduct[] = [
  {
    name: 'Cotton Wiping / Cleaning Rags',
    category: 'Industrial Supplies & Textiles',
    specs: [
      '100% Pure Recycled Cotton',
      'High Absorbency (Oil & Solvents)',
      'Bleached White & Color Mix Grades',
      'Lint-Free & Washed Quality',
      'Custom Bale Packing (10kg/25kg/50kg)',
    ],
    orderVolume: '500 KG / 20ft FCL Bulk',
    image: 'products/wiping-rags-800.webp',
    imageAlt: 'Cotton wiping / cleaning rags',
  },
  {
    name: 'Dr. Clenzol Concentrated Dishwash Liquid',
    category: 'Commercial Kitchen & FMCG',
    // NOTE: "ISO 9001 & GMP Certified Formulation" appears on products.php only
    // and is flagged unverified in the audit — excluded from the seed.
    specs: [
      'pH 7.0–7.5 Skin-Safe Neutral',
      '18% Active Matter Power',
      'Enzyme-Active Tough Grease Release',
      'Fresh Lemon & Kaffir Lime Aroma',
    ],
    orderVolume: '500 L / 1 Pallet Minimum',
    image: 'products/dishwash/DW.png',
    imageAlt: 'Dr. Clenzol concentrated dishwash liquid',
  },
  {
    name: 'Hyper-Foam Snow Car Wash Shampoo',
    category: 'Automotive Cleaning & Detailing',
    specs: [
      'High-Density Thick Snow Foam',
      'pH Balanced (Safe for Ceramic/PPF)',
      'Spot-Free Clean Sheeting Rinse',
      '1:200 High Dilution Ratio',
      'Zero Harsh Acids or Solvents',
    ],
    orderVolume: '500 L / 50 Cartons',
    image: 'products/car-wash/CC.png',
    imageAlt: 'Hyper-Foam snow car wash shampoo',
  },
  {
    name: 'Hydro-Shield Carnauba Liquid Wax',
    category: 'Automotive Care & Detailing',
    specs: [
      'Pure T1 Brazilian Carnauba Wax',
      '90+ Day Hydrophobic Water Beading',
      'Deep Optical Wet-Look Mirror Gloss',
      'UV-A & UV-B Radiation Barrier',
      'Easy On / Easy Buff Non-Dusting',
    ],
    orderVolume: '250 L / 500 Bottles',
    image: 'products/premium-liquid-wax/photo-1.jpg',
    imageAlt: 'Hydro-Shield carnauba liquid wax',
  },
  {
    name: 'Ultra-Slick Tyre Polish & Conditioner',
    category: 'Automotive Care & Detailing',
    specs: [
      'Deep Jet-Black Showroom Satin Gloss',
      'Anti-Cracking & UV Ozone Protection',
      'Zero Sling High-Adhesion Formula',
      'Dust & Road Grime Repellent',
      'Safe for Rubber & Vinyl Sidewalls',
    ],
    orderVolume: '500 Bottles / 250 L',
    image: 'products/tyre-polish/photo-1.jpg',
    imageAlt: 'Ultra-Slick tyre polish & conditioner',
  },
  {
    name: 'Anti-Static Dashboard & Leather Polish',
    category: 'Automotive Care & Detailing',
    specs: [
      'Anti-Static Active Dust Repellent',
      'UV Sunblock Prevents Fading & Cracking',
      'Non-Greasy Natural Satin Finish',
      'Subtle Refreshing Lavender Scent',
      'Safe on Leather, PU, Vinyl & Plastic',
    ],
    orderVolume: '500 Units / 250 L',
    image: 'products/dashboard-polish/photo-1.jpg',
    imageAlt: 'Anti-static dashboard & leather polish',
  },
  {
    name: 'Pro-Industrial Engine Degreaser',
    category: 'Industrial & Heavy Maintenance',
    specs: [
      'Rapid Penetration on Baked Grease & Sludge',
      'Water-Emulsifying Clean Rinse Formula',
      'Non-Corrosive to Aluminum & Copper',
      'Safe on Rubber Hoses & Engine Gaskets',
      'Industrial Fleet & Workshop Approved',
    ],
    orderVolume: '500 L / 25 Cartons',
    image: 'products/engine-degreaser/photo-1.jpg',
    imageAlt: 'Pro-industrial engine degreaser',
  },
  {
    name: 'Dr. Clenzol Multi-Surface Floor Cleaner',
    category: 'Commercial Floor & Facility Care',
    // NOTE: "99.9% Antibacterial Sanitization" is a site claim flagged as
    // must-not-propagate without evidence in the audit — excluded from seed.
    specs: [
      'Zero Residue Quick-Drying Formula',
      'Citrus, Pine, Rose & Jasmine Fragrances',
      'Safe on Polished Marble, Granite & Vinyl',
      'High Economy 1:50 Dilution Ratio',
    ],
    orderVolume: '1,000 L / 1 FCL Option',
    image: 'products/floor-cleaner/FC.png',
    imageAlt: 'Dr. Clenzol multi-surface floor cleaner',
  },
  {
    name: 'Dr. Clenzol Power-Thick Toilet Cleaner',
    category: 'Sanitary & Commercial Hygiene',
    // NOTE: "Kills 99.9% Pathogenic Germs & Odors" flagged in audit — excluded.
    specs: [
      'High Viscosity 10x Clinging Power',
      'Limescale, Yellowing & Rust Eradication',
      'Angled Precision Pouring Nozzle',
      'Deep Ocean Blue & Citrus Variants',
    ],
    orderVolume: '1,000 Bottles / 500 L',
    // Image path not extractable in the audit — no image seeded.
  },
  {
    name: 'Fabric-Care Liquid Laundry Detergent',
    category: 'Commercial & Consumer Laundry',
    specs: [
      'Triple Enzyme Stain-Lift Technology',
      'Color-Lock Protection Prevents Fading',
      'Front & Top Load Washing Machine Safe',
      'Soft Breeze Long-Lasting Fragrance',
      'Phosphate-Free & Biodegradable',
    ],
    orderVolume: '1,000 L / 50 Cartons',
    // Image path not extractable in the audit — no image seeded.
  },
  {
    name: 'Heavy-Duty Bathroom & Tile Cleaner',
    category: 'Commercial Floor & Facility Care',
    specs: [
      'Instant Soap Scum & Hard Water Removal',
      'Chrome, Ceramic & Grout Safe',
      'Active Foaming Trigger Action',
      'Floral Deodorizing Fragrance',
      'Commercial Janitorial Grade',
    ],
    orderVolume: '500 L / 50 Cartons',
    image: 'products/bathroom-cleaner/BC.png',
    imageAlt: 'Heavy-duty bathroom & tile cleaner',
  },
  {
    name: 'Crystal-Clear Streak-Free Glass Cleaner',
    category: 'Commercial Floor & Facility Care',
    specs: [
      'Ammonia-Free Crystal Clarity',
      'Ultra-Fast Evaporating Zero-Streak',
      'Anti-Fogging & Anti-Static Shield',
      'Safe on Tinted Auto Glass & Screens',
      'Refreshing Ocean Mist Scent',
    ],
    orderVolume: '500 L / 50 Cartons',
    // Image path not extractable in the audit — no image seeded.
  },
  {
    name: 'High-Calorie Biomass Fuel Pellets',
    category: 'Agricultural & Energy Commodities',
    specs: [
      'Gross Calorific Value: 4200–4600 kcal/kg',
      'Low Moisture Content (< 8%)',
      'Low Ash Residue (< 2.5%)',
      'High Bulk Density (650 kg/m³)',
      '100% Eco-Friendly & Carbon Neutral',
    ],
    orderVolume: '20 MT (1 x 20ft FCL)',
    image: 'products/biomass-fuel.jpg',
    imageAlt: 'High-calorie biomass fuel pellets',
  },
  {
    name: 'Premium Sharbati Wheat Flour (Atta & Maida)',
    category: 'Food & Agricultural Commodities',
    // NOTE: "FSSAI, APEDA & Phytosanitary Certified" appears on products.php
    // only and is flagged unverified in the audit — excluded from the seed.
    specs: [
      'High Protein Content (11.5% – 12.8%)',
      'Wet Gluten: 28% – 32%',
      'Moisture Content (< 13.0%)',
      '100% Sortex Cleaned Sharbati Grain',
    ],
    orderVolume: '24 MT (1 x 20ft FCL)',
    image: 'products/wheat.jpg',
    imageAlt: 'Premium Sharbati wheat flour (atta & maida)',
  },
  {
    name: 'Export-Grade Fresh Table & Processing Potatoes',
    category: 'Fresh Produce & Agri Commodities',
    // NOTE: "APEDA & Global G.A.P. Certified Farms" appears on products.php
    // only and is flagged unverified in the audit — excluded from the seed.
    specs: [
      'Caliber Sizes: 45mm+, 50mm+, 55mm+',
      'Varieties: Lady Rosetta, Kufri Jyoti, Chipsona',
      'Zero Sprouts & Soil Washed / Dry Cleaned',
      'Reefer Container Maintained at +8°C',
    ],
    orderVolume: '28 MT (1 x 20ft FCL)',
    image: 'products/potatoes.jpg',
    imageAlt: 'Export-grade fresh table & processing potatoes',
  },
  {
    name: 'Organic Composted Cow Dung Manure Powder',
    category: 'Organic Farming & Soil Nutrition',
    specs: [
      '100% Pure Aged Natural Organic Compost',
      'NPK Enriched (N: 1.5%, P: 1.0%, K: 1.2%)',
      'Weed-Seed Free & Pathogen Sanitized',
      'Fine Screened Powder (Moisture < 18%)',
      'Certified Organic Soil Conditioner',
    ],
    orderVolume: '18 MT (1 x 20ft FCL)',
    image: 'products/cow-dung-powder/photo-2.jpg',
    imageAlt: 'Organic composted cow dung manure powder',
  },
];

// Test users. Documented dev passwords ONLY — change before any shared
// environment; never valid in production.
const TEST_USERS = [
  { email: 'buyer@example.com', password: 'Buyer#12345', fullName: 'Dev Buyer', role: 'buyer' as RoleName },
  { email: 'buyer2@example.com', password: 'Buyer#12345', fullName: 'Dev Buyer Two', role: 'buyer' as RoleName },
  { email: 'supplier@example.com', password: 'Supplier#12345', fullName: 'Dev Supplier', role: 'supplier' as RoleName },
  { email: 'staff@example.com', password: 'Staff#12345', fullName: 'Dev Staff', role: 'staff' as RoleName },
  { email: 'admin@example.com', password: 'Admin#12345', fullName: 'Dev Admin', role: 'admin' as RoleName },
];

const PERMISSIONS: [string, string][] = [
  ['rfq.create', 'Create RFQs'],
  ['rfq.read.own', 'Read own RFQs'],
  ['rfq.read.all', 'Read all RFQs'],
  ['rfq.transition', 'Move RFQs through lifecycle'],
  ['quote.create', 'Create quotes (staff)'],
  ['quote.accept', 'Accept own RFQ quotes (buyer)'],
  ['quote.revise', 'Request quote revision (buyer)'],
  ['order.read.own', 'Read own orders'],
  ['order.read.all', 'Read all orders'],
  ['shipment.create', 'Create shipments (staff)'],
  ['shipment.update', 'Update shipment status/events'],
  ['document.upload', 'Upload documents'],
  ['document.read.own', 'Download own documents'],
  ['supplier.listing.create', 'Submit supplier product listings'],
  ['supplier.listing.review', 'Review supplier listings (staff)'],
  ['support.ticket.create', 'Open support tickets'],
  ['admin.users.manage', 'Manage users'],
  ['admin.audit.read', 'Read audit log'],
  ['admin.catalog.manage', 'Manage product catalogue'],
];

function slugify(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

async function main() {
  console.log(`Seeding EGT backend (NODE_ENV=${NODE_ENV})…`);

  // Roles
  const roles: Record<RoleName, string> = {} as Record<RoleName, string>;
  for (const name of Object.values(RoleName)) {
    const role = await prisma.role.upsert({
      where: { name },
      update: {},
      create: { name, description: `${name} role` },
    });
    roles[name] = role.id;
  }

  // Permissions
  for (const [key, description] of PERMISSIONS) {
    const perm = await prisma.permission.upsert({
      where: { key },
      update: {},
      create: { key, description },
    });
    // Admin and staff get everything; buyer/supplier get their scoped sets.
    const roleNames: RoleName[] =
      key.startsWith('admin.') || key === 'rfq.read.all' || key === 'order.read.all'
        ? ['admin']
        : key === 'rfq.transition' || key === 'quote.create' || key === 'shipment.create'
          || key === 'shipment.update' || key === 'supplier.listing.review' || key === 'admin.catalog.manage'
          ? ['admin', 'staff']
          : key === 'supplier.listing.create'
            ? ['supplier', 'admin', 'staff']
            : key === 'rfq.create' || key === 'rfq.read.own' || key === 'quote.accept'
              || key === 'quote.revise' || key === 'order.read.own' || key === 'document.upload'
              || key === 'document.read.own' || key === 'support.ticket.create'
              ? ['buyer', 'supplier', 'admin', 'staff']
              : ['admin'];
    for (const rn of roleNames) {
      await prisma.rolePermission.upsert({
        where: { roleId_permissionId: { roleId: roles[rn], permissionId: perm.id } },
        update: {},
        create: { roleId: roles[rn], permissionId: perm.id },
      });
    }
  }

  // Categories
  const categoryIds: Record<string, string> = {};
  for (const [i, name] of CATEGORIES.entries()) {
    const cat = await prisma.category.upsert({
      where: { slug: slugify(name) },
      update: { name, sortOrder: i },
      create: { name, slug: slugify(name), sortOrder: i },
    });
    categoryIds[name] = cat.id;
  }

  // Products — upsert by slug; never delete existing ones.
  for (const [i, p] of PRODUCTS.entries()) {
    const slug = slugify(p.name);
    const product = await prisma.product.upsert({
      where: { slug },
      update: {
        name: p.name,
        categoryId: categoryIds[p.category],
        orderVolume: p.orderVolume,
        sortOrder: i,
      },
      create: {
        name: p.name,
        slug,
        categoryId: categoryIds[p.category],
        shortDescription: p.specs[0],
        orderVolume: p.orderVolume,
        sortOrder: i,
      },
    });
    // Specs: replace set to keep them exactly in sync with the audit.
    await prisma.productSpecification.deleteMany({ where: { productId: product.id } });
    for (const [j, text] of p.specs.entries()) {
      await prisma.productSpecification.create({
        data: { productId: product.id, text, sortOrder: j },
      });
    }
    // Images: keep single seeded image per product when a path exists.
    await prisma.productImage.deleteMany({ where: { productId: product.id } });
    if (p.image) {
      await prisma.productImage.create({
        data: {
          productId: product.id,
          url: p.image,
          alt: p.imageAlt ?? p.name,
          sortOrder: 0,
        },
      });
    }
  }

  // Test users
  const created: string[] = [];
  for (const u of TEST_USERS) {
    const existing = await prisma.user.findUnique({ where: { email: u.email } });
    if (existing) continue;
    await prisma.user.create({
      data: {
        email: u.email,
        passwordHash: await argon2.hash(u.password, { type: argon2.argon2id }),
        fullName: u.fullName,
        roleId: roles[u.role],
        emailVerifiedAt: new Date(),
      },
    });
    created.push(`${u.email} / ${u.password}`);
  }

  const productCount = await prisma.product.count();
  console.log(`Seed complete: ${productCount} products, roles=${Object.keys(roles).length}.`);
  if (created.length) {
    console.log('Test users (dev only):');
    for (const c of created) console.log(`  ${c}`);
  } else {
    console.log('Test users already existed — skipped.');
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
