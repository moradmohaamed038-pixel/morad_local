import 'package:flutter/material.dart';

class RelayButton extends StatelessWidget {
  final int id;
  final String name;
  final bool isOn;
  final VoidCallback onToggle;

  const RelayButton({
    super.key,
    required this.id,
    required this.name,
    required this.isOn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isOn ? Colors.green.shade50 : Colors.grey.shade100,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isOn ? Colors.green.shade800 : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isOn ? Colors.green : Colors.grey.shade600,
                ),
                child: Text(
                  isOn ? 'ON' : 'OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}