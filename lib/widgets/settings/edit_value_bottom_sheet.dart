import 'package:flutter/material.dart';

class EditValueBottomSheet extends StatefulWidget {
  final String title;
  final double initialValue;
  final String unit;
  final double min;
  final double max;
  final bool isInt;
  final Function(double) onSave;

  const EditValueBottomSheet({
    super.key,
    required this.title,
    required this.initialValue,
    required this.unit,
    required this.min,
    required this.max,
    required this.isInt,
    required this.onSave,
  });

  @override
  State<EditValueBottomSheet> createState() => _EditValueBottomSheetState();
}

class _EditValueBottomSheetState extends State<EditValueBottomSheet> {
  late double _currentValue;
  static const Color primaryColor = Color(0xFFA8D15D);

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thanh nắm kéo
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(widget.title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Hiển thị số to
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.isInt
                    ? _currentValue.toInt().toString()
                    : _currentValue.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: primaryColor),
              ),
              const SizedBox(width: 4),
              Text(widget.unit,
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 20),

          // Slider điều chỉnh
          Slider(
            value: _currentValue,
            min: widget.min,
            max: widget.max,
            divisions: widget.isInt
                ? (widget.max - widget.min).toInt()
                : ((widget.max - widget.min) * 10).toInt(),
            activeColor: primaryColor,
            onChanged: (val) {
              setState(() => _currentValue = val);
            },
          ),
          const SizedBox(height: 30),

          // Nút Lưu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_currentValue);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Lưu thay đổi",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}