# jac code to generate qrcode
import qrcode;
import from PIL { Image }

def generate_qr_code(data: str) {
    qr = qrcode.QRCode(version=3, box_size=10, border=4);
    qr.add_data(data);
    qr.make(fit=True);
    img = qr.make_image(fill_color="black", back_color="blue");
    img.save("qr_code.png");
}

with entry {
    data = input("Provide data to generate QR code: ");
    generate_qr_code(data);
}