import os
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from datetime import datetime
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import mm
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, HRFlowable
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_RIGHT, TA_LEFT
from dotenv import load_dotenv
from pathlib import Path

# Load .env — try multiple locations
_env_path = Path(__file__).parent / '.env'
_env_path2 = Path(__file__).parent.parent / '.env'
if _env_path.exists():
    load_dotenv(dotenv_path=_env_path)
    print(f"[bill_service] Loaded .env from: {_env_path}")
elif _env_path2.exists():
    load_dotenv(dotenv_path=_env_path2)
    print(f"[bill_service] Loaded .env from: {_env_path2}")
else:
    load_dotenv()
    print(f"[bill_service] .env searched at: {_env_path} and {_env_path2}")

EMAIL_FROM = os.getenv('EMAIL_ADDRESS', '')
EMAIL_PASS = os.getenv('EMAIL_PASSWORD', '')
if not EMAIL_FROM:
    print("[bill_service] WARNING: EMAIL_ADDRESS not found in .env")
else:
    print(f"[bill_service] Email loaded: {EMAIL_FROM[:6]}...")

SHOP_EMAIL = EMAIL_FROM

SHOP_NAME    = "Annachi Kadai"
SHOP_ADDRESS = "Coimbatore, Tamil Nadu"
SHOP_PHONE   = "+91 XXXXX XXXXX"



def generate_bill_pdf(order_id: int, customer_name: str, customer_email: str,
                      delivery_address: str, items: list, total_amount: float,
                      notes: str = '', payment_method: str = 'cod') -> str:
    """Generate PDF bill and return file path."""

    os.makedirs('bills', exist_ok=True)
    filepath = f'bills/bill_order_{order_id}.pdf'

    doc = SimpleDocTemplate(filepath, pagesize=A4,
                             rightMargin=15*mm, leftMargin=15*mm,
                             topMargin=15*mm, bottomMargin=15*mm)

    styles = getSampleStyleSheet()
    yellow = colors.HexColor('#FFD60A')
    navy   = colors.HexColor('#1A1F36')
    grey   = colors.HexColor('#6B7280')
    green  = colors.HexColor('#10B981')
    white  = colors.white
    light  = colors.HexColor('#F9FAFB')

    story = []

    # ── HEADER ──
    header_data = [[
        Paragraph(f'<font size="22" color="#FFD60A"><b>{SHOP_NAME}</b></font>', styles['Normal']),
        Paragraph(f'<font size="10" color="#6B7280">{SHOP_ADDRESS}<br/>{SHOP_PHONE}<br/>{SHOP_EMAIL}</font>',
                  ParagraphStyle('right', parent=styles['Normal'], alignment=TA_RIGHT))
    ]]
    header_table = Table(header_data, colWidths=[90*mm, 90*mm])
    header_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), navy),
        ('ROWBACKGROUNDS', (0,0), (-1,-1), [navy]),
        ('TOPPADDING', (0,0), (-1,-1), 14),
        ('BOTTOMPADDING', (0,0), (-1,-1), 14),
        ('LEFTPADDING', (0,0), (0,-1), 12),
        ('RIGHTPADDING', (-1,0), (-1,-1), 12),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(header_table)
    story.append(Spacer(1, 6*mm))

    # ── TAX INVOICE TITLE ──
    story.append(Paragraph(
        '<font size="14" color="#1A1F36"><b>TAX INVOICE</b></font>',
        ParagraphStyle('center', parent=styles['Normal'], alignment=TA_CENTER)
    ))
    story.append(Spacer(1, 4*mm))
    story.append(HRFlowable(width="100%", thickness=2, color=yellow))
    story.append(Spacer(1, 4*mm))

    # ── ORDER & CUSTOMER INFO ──
    now = datetime.now().strftime('%d %b %Y, %I:%M %p')
    info_data = [
        [Paragraph('<b>Order Details</b>', styles['Normal']),
         Paragraph('<b>Bill To</b>', styles['Normal'])],
        [Paragraph(f'Order #: <b>{order_id}</b>', styles['Normal']),
         Paragraph(f'Name: <b>{customer_name}</b>', styles['Normal'])],
        [Paragraph(f'Date: {now}', styles['Normal']),
         Paragraph(f'Email: {customer_email}', styles['Normal'])],
        [Paragraph(f'Status: <font color="#10B981"><b>Confirmed</b></font>', styles['Normal']),
         Paragraph(f'Address: {delivery_address}', styles['Normal'])],
        [Paragraph('Payment: <b>' + ('Cash on Delivery' if payment_method == 'cod' else payment_method.upper()) + '</b>', styles['Normal']),
         Paragraph('', styles['Normal'])],
    ]
    info_table = Table(info_data, colWidths=[90*mm, 90*mm])
    info_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), light),
        ('FONTSIZE', (0,0), (-1,-1), 9),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E5E7EB')),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ]))
    story.append(info_table)
    story.append(Spacer(1, 6*mm))

    # ── ITEMS TABLE ──
    item_header = [
        Paragraph('<font color="white"><b>#</b></font>', styles['Normal']),
        Paragraph('<font color="white"><b>Product</b></font>', styles['Normal']),
        Paragraph('<font color="white"><b>Unit</b></font>', styles['Normal']),
        Paragraph('<font color="white"><b>Qty</b></font>', styles['Normal']),
        Paragraph('<font color="white"><b>Price</b></font>', styles['Normal']),
        Paragraph('<font color="white"><b>Total</b></font>', styles['Normal']),
    ]
    item_rows = [item_header]
    subtotal = 0.0
    for idx, item in enumerate(items, 1):
        qty   = item.get('quantity', 1)
        price = float(item.get('price', 0))
        total = qty * price
        subtotal += total
        row_bg = light if idx % 2 == 0 else white
        item_rows.append([
            str(idx),
            item.get('name', ''),
            item.get('unit', 'pcs'),
            str(qty),
            f'₹{price:.2f}',
            f'₹{total:.2f}',
        ])

    items_table = Table(item_rows, colWidths=[10*mm, 65*mm, 25*mm, 15*mm, 25*mm, 30*mm])
    item_style = TableStyle([
        ('BACKGROUND', (0,0), (-1,0), navy),
        ('FONTSIZE', (0,0), (-1,-1), 9),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [white, light]),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor('#E5E7EB')),
        ('ALIGN', (3,0), (-1,-1), 'CENTER'),
        ('ALIGN', (4,1), (-1,-1), 'RIGHT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ])
    items_table.setStyle(item_style)
    story.append(items_table)
    story.append(Spacer(1, 4*mm))

    # ── TOTALS ──
    totals_data = [
        ['', '', '', '', 'Subtotal:', f'₹{subtotal:.2f}'],
        ['', '', '', '', 'Delivery:', 'FREE'],
        ['', '', '', '',
         Paragraph('<b>TOTAL:</b>', styles['Normal']),
         Paragraph(f'<b>₹{total_amount:.2f}</b>', styles['Normal'])],
    ]
    totals_table = Table(totals_data, colWidths=[10*mm, 65*mm, 25*mm, 15*mm, 25*mm, 30*mm])
    totals_table.setStyle(TableStyle([
        ('FONTSIZE', (0,0), (-1,-1), 9),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('ALIGN', (4,0), (-1,-1), 'RIGHT'),
        ('BACKGROUND', (4,2), (-1,2), colors.HexColor('#FFFBEB')),
        ('LINEABOVE', (4,2), (-1,2), 1.5, yellow),
        ('TEXTCOLOR', (4,1), (4,1), green),
    ]))
    story.append(totals_table)

    if notes:
        story.append(Spacer(1, 4*mm))
        story.append(HRFlowable(width="100%", thickness=0.5, color=colors.HexColor('#E5E7EB')))
        story.append(Spacer(1, 2*mm))
        story.append(Paragraph(f'<font size="9" color="#6B7280"><b>Delivery Notes:</b> {notes}</font>',
                                styles['Normal']))

    # ── FOOTER ──
    story.append(Spacer(1, 8*mm))
    story.append(HRFlowable(width="100%", thickness=1, color=yellow))
    story.append(Spacer(1, 3*mm))
    story.append(Paragraph(
        f'<font size="9" color="#6B7280">Thank you for shopping at {SHOP_NAME}! '
        f'For support contact {SHOP_EMAIL}</font>',
        ParagraphStyle('footer', parent=styles['Normal'], alignment=TA_CENTER)
    ))

    doc.build(story)
    return filepath


def send_bill_email(customer_email: str, customer_name: str,
                    order_id: int, pdf_path: str, total: float) -> bool:
    """Email the PDF bill to the customer."""
    try:
        msg = MIMEMultipart()
        msg['From']    = EMAIL_FROM
        msg['To']      = customer_email
        msg['Subject'] = f'Your Annachi Kadai Bill - Order #{order_id}'

        body = f"""
Hi {customer_name}!

Thank you for your order at Annachi Kadai 🛒

Your order #{order_id} has been confirmed!
Total Amount: ₹{total:.2f}
Delivery: FREE

Please find your PDF bill attached to this email.

Expect your delivery in approximately 10 minutes! ⚡

Thank you,
Annachi Kadai Team
        """
        msg.attach(MIMEText(body, 'plain'))

        with open(pdf_path, 'rb') as f:
            part = MIMEBase('application', 'octet-stream')
            part.set_payload(f.read())
        encoders.encode_base64(part)
        part.add_header('Content-Disposition',
                        f'attachment; filename=bill_order_{order_id}.pdf')
        msg.attach(part)

        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(EMAIL_FROM, EMAIL_PASS)
        server.sendmail(EMAIL_FROM, customer_email, msg.as_string())
        server.quit()
        return True
    except Exception as e:
        print(f"Email error: {e}")
        return False