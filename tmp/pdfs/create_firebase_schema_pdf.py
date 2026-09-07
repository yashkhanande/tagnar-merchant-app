from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "output/pdf/tagnar_merchant_firebase_schema.pdf"
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

NAVY = colors.HexColor("#12233F")
BLUE = colors.HexColor("#276EF1")
PALE = colors.HexColor("#EEF4FF")
INK = colors.HexColor("#1B2430")
MUTED = colors.HexColor("#586579")
LINE = colors.HexColor("#D9E1EC")
GREEN = colors.HexColor("#167C5A")

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="CoverTitle", parent=styles["Title"], fontName="Helvetica-Bold", fontSize=28, leading=33, textColor=colors.white, alignment=TA_LEFT, spaceAfter=12))
styles.add(ParagraphStyle(name="CoverSub", parent=styles["Normal"], fontName="Helvetica", fontSize=12, leading=18, textColor=colors.HexColor("#D9E8FF")))
styles.add(ParagraphStyle(name="H1x", parent=styles["Heading1"], fontName="Helvetica-Bold", fontSize=20, leading=24, textColor=NAVY, spaceBefore=4, spaceAfter=10))
styles.add(ParagraphStyle(name="H2x", parent=styles["Heading2"], fontName="Helvetica-Bold", fontSize=13, leading=17, textColor=NAVY, spaceBefore=10, spaceAfter=7))
styles.add(ParagraphStyle(name="Bodyx", parent=styles["BodyText"], fontName="Helvetica", fontSize=9.2, leading=13.2, textColor=INK, spaceAfter=6))
styles.add(ParagraphStyle(name="Smallx", parent=styles["BodyText"], fontName="Helvetica", fontSize=7.8, leading=10.5, textColor=MUTED))
styles.add(ParagraphStyle(name="Codex", parent=styles["Code"], fontName="Courier", fontSize=7.5, leading=10.5, textColor=INK, leftIndent=8, rightIndent=8, spaceBefore=6, spaceAfter=8))
styles.add(ParagraphStyle(name="Callout", parent=styles["BodyText"], fontName="Helvetica-Bold", fontSize=9, leading=13, textColor=GREEN, backColor=colors.HexColor("#EAF8F2"), borderPadding=8, spaceBefore=5, spaceAfter=8))


def p(text, style="Bodyx"):
    return Paragraph(text, styles[style])


def code(text):
    return Paragraph(text.replace("\n", "<br/>"), styles["Codex"])


def schema_table(rows):
    data = [[p("Field", "Smallx"), p("Type", "Smallx"), p("Req.", "Smallx"), p("Rules / meaning", "Smallx")]]
    for field, typ, req, meaning in rows:
        data.append([p(f"<b>{field}</b>", "Smallx"), p(typ, "Smallx"), p(req, "Smallx"), p(meaning, "Smallx")])
    table = Table(data, colWidths=[38*mm, 25*mm, 14*mm, 103*mm], repeatRows=1, hAlign="LEFT")
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("GRID", (0, 0), (-1, -1), .4, LINE),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAFD")]),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    return table


def collection(title, path, rows, example, note=None):
    items = [p(title, "H1x"), p(f"Path: <b>{path}</b>"), schema_table(rows), Spacer(1, 4*mm), p("Example", "H2x"), code(example)]
    if note:
        items.append(p(note, "Callout"))
    # The offers table is the tallest section and flows more reliably without
    # an outer KeepTogether; all other sections are grouped as one unit.
    return items


def header_footer(canvas, doc):
    canvas.saveState()
    width, height = A4
    if doc.page > 1:
        canvas.setStrokeColor(LINE)
        canvas.line(16*mm, height-13*mm, width-16*mm, height-13*mm)
        canvas.setFont("Helvetica-Bold", 7.5)
        canvas.setFillColor(NAVY)
        canvas.drawString(16*mm, height-10*mm, "TAGNAR MERCHANT - FIREBASE DATA CONTRACT")
        canvas.setFont("Helvetica", 7.5)
        canvas.setFillColor(MUTED)
        canvas.drawRightString(width-16*mm, 9*mm, f"Page {doc.page}")
    canvas.restoreState()


doc = SimpleDocTemplate(str(OUTPUT), pagesize=A4, rightMargin=15*mm, leftMargin=15*mm, topMargin=18*mm, bottomMargin=16*mm, title="Tagnar Merchant Firebase Data Contract", author="Canonical Firestore collection and attribute specification")
story = []

cover = Table([[p("TAGNAR", "CoverSub")], [p("Merchant Firebase<br/>Data Contract", "CoverTitle")], [p("Canonical collection names, field types, relationships, permissions, and examples for interoperable Tagnar applications.", "CoverSub")]], colWidths=[180*mm], rowHeights=[15*mm, 54*mm, 38*mm])
cover.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), NAVY), ("VALIGN", (0, 0), (-1, -1), "MIDDLE"), ("LEFTPADDING", (0, 0), (-1, -1), 16*mm), ("RIGHTPADDING", (0, 0), (-1, -1), 16*mm)]))
story += [Spacer(1, 20*mm), cover, Spacer(1, 14*mm), p("Implementation target", "H2x"), schema_table([
    ("Firebase project", "string", "Yes", "arcloudanchor-12fd3"),
    ("Firestore database", "string", "Yes", "tagnar-merchant (named database, not the default database)"),
    ("Android package", "string", "Yes", "com.example.tagnar_merchant"),
    ("Authentication", "providers", "Yes", "Google account linked with Phone on the same Firebase UID"),
    ("Date storage", "timestamp", "Yes", "Use Firestore Timestamp / serverTimestamp for persisted dates"),
]), Spacer(1, 7*mm), p("Contract rule", "H2x"), p("All names and enum values are case-sensitive. Missing collections are valid and produce empty states. Missing required fields, wrong types, permission failures, and network failures produce an error; the app never substitutes demo records.", "Callout"), PageBreak()]

story += [p("System map", "H1x"), code("Firebase Auth merchant UID\n  -> merchants_new/{merchantUid}\n      -> merchant_shops/{shopId}\n          <-> merchant_anchors/{anchorId}\n\nmerchantId + shopId\n  -> merchant_requests\n  -> merchant_offers\n  -> merchant_payments\n  -> merchant_interactions\n  -> merchant_conversations/{conversationId}\n      -> messages/{messageId}"), p("Universal identifiers", "H2x"), schema_table([
    ("merchantId", "string", "Yes", "Firebase Authentication UID and merchants_new document ID"),
    ("shopId", "string", "Yes", "merchant_shops document ID"),
    ("anchorId", "string", "Shop only", "merchant_anchors document ID"),
]), p("Operational query contract", "H2x"), p("Every operational document is queried with merchantId == current Firebase UID and shopId == selected approved shop ID. Both fields are mandatory even when another app can infer them."), p("Creation authority", "H2x"), p("The merchant client creates/maintains only its own profile, responds once to eligible offers, marks conversations read, and sends merchant messages. Trusted backend/Admin SDK jobs provision all other operational data. Payments remain read-only."), PageBreak()]

story += collection("1. merchants_new", "merchants_new/{merchantUid}", [
    ("uid", "string", "Yes", "Must equal document ID and Firebase UID"),
    ("name", "string", "Yes", "1-200 characters"),
    ("email", "string", "Yes", "Must equal authenticated token email"),
    ("phoneNumber", "string", "Yes", "Verified token phone in E.164 form, for example +919518940410"),
    ("createdAt", "timestamp", "Yes", "Server timestamp on create"),
    ("updatedAt", "timestamp", "Yes", "Server timestamp on create/update"),
    ("suspended", "boolean", "No", "Admin-controlled; missing means false"),
], '{\n  "uid": "FIREBASE_UID",\n  "name": "Aarav Shah",\n  "email": "aarav@example.com",\n  "phoneNumber": "+919518940410",\n  "createdAt": SERVER_TIMESTAMP,\n  "updatedAt": SERVER_TIMESTAMP,\n  "suspended": false\n}', "Document ID must equal uid. The merchant cannot grant itself roles or change suspended.")
story += [Spacer(1, 5*mm)] + collection("2. master_access", "master_access/{masterUid}", [("active", "boolean", "Yes", "Must be true for Master permissions")], '{ "active": true }', "Only an administrator or Admin SDK grants or revokes Master access.") + [PageBreak()]

story += collection("3. merchant_shops", "merchant_shops/{shopId}", [
    ("merchantId", "string", "Yes", "Merchant Firebase UID"),
    ("name", "string", "Yes", "2-100 characters"),
    ("address", "string", "Yes", "5-300 characters"),
    ("status", "string", "Yes", "approved"),
    ("anchorId", "string", "Yes", "Matching merchant_anchors document ID"),
    ("approvedBy", "string", "Yes", "Active Master Firebase UID"),
    ("createdAt", "timestamp", "Yes", "Server timestamp"),
    ("updatedAt", "timestamp", "Yes", "Server timestamp"),
], '{\n  "merchantId": "FIREBASE_UID",\n  "name": "Corner Market",\n  "address": "Baner Road, Pune, Maharashtra",\n  "status": "approved",\n  "anchorId": "ANCHOR-PN-0142",\n  "approvedBy": "MASTER_UID",\n  "createdAt": SERVER_TIMESTAMP,\n  "updatedAt": SERVER_TIMESTAMP\n}')
story += [Spacer(1, 4*mm)] + collection("4. merchant_anchors", "merchant_anchors/{anchorId}", [
    ("merchantId", "string", "Yes", "Same merchant as linked shop"),
    ("shopId", "string", "Yes", "Matching merchant_shops document ID"),
    ("approvedBy", "string", "Yes", "Same active Master as linked shop"),
    ("active", "boolean", "Yes", "Must be true"),
    ("createdAt", "timestamp", "Yes", "Server timestamp"),
], '{\n  "merchantId": "FIREBASE_UID",\n  "shopId": "corner-market-pune",\n  "approvedBy": "MASTER_UID",\n  "active": true,\n  "createdAt": SERVER_TIMESTAMP\n}', "Create the shop and anchor together in one atomic batch. All cross-references must agree.") + [PageBreak()]

story += collection("5. merchant_requests", "merchant_requests/{requestId}", [
    ("merchantId", "string", "Yes", "Merchant Firebase UID"),
    ("shopId", "string", "Yes", "Approved shop ID"),
    ("brand", "string", "Yes", "Brand display name"),
    ("title", "string", "Yes", "Request title"),
    ("kind", "string", "Yes", "brand | product"),
    ("status", "string", "Yes", "pending | approved | declined"),
    ("date", "timestamp", "Yes", "Request date"),
    ("category", "string", "Yes", "Display category"),
    ("description", "string", "Yes", "Request details"),
], '{\n  "merchantId": "FIREBASE_UID",\n  "shopId": "corner-market-pune",\n  "brand": "Daily Brew",\n  "title": "Neighbourhood coffee placement",\n  "kind": "brand",\n  "status": "pending",\n  "date": FIRESTORE_TIMESTAMP,\n  "category": "Food & beverages",\n  "description": "A 14-day discovery placement proposal."\n}', "The Firestore document ID is displayed as the request ID.") + [PageBreak()]

story += [
    Spacer(1, 65*mm),
    p("Offers and financial records", "H1x"),
    p("Transactional offer responses and authoritative, read-only payment data."),
    PageBreak(),
]

story += collection("6. merchant_offers", "merchant_offers/{offerId}", [
    ("merchantId", "string", "Yes", "Merchant Firebase UID"),
    ("shopId", "string", "Yes", "Approved shop ID"),
    ("brand", "string", "Yes", "Brand display name"),
    ("title", "string", "Yes", "Offer title"),
    ("description", "string", "Yes", "Offer terms/details"),
    ("rewardRupees", "integer", "Yes", "Whole INR rupees, not paise"),
    ("expiresAt", "timestamp", "Yes", "Response deadline"),
    ("decision", "string", "No", "Absent initially; accepted | declined after response"),
    ("decidedAt", "timestamp", "No", "Server timestamp added with response"),
    ("decidedBy", "string", "No", "Merchant Firebase UID added with response"),
], '{\n  "merchantId": "FIREBASE_UID",\n  "shopId": "corner-market-pune",\n  "brand": "Daily Brew",\n  "title": "Coffee campaign",\n  "description": "Seven-day placement.",\n  "rewardRupees": 2400,\n  "expiresAt": FUTURE_TIMESTAMP\n}', "Offer IDs must be globally unique. A merchant can respond once, before expiresAt, through a Firestore transaction.") + [PageBreak()]

story += collection("7. merchant_payments", "merchant_payments/{paymentId}", [
    ("merchantId", "string", "Yes", "Merchant Firebase UID"),
    ("shopId", "string", "Yes", "Approved shop ID"),
    ("from", "string", "Yes", "Payer or brand display name"),
    ("description", "string", "Yes", "Payment description"),
    ("amountPaise", "integer", "Yes", "INR amount in paise; 850000 displays as INR 8,500"),
    ("date", "timestamp", "Yes", "Payment timestamp"),
    ("status", "string", "Yes", "received | pending | failed | refunded"),
    ("method", "string", "No", "Defaults in UI to Not provided"),
], '{\n  "merchantId": "FIREBASE_UID",\n  "shopId": "corner-market-pune",\n  "from": "Leaf Home",\n  "description": "September placement payment",\n  "amountPaise": 850000,\n  "date": FIRESTORE_TIMESTAMP,\n  "status": "received",\n  "method": "Bank transfer"\n}', "Payment records are authoritative and read-only to the merchant. Only a trusted payment backend/Admin SDK writes them.") + [PageBreak()]

story += collection("8. merchant_interactions", "merchant_interactions/{interactionId}", [
    ("merchantId", "string", "Yes", "Merchant Firebase UID"),
    ("shopId", "string", "Yes", "Approved shop ID"),
    ("date", "timestamp", "Yes", "Reporting date"),
    ("views", "integer", "Yes", "Non-negative view count"),
    ("productTaps", "integer", "Yes", "Non-negative product tap count"),
    ("offerOpens", "integer", "Yes", "Non-negative offer open count"),
], '{\n  "merchantId": "FIREBASE_UID",\n  "shopId": "corner-market-pune",\n  "date": FIRESTORE_TIMESTAMP,\n  "views": 128,\n  "productTaps": 37,\n  "offerOpens": 12\n}', "Generate aggregated interaction documents through a trusted analytics backend.") + [PageBreak()]

story += collection("9. merchant_conversations", "merchant_conversations/{conversationId}", [
    ("merchantId", "string", "Yes", "Merchant Firebase UID"),
    ("shopId", "string", "Yes", "Approved shop ID"),
    ("name", "string", "Yes", "Other participant/display name"),
    ("role", "string", "Yes", "brand | master | user"),
    ("unread", "integer", "Yes", "Unread count; use 0 when none"),
    ("readAt", "timestamp", "No", "Server timestamp after merchant marks read"),
], '{\n  "merchantId": "FIREBASE_UID",\n  "shopId": "corner-market-pune",\n  "name": "Daily Brew",\n  "role": "brand",\n  "unread": 2\n}', "Conversation IDs must be globally unique because the app opens a conversation directly by document ID.")
story += [Spacer(1, 5*mm)] + collection("10. Conversation messages", "merchant_conversations/{conversationId}/messages/{messageId}", [
    ("text", "string", "Yes", "1-1,000 characters"),
    ("sentAt", "timestamp", "Yes", "Server timestamp"),
    ("senderId", "string", "Yes", "Firebase UID of sender"),
    ("fromMerchant", "boolean", "Yes", "true for merchant; false for incoming"),
], '{\n  "text": "Please share the placement details.",\n  "sentAt": SERVER_TIMESTAMP,\n  "senderId": "FIREBASE_UID",\n  "fromMerchant": true\n}', "Messages are ordered by sentAt ascending. The app loads at most 500 messages per conversation.") + [PageBreak()]

story += [p("Permissions and delivery checklist", "H1x"), schema_table([
    ("Profile", "client", "Own only", "Merchant may create/update validated identity fields"),
    ("Shop + anchor", "Master", "Atomic", "Active Master creates both documents in one batch"),
    ("Requests", "backend", "Read-only", "Merchant reads only own approved shop"),
    ("Offers", "mixed", "Transactional", "Backend creates; merchant sets one decision before expiry"),
    ("Payments", "backend", "Read-only", "Never accept client-declared payment success"),
    ("Analytics", "backend", "Read-only", "Trusted aggregation writes counts"),
    ("Conversations", "mixed", "Scoped", "Backend provisions; merchant may mark read"),
    ("Messages", "mixed", "Append-only", "Merchant may add valid merchant-authored messages"),
]), Spacer(1, 5*mm), p("Firebase readiness", "H2x"), code("[ ] Project: arcloudanchor-12fd3\n[ ] Named Firestore database: tagnar-merchant\n[ ] Google and Phone Authentication enabled\n[ ] Required SMS regions enabled\n[ ] Android SHA-1 and SHA-256 registered\n[ ] firestore.merchant.rules deployed to tagnar-merchant\n[ ] Backend uses exact case-sensitive collection and field names\n[ ] Backend writes Firestore Timestamp values\n[ ] Every operational document includes merchantId + shopId\n[ ] Empty, permission, network, and malformed-data cases tested"), p("Enum reference", "H2x"), schema_table([
    ("Request kind", "string", "-", "brand | product"),
    ("Request status", "string", "-", "pending | approved | declined"),
    ("Offer decision", "string", "-", "accepted | declined"),
    ("Payment status", "string", "-", "received | pending | failed | refunded"),
    ("Chat role", "string", "-", "brand | master | user"),
]), p("Deployment command", "H2x"), code("firebase deploy --only firestore:rules --config firebase.merchant.json")]

doc.build(story, onFirstPage=header_footer, onLaterPages=header_footer)
print(OUTPUT)
