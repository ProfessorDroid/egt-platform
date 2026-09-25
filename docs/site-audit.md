# EGT Site Audit — Phase 0 (single source of truth)

Audited 2026-09-25 (IST) against the live site https://eaglegoodstrading.com/ via page-text fetch + HTTP status checks + CSS/asset downloads.
**Ground rule applied:** only facts observed on the live site are recorded below. Anything unverified is flagged, never invented.

---

## 1. Page Inventory

Sitemap (https://eaglegoodstrading.com/sitemap.xml) lists 15 URLs. Live HTTP status of each (verified via fetch service AND curl with browser UA):

| # | Route | Sitemap? | Live status | Notes |
|---|-------|----------|-------------|-------|
| 1 | `/` + `index.php` | yes | **200** | Homepage, full render |
| 2 | `products.php` | yes | **200** | Featured export product catalogue |
| 3 | `quote.php` | yes | **200** | RFQ form ("Full Name *" title) |
| 4 | `earn-with-egt.php` | yes | **200** | Earn with EGT youth partner page |
| 5 | `contact.php` | yes | **200** | Contact page + enquiry form |
| 6 | `partner-dashboard.php` | no (not in sitemap) | **200** | Referral-code-gated partner dashboard |
| 7 | `about.php` | yes | **500** | In sitemap but server errors |
| 8 | `catalogue.php` | yes | **500** | In sitemap but server errors |
| 9 | `oem-private-label.php` | yes | **500** | In sitemap but server errors |
| 10 | `sourcing-process.php` | yes | **500** | In sitemap but server errors |
| 11 | `quality-control.php` | yes | **500** | In sitemap but server errors |
| 12 | `shipping-documentation.php` | yes | **500** | In sitemap but server errors |
| 13 | `faq.php` | yes | **500** | In sitemap but server errors |
| 14 | `privacy-policy.php` | yes | **500** | In sitemap but server errors |
| 15 | `terms-and-conditions.php` | yes | **500** | In sitemap but server errors |
| 16 | `refer-and-earn.html` | no | **404** | Never built; Earn page links earn-with-egt.php instead |
| 17 | `dropshipping.php` | no | **404** | No dropshipping page exists |
| 18 | `track-order.php` | no | **404** | No shipment/order tracking exists |
| 19 | `login.php` / `my-account.php` | no | **404** | No customer account/login exists |

**Critical finding:** 9 of the 15 sitemap-listed pages return HTTP 500 to both the text-fetch service and direct curl. This looks like a live server-side fault (broken shared include / PHP fatal), not a crawler quirk — the homepage text itself references content that lives on those pages. Treat About, OEM/Private Label, Sourcing Process, Quality Control, Shipping/Documentation, FAQ, Catalogue, Privacy Policy and Terms as **currently broken until re-verified**.

---

## 2. Navigation

Main header nav link text was not exposed by the page-text extraction on any fetched page, so the exact menu order could not be captured from render. The routes the site presents (sitemap + visible CTAs + footer-linked pages):

- Home (`/`, `index.php`)
- Products (`products.php`)
- Catalogue (`catalogue.php` — currently 500)
- Earn with EGT (`earn-with-egt.php`)
- Sourcing Process (`sourcing-process.php` — 500)
- OEM & Private Label (`oem-private-label.php` — 500)
- FAQ (`faq.php` — 500)
- Contact (`contact.php`)
- Request Quote / RFQ (`quote.php`)
- Partner Dashboard (`partner-dashboard.php` — referral-code gated; not in sitemap)

**Gap:** exact nav menu items/order and footer column structure could not be extracted from page text (header/footer link lists were skipped by extraction). Re-capture with a real browser session before finalizing app IA.

---

## 3. Product Catalogue (16 products on products.php; same 16 on homepage)

Each card shows: category tag, product name, short description, 5 checkmark spec bullets, "ORDER VOLUME" (MOQ-style figure), "QUALITY ASSURANCE ✅ 100% Inspected", "⚡ Express Sample" and "📈 Wholesale Margin" badges. No prices are published anywhere — "Click any product card for instant FOB/CIF pricing" opens a quotation modal.

**Private label / customization:** stated site-wide rather than per product — "Custom Packaging & OEM Private label, bulk drums, IBC tanks & retail bottling" and "Not Listed? We Source It" card (private labelling, custom viscosity, bulk industrial drums). RFQ form has a "Private Label / Custom Packaging Required" checkbox. Sample availability: every card carries an "Express Sample" badge; homepage "Sample Supply Services: samples dispatched fast with complete documentation."

| # | Product name (exact) | Category (exact, as shown) | Spec bullets (verbatim) | Order volume (verbatim) | Image |
|---|----------------------|----------------------------|-------------------------|-------------------------|-------|
| 1 | Cotton Wiping / Cleaning Rags | Industrial Supplies & Textiles | 100% Pure Recycled Cotton; High Absorbency (Oil & Solvents); Bleached White & Color Mix Grades; Lint-Free & Washed Quality; Custom Bale Packing (10kg/25kg/50kg) | 500 KG / 20ft FCL Bulk | `products/wiping-rags-800.webp` |
| 2 | Dr. Clenzol Concentrated Dishwash Liquid | Commercial Kitchen & FMCG | pH 7.0–7.5 Skin-Safe Neutral; 18% Active Matter Power; Enzyme-Active Tough Grease Release; Fresh Lemon & Kaffir Lime Aroma; **ISO 9001 & GMP Certified Formulation** ⚠️ (products.php only — homepage shows "Compliance docs on request" instead) | 500 L / 1 Pallet Minimum | `products/dishwash/DW.png` |
| 3 | Hyper-Foam Snow Car Wash Shampoo | Automotive Cleaning & Detailing | High-Density Thick Snow Foam; pH Balanced (Safe for Ceramic/PPF); Spot-Free Clean Sheeting Rinse; 1:200 High Dilution Ratio; Zero Harsh Acids or Solvents | 500 L / 50 Cartons | `products/car-wash/CC.png` |
| 4 | Hydro-Shield Carnauba Liquid Wax | Automotive Care & Detailing | Pure T1 Brazilian Carnauba Wax; 90+ Day Hydrophobic Water Beading; Deep Optical Wet-Look Mirror Gloss; UV-A & UV-B Radiation Barrier; Easy On / Easy Buff Non-Dusting | 250 L / 500 Bottles | `products/premium-liquid-wax/photo-1.jpg` |
| 5 | Ultra-Slick Tyre Polish & Conditioner | Automotive Care & Detailing | Deep Jet-Black Showroom Satin Gloss; Anti-Cracking & UV Ozone Protection; Zero Sling High-Adhesion Formula; Dust & Road Grime Repellent; Safe for Rubber & Vinyl Sidewalls | 500 Bottles / 250 L | `products/tyre-polish/photo-1.jpg` |
| 6 | Anti-Static Dashboard & Leather Polish | Automotive Care & Detailing | Anti-Static Active Dust Repellent; UV Sunblock Prevents Fading & Cracking; Non-Greasy Natural Satin Finish; Subtle Refreshing Lavender Scent; Safe on Leather, PU, Vinyl & Plastic | 500 Units / 250 L | `products/dashboard-polish/photo-1.jpg` |
| 7 | Pro-Industrial Engine Degreaser | Industrial & Heavy Maintenance | Rapid Penetration on Baked Grease & Sludge; Water-Emulsifying Clean Rinse Formula; Non-Corrosive to Aluminum & Copper; Safe on Rubber Hoses & Engine Gaskets; Industrial Fleet & Workshop Approved | 500 L / 25 Cartons | `products/engine-degreaser/photo-1.jpg` |
| 8 | Dr. Clenzol Multi-Surface Floor Cleaner | Commercial Floor & Facility Care | 99.9% Antibacterial Sanitization; Zero Residue Quick-Drying Formula; Citrus, Pine, Rose & Jasmine Fragrances; Safe on Polished Marble, Granite & Vinyl; High Economy 1:50 Dilution Ratio | 1,000 L / 1 FCL Option | `products/floor-cleaner/FC.png` |
| 9 | Dr. Clenzol Power-Thick Toilet Cleaner | Sanitary & Commercial Hygiene | High Viscosity 10x Clinging Power; Limescale, Yellowing & Rust Eradication; Kills 99.9% Pathogenic Germs & Odors; Angled Precision Pouring Nozzle; Deep Ocean Blue & Citrus Variants | 1,000 Bottles / 500 L | image path not extractable (see Gaps) |
| 10 | Fabric-Care Liquid Laundry Detergent | Commercial & Consumer Laundry | Triple Enzyme Stain-Lift Technology; Color-Lock Protection Prevents Fading; Front & Top Load Washing Machine Safe; Soft Breeze Long-Lasting Fragrance; Phosphate-Free & Biodegradable | 1,000 L / 50 Cartons | image path not extractable |
| 11 | Heavy-Duty Bathroom & Tile Cleaner | Commercial Floor & Facility Care | Instant Soap Scum & Hard Water Removal; Chrome, Ceramic & Grout Safe; Active Foaming Trigger Action; Floral Deodorizing Fragrance; Commercial Janitorial Grade | 500 L / 50 Cartons | `products/bathroom-cleaner/BC.png` |
| 12 | Crystal-Clear Streak-Free Glass Cleaner | Commercial Floor & Facility Care | Ammonia-Free Crystal Clarity; Ultra-Fast Evaporating Zero-Streak; Anti-Fogging & Anti-Static Shield; Safe on Tinted Auto Glass & Screens; Refreshing Ocean Mist Scent | 500 L / 50 Cartons | image path not extractable |
| 13 | High-Calorie Biomass Fuel Pellets | Agricultural & Energy Commodities | Gross Calorific Value: 4200–4600 kcal/kg; Low Moisture Content (< 8%); Low Ash Residue (< 2.5%); High Bulk Density (650 kg/m³); 100% Eco-Friendly & Carbon Neutral | 20 MT (1 x 20ft FCL) | `products/biomass-fuel.jpg` |
| 14 | Premium Sharbati Wheat Flour (Atta & Maida) | Food & Agricultural Commodities | High Protein Content (11.5% – 12.8%); Wet Gluten: 28% – 32%; Moisture Content (< 13.0%); 100% Sortex Cleaned Sharbati Grain; **FSSAI, APEDA & Phytosanitary Certified** ⚠️ (products.php only — homepage shows "Compliance docs on request") | 24 MT (1 x 20ft FCL) | `products/wheat.jpg` |
| 15 | Export-Grade Fresh Table & Processing Potatoes | Fresh Produce & Agri Commodities | Caliber Sizes: 45mm+, 50mm+, 55mm+; Varieties: Lady Rosetta, Kufri Jyoti, Chipsona; Zero Sprouts & Soil Washed / Dry Cleaned; Reefer Container Maintained at +8°C; **APEDA & Global G.A.P. Certified Farms** ⚠️ (products.php only — homepage shows "Compliance docs on request") | 28 MT (1 x 40ft Reefer) | `products/potatoes.jpg` |
| 16 | Organic Composted Cow Dung Manure Powder | Organic Farming & Soil Nutrition | 100% Pure Aged Natural Organic Compost; NPK Enriched (N: 1.5%, P: 1.0%, K: 1.2%); Weed-Seed Free & Pathogen Sanitized; Fine Screened Powder (Moisture < 18%); Certified Organic Soil Conditioner | 18 MT (1 x 20ft FCL) | `products/cow-dung-powder/photo-2.jpg` |
| — | Not Listed? We Source It | Custom Procurement | "Need private labelling, custom viscosity, bulk industrial drums, or agricultural grade specifications not listed above? We source direct from certified manufacturers." | — | `products/not-listed.jpg` |

**Also on the site (not as product cards):** 12 "Featured Sectors" tiles on the homepage (Apparel & Garments; Textiles, Fabrics & Yarn; Home Textiles & Furnishings; Leather & Leather Products; Footwear & Shoes; Fashion & Lifestyle Accessories; Medical, Surgical & Healthcare Supplies; Pharmaceuticals & Wellness; Automotive Parts & Accessories; Engineering & Industrial Products; Machinery, Tools & Equipment; Electrical & Electronic Products). These are sourcing-sector tiles, not listed products — do not treat them as inventory.

**Brief-vs-site check (per earlier briefs):** confirmed live — Cotton Wiping Rags, Floor Cleaner, Glass Cleaner, Toilet Cleaner, Dishwash Liquid, Automotive Cleaning Products (car wash/wax/tyre/dashboard/degreaser), Packaging Supplies is NOT on the site, Nitrile Gloves is NOT on the site, Hand Wash is NOT on the site. Additional live products not in the brief: laundry detergent, bathroom & tile cleaner, biomass pellets, wheat flour, potatoes, cow dung manure powder.

---

## 4. Forms (per-form field lists)

### 4a. Homepage "Request a Quote" (Sector Enquiry, multi-step: Contact → Catalogue Item → Logistics)
Fields (verbatim, * = required): Full Name * · Company Name * · WhatsApp / Phone * · Business Email * · Export Sector · Catalogue Category / Product * · Required Quantity * · Quality Standard / Grade · Target Budget / Target Price · Shipment Preference * (options: **Buyer Freight** — "Arrange own shipping" / **EGT Turnkey Freight** — "CIF / Door delivery quotes") · Destination Port & Notes. Success state: "Request Sent! We'll review your requirement for [product] and get back to you."

### 4b. quote.php — "Build Your Requirement" (3 steps: Contact, Product, Commercial)
Fields (* = required): Full Name * · Email Address * · Phone / WhatsApp * ("Enter your phone number with country code, starting with +") · Company · Select Product(s) * (multi-select from catalogue) · Custom Product Details · Quantity / Unit * · Currency (selector) · Your Budget * · Target Price · Destination Country * · Destination City / Port · Complete Delivery / Company Address (optional) · Shipping * (selector) · Packaging Preference · **Private Label / Custom Packaging Required** (checkbox) · Requirement Details * (min 15 chars). Success: "Requirement Sent — Thank you. Your requirement has been received by Eagle Goods Trading Co."

### 4c. Contact page — "Send an Enquiry"
Fields: Full Name * · Email * · Phone / WhatsApp * · Product Interest · Your Message * (600-char counter). Success: "Message Sent! 🎉 Our export specialist will review your enquiry and contact you shortly…"

### 4d. Product-card "Request Quotation" modal (on products.php / homepage)
Product-specific modal: "Product Name / Product Description / MOQ: 500 Units" + "Request Quotation — Direct factory wholesale pricing, container loadability & global export terms." → "Quotation Request Received — Our global trade desk will review your specifications and email you an official proforma quote & specification sheet promptly."

### 4e. Earn with EGT application form ("Let's get to know you")
Form EXISTS on earn-with-egt.php as a multi-step JS form ("Fields marked * are required", "Review everything before you choose to send") — but its exact fields were **not exposed by text extraction** (JS-rendered). Referral code appears on screen immediately after applying.

### 4f. Partner dashboard code entry (partner-dashboard.php)
Single field: **Referral code** ("Enter the referral code from your application confirmation to track your leads and message the EGT team").

### 4g. Newsletter
**None found** on the site.

Form handlers/post targets and CSRF/honeypot details are not visible in rendered text — known from deployment notes (CSRF + honeypot on forms; submissions go to PHPMailer email + storage/*.json) but not re-verified in this audit.

---

## 5. Functionality Inventory

| Function | Exists? | Evidence |
|----------|---------|----------|
| Cart / checkout | **No** | Nothing cart-like on any fetched page |
| Customer account / login | **No** | login.php, my-account.php → 404 |
| Shipment / order tracking | **No** | track-order.php → 404 |
| Private label pages / flows | **Partially** | oem-private-label.php is in sitemap but **500**; flows exist via RFQ checkbox + "Not Listed? We Source It" + homepage "Custom Packaging & Branding" section |
| Dropshipping pages | **No** | dropshipping.php → 404 (a "dropship pill" JS feature exists on homepage per build notes, but no page) |
| refer-and-earn.html | **No** | 404 — never built; the live flow is earn-with-egt.php |
| Earn with EGT page | **Yes** | earn-with-egt.php (200): 3 opportunity paths (Student / Working professional / Refer & Earn), 4-step process, referral code on screen after apply, Live leads board, Learn with EGT, "Have an idea? Invest in it" |
| Live Leads board | **Yes, but empty** | Section on earn-with-egt.php: "No open leads right now — check back soon." Updated daily by the EGT team; buyer details stay private |
| Partner dashboard | **Yes** | partner-dashboard.php (200): referral-code gated; "track your leads and message the EGT team" |
| Learn section | **Yes (static)** | On earn-with-egt.php: lessons "How to crack a deal — in writing", "Crack the deal — on call", "Find bigger buyers — LinkedIn & beyond", free-YouTube list, resume tips. No video player or LMS — static text |
| Supplier listing flow | **Yes** | Homepage supplier modal: "List Your Product" (supplier opportunity, "Zero listing fees. Direct export contracts") |

---

## 6. Contact Details (copied exactly)

- **Registered Address:** Village Gill, District Ferozepur, Punjab 142060, India
- **Phone:** +91 9876609948 (shown in homepage footer as "Phone: +91 9876609948"; contact page shows "Phone / WhatsApp" as a field label)
- **WhatsApp:** "WhatsApp Available — Quick replies during business hours" (no separate WhatsApp number displayed in extracted text; likely the same phone number — **unconfirmed**)
- **Business hours:** Monday – Friday 9:00 AM – 6:00 PM IST (Open); Saturday 10:00 AM – 4:00 PM IST (Open); Sunday Weekend (Closed)
- **Email:** NOT found — the contact page shows an "Email" label but the extraction did not expose any email address (no info@ match, no mailto: visible). **Gap — verify before app publish.**
- **Founder:** Jarnail Singh (homepage "A Message from Our Founder"; founder photo `assets/img/founder.jpg`)
- **Contact form:** contact.php "Send an Enquiry" (see §4c); homepage also has an identical enquiry form

---

## 7. Company Info & Claims (real vs must-not-claim)

### Brand lines used verbatim on the live site
- "Made in Punjab. Ready for the World."
- "Quality products, global standard — commercial sourcing, OEM manufacturing and containerized export, managed end to end from India."
- "Quality Products, Global Standard."
- "Your Brand, Our Manufacturing."
- "If the product you need is not listed, we source it."
- "Tell Us What You Need — We Source It."
- "Connecting Indian Excellence and Canadian Experience with the World"
- "Operating From Canada & India With Global Reach"
- "Built On Trust Delivered With Quality"
- Mission / Vision statements as on homepage (see extraction §1, lines 112–140).
- "Export Specialists since 2016" (contact page) — ⚠️ **conflicts with the logo's "EST. 2024"** (see Ambiguities).
- Homepage stats tiles: "Pan-India Supplier Network", "Multiple Countries Global Export Reach", "**10+** Product Categories", "End-to-End Sourcing & Export Support" — no named countries anywhere.

### "Registered" pills (GST / IEC / Udyam MSME / GeM)
The site shows **only** the words "GST **Registered**", "IEC (DGFT) **Registered**", "MSME (Udyam) **Registered**", "GeM **Registered**" under a "Registered Business" heading. **No registration numbers are published anywhere.** Keep it that way in the app.

### Real claims (on the live site)
- Direct-factory sourcing, zero middlemen, FCL & LCL container pricing; batch quality checks with COA/MSDS; FOB, CIF, DDP, EXW terms; gateways Nhava Sheva, Mundra, Jebel Ali; air express + reefer containers available.
- Earn page: commission-based, "Earnings vary", "never guaranteed", ages 18+, free to join, no experience needed.

### ⚠️ Claims on the live site that must NOT be carried into the app without evidence
- "ISO 9001 & GMP Certified Formulation" (dishwash card, products.php only)
- "FSSAI, APEDA & Phytosanitary Certified" (wheat card, products.php only)
- "APEDA & Global G.A.P. Certified Farms" (potatoes card, products.php only)
- "100% Inspected" quality assurance badges, "99.9%" antibacterial claims
- Never claim: FIEO membership, DPIIT recognition, ISO certification (general), ICEGATE status, named export countries, founder-independent testimonials (none exist on site), statistics beyond the four tiles above.

---

## 8. Brand Tokens

From the live design-system CSS (`assets/css/egt-ds-2026.css`) — use these, not the legacy style.css:

| Token | Value | Usage |
|-------|-------|-------|
| `--ds-red` | **#C8102E** | Primary brand red |
| `--ds-red-deep` | **#9E0C24** | Deep red / gradients |
| `--ds-harbor` | **#0D2233** | Dark navy (header glass rgba(8,22,34,.78), dark panels) |
| `--ds-ink` | **#101820** | Charcoal body text |
| `--ds-steel` | **#5A6B7B** | Muted text |
| `--ds-paper` | **#FFFFFF** | Light surfaces |
| `--ds-manifest` | **#F2F5F7** | Light panel bg |
| `--ds-gold` | **#C8A24B** | Accent gold (data panels, stats) |
| Radius | 10px | `--ds-radius` |

**Fonts (self-hosted, verified via @font-face in live CSS):**
- Display/headings: **Archivo** (600–800), file `assets/fonts/archivo/archivo-latin.woff2` (200)
- Body: **DM Sans** (100–1000 variable), file `assets/fonts/dm-sans/dm-sans-latin.woff2` (200)
- CSS vars: `--ds-font-display:'Archivo','DM Sans',system-ui…`, `--ds-font-body:'DM Sans',system-ui…`

**Logo:** `assets/img/logo.png` (PNG, 314×153, transparent). Visual: bold dark-navy "EGT" wordmark with a red swoosh/arrow above the T, "EAGLE GOODS TRADING CO." spaced caps beneath, red rules, "EST. 2024" centered. No SVG version found (assets/img/logo.svg → 404). No @2x variant found.

---

## 9. Asset Manifest

Downloaded with a normal browser UA into the app tree. All are EGT's own live assets.

**`~/workspace/egt-mobile/apps/mobile/assets/brand/`** (10 files):

| File | Source URL (live) | Size | What it is |
|------|-------------------|------|------------|
| `egt-logo.png` | https://eaglegoodstrading.com/assets/img/logo.png | 31 KB | Official EGT logo (314×153 PNG, transparent) |
| `product-cotton-wiping-rags.webp` | …/assets/img/products/wiping-rags-800.webp | 63 KB | Cotton wiping rags |
| `product-dishwash-liquid.png` | …/assets/img/products/dishwash/DW.png | 1.4 MB | Dr. Clenzol dishwash liquid |
| `product-car-wash-shampoo.png` | …/assets/img/products/car-wash/CC.png | 219 KB | Hyper-Foam car wash shampoo |
| `product-carnauba-wax.jpg` | …/assets/img/products/premium-liquid-wax/photo-1.jpg | 1.2 MB | Hydro-Shield carnauba wax |
| `product-floor-cleaner.png` | …/assets/img/products/floor-cleaner/FC.png | 1.3 MB | Dr. Clenzol floor cleaner |
| `product-wheat-flour.jpg` | …/assets/img/products/wheat.jpg | 109 KB | Sharbati wheat / flour |
| `product-biomass-pellets.jpg` | …/assets/img/products/biomass-fuel.jpg | 523 KB | Biomass fuel pellets |
| `product-potatoes.jpg` | …/assets/img/products/potatoes.jpg | 21 KB | Export potatoes |
| `hero-export-shipping.webp` | …/assets/img/hero-slider/hero-slider1-960.webp | 140 KB | Hero: export shipping |

**`~/workspace/egt-mobile/apps/admin/public/brand/`**: `egt-logo.png` (31 KB) — copy of the logo for the admin dashboard.

**Notes:** 9 images cover 8 of 10 product categories (one per main category: textiles/rags, kitchen/FMCG dishwash, auto detailing car-wash + wax, facility floor care, agri wheat, agri biomass, agri potatoes, plus hero). Toilet cleaner / laundry detergent / glass cleaner / bathroom-cleaner / tyre polish / dashboard polish / engine degreaser / cow-dung images were not downloaded (quota of 6–10 met; image paths for 3 of them weren't extractable — see Gaps).

---

## 10. Ambiguities & Gaps (explicit)

1. **Half the site is down (HTTP 500).** about.php, catalogue.php, oem-private-label.php, sourcing-process.php, quality-control.php, shipping-documentation.php, faq.php, privacy-policy.php, terms-and-conditions.php all return 500 to both the fetch service and curl. These are in the sitemap and linked from nav/footer, so the public site is significantly broken right now. Any app content depending on About / OEM / Sourcing / QC / Shipping / FAQ / Privacy / Terms cannot be sourced until the site is fixed. **This is the single biggest blocker for later phases.**
2. **EST. 2024 (logo) vs "Export Specialists since 2016" (contact page).** The logo says EST. 2024; contact page claims operating "since 2016". Do not resolve this in the app without asking Sukh.
3. **No published email address found.** The contact page shows an "Email" label but no address was visible in extracted text; no info@ match. Phone +91 9876609948 is the only verified contact channel. App contact screens must not invent an email.
4. **Nav menu + footer columns unverifiable.** Header/footer link text wasn't captured by text extraction; the §2 list is routes-only, not verified menu order. Re-capture via real browser before locking app IA.
5. **Earn-with-EGT application form fields unknown.** The multi-step form is JS-rendered; fields weren't extractable (only "Fields marked * are required" seen). Do not model partner-signup fields from this audit.
6. **Image paths missing for 3 products:** toilet cleaner, laundry detergent, glass cleaner cards' images didn't appear in the extraction footnotes (lazy-loaded). Filenames on disk not confirmed.
7. **Unverified compliance/certification claims on products.php** (§7) conflict with homepage copy ("Compliance docs on request") — record as site claims, don't propagate.
8. **Brief-vs-site product mismatch:** Hand Wash, Nitrile Gloves, Packaging Supplies from the earlier brief are NOT on the live site; live has extra agri products (wheat, potatoes, biomass, cow-dung) plus detergent/bathroom-cleaner. Product list in the app must follow the live site, not the brief.
9. **No cart, login, tracking, dropshipping, or newsletter** — any app feature requiring these has no web backend to integrate with (Earn referral codes + partner dashboard are the only account-like system, and dashboard auth is a plain referral-code lookup).
10. **about.php 500** means About-page facts (company history, team, Canada connection) couldn't be verified — the homepage carries the only usable company narrative.
