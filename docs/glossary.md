# Glossary — EGT Mobile App Program

Plain-language definitions of domain terms used across the app, API, and docs.
No company facts are asserted here — anything about EGT specifically comes from
`docs/site-audit.md`, not from these definitions.

## Trade & sourcing

- **RFQ (Request for Quotation):** A buyer's formal request asking a supplier to quote a price for
  specific goods. In this app it is the 12-step form (contact → product → commercial details) and the
  pipeline object staff work through to delivery.
- **MOQ (Minimum Order Quantity):** The smallest quantity a supplier will sell in one order.
  EGT's site shows these as "ORDER VOLUME" figures (e.g. 500 L, 1 FCL).
- **FOB (Free On Board):** Incoterm where the seller delivers goods onto the vessel at the origin port;
  the buyer handles ocean freight and insurance from there.
- **CIF (Cost, Insurance and Freight):** Incoterm where the seller pays for the goods, freight, and
  insurance to the destination port (site offers this as "EGT Turnkey Freight").
- **DDP (Delivered Duty Paid):** Incoterm where the seller bears all costs and risks to deliver goods
  to the buyer's door, duties paid.
- **EXW (Ex Works):** Incoterm where the buyer collects goods at the seller's premises and handles
  everything from there.
- **FCL (Full Container Load):** A shipment filling an entire container (site references 20ft and 40ft).
- **LCL (Less than Container Load):** A shipment sharing container space with other cargo.
- **Reefer container:** A refrigerated container for temperature-sensitive cargo
  (site: potatoes shipped at +8°C in a 40ft reefer).
- **Private label:** Products manufactured by one company but sold under another company's brand.
  The site offers "Custom Packaging & OEM Private label" and the RFQ form has a private-label checkbox.
- **OEM (Original Equipment Manufacturer):** Here, manufacturing goods to a buyer's specification/brand.
- **Proforma invoice / quote:** A preliminary bill/quotation sent before shipment; not a demand for payment.
- **COA (Certificate of Analysis):** Lab document certifying a batch meets specifications.
- **MSDS / SDS (Material/Safety Data Sheet):** Document describing a chemical product's hazards and
  safe handling.
- **Bill of Lading (BL):** The shipping document serving as receipt and contract of carriage.
- **Sourcing:** Finding and vetting manufacturers/suppliers for a buyer's requirement
  ("If the product you need is not listed, we source it").
- **Turnkey freight:** EGT arranging shipping end-to-end (site: "EGT Turnkey Freight — CIF / Door
  delivery quotes") vs. "Buyer Freight" where the buyer arranges their own shipping.

## Program-specific

- **Lead:** A buyer requirement or opportunity visible on the Live Leads board (Earn with EGT).
- **Partner:** A youth partner in the Earn with EGT program who refers buyers and earns commission.
- **Referral code:** The code issued after applying to Earn with EGT; used to log in to the partner
  dashboard and to attribute referred leads. Commission-based, earnings explicitly not guaranteed.
- **Live Leads board:** The public list of open buyer leads partners can pursue (currently empty on site).

## Roles (app RBAC)

- **Guest:** Unauthenticated app user; can browse catalogue and company info, can start an RFQ draft.
- **Buyer:** Authenticated customer submitting and tracking RFQs; sees only their own data.
- **Supplier:** Manufacturer/supplier onboarded by staff; sees only RFQs explicitly shared with them.
- **Staff:** EGT team member; works the RFQ pipeline, manages catalogue content and leads.
- **Admin:** Full system administration including user/role management and audit-log access.

## Security & engineering

- **RBAC (Role-Based Access Control):** Permissions derived from the user's role; enforced on the server,
  never trusted from the client.
- **JWT (JSON Web Token):** Short-lived signed token proving identity for API calls (15-minute lifetime here).
- **Refresh token (rotating):** Long-lived opaque token used to get new JWTs; single-use — each use
  issues a new one and invalidates the old (reuse signals theft).
- **argon2id:** Memory-hard password hashing algorithm (OWASP-recommended).
- **Signed URL:** A time-limited link granting temporary access to a private file; expires automatically.
- **CSRF (Cross-Site Request Forgery):** Attack tricking a logged-in browser into making unwanted requests;
  mitigated with anti-CSRF tokens (the website already uses these on forms).
- **Audit log:** Append-only record of who did what, when — used for accountability and incident review.
- **MASVS (OWASP Mobile Application Security Verification Standard):** The checklist the app's security
  posture is measured against (see Stage B `docs/security.md`).
- **FCM (Firebase Cloud Messaging):** Google's push-notification service used for Android notifications.
- **Idempotency key:** A client-supplied key ensuring a retried request (e.g. RFQ submit) doesn't create
  duplicates.
