import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final IconData? icon;
  final bool isAmount;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.isAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: isMobile ? 100 : 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: isAmount
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : EdgeInsets.zero,
              decoration: isAmount
                  ? BoxDecoration(
                      color: (color ?? Colors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (color ?? Colors.blue).withOpacity(0.3),
                      ),
                    )
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: isAmount ? FontWeight.bold : FontWeight.w600,
                  color: color ?? Colors.black87,
                  fontSize: isAmount
                      ? (isMobile ? 13 : 15)
                      : (isMobile ? 12 : 14),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
