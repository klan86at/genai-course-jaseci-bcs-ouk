import qrcode;
import from PIL { Image };

def generate_qr_code(data: str) {
    data = input("Provide data to generate QR code: ");
    qr = qrcode.QRCode(version=3, box_size=10, border=4);
    qr.add_data(data);
    qr.make(fit=True);
    img = qr.make_image(fill_color="black", back_color="peru");
    img.save("qr_code.png");
    # To open an image, you might need inline Python or a similar approach
}

with entry {
    
    generate_qr_code(data);
}