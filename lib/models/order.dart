class Order {
  final String id;
  final String receiverPhone;
  final String receiverName;
  final String address;
  final double? lat;
  final double? lng;
  int status; // 1: รอไรเดอร์มารับ, 2: ไรเดอร์รับงาน, 3: รับของแล้วกำลังไปส่ง
  String? proofImagePath; // รูปสถานะ [1]

  Order({
    required this.id,
    required this.receiverPhone,
    required this.receiverName,
    required this.address,
    this.lat,
    this.lng,
    this.status = 1,
    this.proofImagePath,
  });
}
