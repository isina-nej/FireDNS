import 'package:flutter/material.dart';
import '../path/path.dart';

/// ویجت فیلتر نوع DNS
class DnsTypeFilter extends StatelessWidget {
  final DnsType? selectedType;
  final Function(DnsType?) onTypeChanged;

  const DnsTypeFilter({
    Key? key,
    required this.selectedType,
    required this.onTypeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // دکمه همه
          _buildFilterChip(
            context,
            label: 'همه',
            isSelected: selectedType == null,
            onSelected: () => onTypeChanged(null),
          ),
          const SizedBox(width: 8),
          // دکمه‌های انواع DNS
          ...DnsType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                context,
                label: type.displayName,
                isSelected: selectedType == type,
                onSelected: () => onTypeChanged(type),
                color: Color(type.colorValue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: color?.withOpacity(0.1),
      selectedColor: color ?? Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : color ?? Theme.of(context).primaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
