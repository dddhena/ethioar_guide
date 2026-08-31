import 'package:flutter/material.dart';

class QrTicketModal {
  static void show({
    required BuildContext context,
    required String ticketId,
    required String title,
    required String providerName,
    required String touristName,
    required String dateLabel,
    required String guestsLabel,
    required bool isUsed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'BOOKING ENTRY PASS',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.5,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      size: const Size(180, 180),
                      painter: QrMockPainter(),
                    ),
                  ),
                  if (isUsed)
                    Transform.rotate(
                      angle: -0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.red.shade800, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'USED / EXPIRED',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Ref: $ticketId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Courier',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildModalDetailRow('Service', title),
                    _buildModalDetailRow('Provider', providerName),
                    _buildModalDetailRow('Tourist', touristName),
                    _buildModalDetailRow('Guests Count', guestsLabel),
                    _buildModalDetailRow('Check-in Date', dateLabel),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.teal.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isUsed 
                        ? 'This pass has already been scanned and verified. It is now deactivated.'
                        : 'Present this QR Code to the provider upon arrival. The provider will scan it to verify and complete your check-in. It will expire immediately after scanning.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isUsed ? Colors.red.shade800 : Colors.grey.shade600,
                        fontWeight: isUsed ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Dismiss Ticket'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildModalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class QrMockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final w = size.width;
    final h = size.height;
    
    // Draw Finder Patterns (Corners)
    void drawFinder(double x, double y) {
      final sizeFinder = w * 0.22;
      canvas.drawRect(Rect.fromLTWH(x, y, sizeFinder, sizeFinder), paint);
      canvas.drawRect(Rect.fromLTWH(x + sizeFinder/7, y + sizeFinder/7, sizeFinder * 5/7, sizeFinder * 5/7), Paint()..color = Colors.white);
      canvas.drawRect(Rect.fromLTWH(x + sizeFinder*2/7, y + sizeFinder*2/7, sizeFinder * 3/7, sizeFinder * 3/7), paint);
    }
    
    drawFinder(0, 0); // Top Left
    drawFinder(w * 0.78, 0); // Top Right
    drawFinder(0, h * 0.78); // Bottom Left
    
    final randomPaint = Paint()..color = Colors.black;
    final pixelSize = w / 25; // 25x25 grid
    
    final pattern = [
      [0, 1, 0, 1, 1, 0, 0, 1, 0, 1],
      [1, 0, 1, 0, 0, 1, 1, 0, 1, 0],
      [0, 0, 1, 1, 0, 0, 1, 1, 0, 0],
      [1, 1, 0, 0, 1, 1, 0, 0, 1, 1],
      [0, 1, 0, 1, 1, 0, 0, 1, 0, 1],
      [1, 0, 1, 0, 0, 1, 1, 0, 1, 0],
      [0, 1, 1, 0, 1, 0, 0, 1, 1, 0],
      [1, 0, 0, 1, 0, 1, 1, 0, 0, 1],
      [0, 0, 1, 1, 0, 0, 1, 1, 0, 0],
      [1, 1, 0, 0, 1, 1, 0, 0, 1, 1],
    ];
    
    for (var r = 0; r < pattern.length; r++) {
      for (var c = 0; c < pattern[r].length; c++) {
        if (pattern[r][c] == 1) {
          final px = w * 0.25 + c * pixelSize;
          final py = h * 0.25 + r * pixelSize;
          if (px < w * 0.75 && py < h * 0.75) {
            canvas.drawRect(Rect.fromLTWH(px, py, pixelSize * 0.9, pixelSize * 0.9), randomPaint);
          }
        }
      }
    }
    
    canvas.drawRect(Rect.fromLTWH(w * 0.88, h * 0.35, pixelSize * 2, pixelSize), randomPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.85, h * 0.5, pixelSize, pixelSize * 3), randomPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.35, h * 0.88, pixelSize * 3, pixelSize), randomPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.5, h * 0.85, pixelSize, pixelSize * 2), randomPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
