import 'package:flutter/material.dart';

/// Simple value object for color-coded entities (Tag, ExerciseType, etc).
class ColorCodedItem {
  final String id;
  final String name;
  final int colorValue;

  const ColorCodedItem({
    required this.id,
    required this.name,
    required this.colorValue,
  });
}

typedef CreateItemCallback = Future<ColorCodedItem> Function(
  String name,
  int colorValue,
);

typedef UpdateItemCallback = Future<ColorCodedItem> Function(
  ColorCodedItem item,
  String name,
  int colorValue,
);

typedef DeleteItemCallback = Future<void> Function(ColorCodedItem item);

/// A reusable selector that behaves like a form field and returns the chosen
/// color-coded item to the parent form.
class ColorCodedSelectorFormField extends FormField<ColorCodedItem?> {
  ColorCodedSelectorFormField({
    super.key,
    required List<ColorCodedItem> items,
    required CreateItemCallback onCreateNew,
    UpdateItemCallback? onEditItem,
    DeleteItemCallback? onDeleteItem,
    super.initialValue,
    String? label,
    ValueChanged<ColorCodedItem?>? onChanged,
    super.validator,
    super.autovalidateMode = AutovalidateMode.disabled,
  }) : super(
          builder: (state) {
            final selected = state.value;

            Future<void> openSelector(BuildContext context) async {
              final result = await showModalBottomSheet<ColorCodedItem>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _ColorCodedSelectorSheet(
                  items: items,
                  onCreateNew: onCreateNew,
                  onEditItem: onEditItem,
                  onDeleteItem: onDeleteItem,
                  selectedId: selected?.id,
                ),
              );
              if (result != null) {
                state.didChange(result);
                onChanged?.call(result);
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: label,
                    errorText: state.errorText,
                    border: const OutlineInputBorder(),
                  ),
                  child: InkWell(
                    onTap: () => openSelector(state.context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (selected != null)
                          Expanded(
                            child: Row(
                              children: [
                                _ColorDot(colorValue: selected.colorValue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selected.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const Text('Select...'),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(state.context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}

class _ColorCodedSelectorSheet extends StatefulWidget {
  const _ColorCodedSelectorSheet({
    required this.items,
    required this.onCreateNew,
    this.onEditItem,
    this.onDeleteItem,
    this.selectedId,
  });

  final List<ColorCodedItem> items;
  final String? selectedId;
  final CreateItemCallback onCreateNew;
  final UpdateItemCallback? onEditItem;
  final DeleteItemCallback? onDeleteItem;

  @override
  State<_ColorCodedSelectorSheet> createState() =>
      _ColorCodedSelectorSheetState();
}

class _ColorCodedSelectorSheetState extends State<_ColorCodedSelectorSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _saving = false;

  // Color picker state (HSV: Hue, Saturation, Value/Brightness)
  double _hue = 0.0; // 0-360
  double _saturation = 1.0; // 0-1
  double _brightness = 1.0; // 0-1

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectAndClose(ColorCodedItem item) {
    Navigator.of(context).pop(item);
  }

  Color _getSelectedColor() {
    return HSVColor.fromAHSV(1.0, _hue, _saturation, _brightness).toColor();
  }

  int _colorToIntValue(Color color) {
    final a = (color.a * 255.0).round().clamp(0, 255);
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  Future<void> _saveNew() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final selectedColor = _getSelectedColor();
      final colorValue = _colorToIntValue(selectedColor);
      final item = await widget.onCreateNew(name, colorValue);
      if (mounted) {
        Navigator.of(context).pop(item);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _editItem(ColorCodedItem item) async {
    if (widget.onEditItem == null) return;
    final result = await showModalBottomSheet<ColorCodedItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditColorCodedItemSheet(
        item: item,
        onSave: (name, color) => widget.onEditItem!(item, name, color),
      ),
    );
    if (result != null) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _deleteItem(ColorCodedItem item) async {
    if (widget.onDeleteItem == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.onDeleteItem!(item);
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: widget.items.map((item) {
                  final selected = item.id == widget.selectedId;
                  return Card(
                    child: ListTile(
                      leading: _ColorDot(colorValue: item.colorValue),
                      title: Text(item.name),
                      selected: selected,
                      onTap: () => _selectAndClose(item),
                      trailing: (widget.onEditItem != null ||
                              widget.onDeleteItem != null)
                          ? PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editItem(item);
                                } else if (value == 'delete') {
                                  _deleteItem(item);
                                }
                              },
                              itemBuilder: (context) => [
                                if (widget.onEditItem != null)
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                if (widget.onDeleteItem != null)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                              ],
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Divider(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Add new',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              Text(
                'Choose Color',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              _FullColorPicker(
                hue: _hue,
                saturation: _saturation,
                brightness: _brightness,
                onColorChanged: (hue, saturation, brightness) {
                  setState(() {
                    _hue = hue;
                    _saturation = saturation;
                    _brightness = brightness;
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save & Select'),
                  onPressed: _saving ? null : _saveNew,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullColorPicker extends StatefulWidget {
  const _FullColorPicker({
    required this.hue,
    required this.saturation,
    required this.brightness,
    required this.onColorChanged,
  });

  final double hue;
  final double saturation;
  final double brightness;
  final void Function(double, double, double) onColorChanged;

  @override
  State<_FullColorPicker> createState() => _FullColorPickerState();
}

class _FullColorPickerState extends State<_FullColorPicker> {
  late double _hue;
  late double _saturation;
  late double _brightness;
  final GlobalKey _spectrumKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _hue = widget.hue;
    _saturation = widget.saturation;
    _brightness = widget.brightness;
  }

  @override
  void didUpdateWidget(_FullColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hue != widget.hue ||
        oldWidget.saturation != widget.saturation ||
        oldWidget.brightness != widget.brightness) {
      _hue = widget.hue;
      _saturation = widget.saturation;
      _brightness = widget.brightness;
    }
  }

  void _updateColor(double h, double s, double v) {
    setState(() {
      _hue = h;
      _saturation = s;
      _brightness = v;
    });
    widget.onColorChanged(h, s, v);
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        HSVColor.fromAHSV(1.0, _hue, _saturation, _brightness).toColor();
    final spectrumSize = MediaQuery.of(context).size.width - 64;

    return Column(
      children: [
        // Color Spectrum (Saturation vs Brightness)
        Container(
          key: _spectrumKey,
          width: spectrumSize,
          height: spectrumSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Base hue color
                Container(
                  color: HSVColor.fromAHSV(1.0, _hue, 1.0, 1.0).toColor(),
                ),
                // Saturation gradient (left to right: full color to white)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
                // Brightness gradient (top to bottom: transparent to black)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
                // Selection indicator
                Positioned(
                  left: _saturation * spectrumSize - 8,
                  top: (1.0 - _brightness) * spectrumSize - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                // Gesture detector for dragging
                GestureDetector(
                  onPanUpdate: (details) {
                    final box = _spectrumKey.currentContext?.findRenderObject()
                        as RenderBox?;
                    if (box == null) return;
                    final localPosition =
                        box.globalToLocal(details.globalPosition);
                    final x = localPosition.dx.clamp(0.0, spectrumSize);
                    final y = localPosition.dy.clamp(0.0, spectrumSize);
                    final s = (x / spectrumSize).clamp(0.0, 1.0);
                    final v = (1.0 - (y / spectrumSize)).clamp(0.0, 1.0);
                    _updateColor(_hue, s, v);
                  },
                  onTapDown: (details) {
                    final box = _spectrumKey.currentContext?.findRenderObject()
                        as RenderBox?;
                    if (box == null) return;
                    final localPosition =
                        box.globalToLocal(details.globalPosition);
                    final x = localPosition.dx.clamp(0.0, spectrumSize);
                    final y = localPosition.dy.clamp(0.0, spectrumSize);
                    final s = (x / spectrumSize).clamp(0.0, 1.0);
                    final v = (1.0 - (y / spectrumSize)).clamp(0.0, 1.0);
                    _updateColor(_hue, s, v);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Hue slider
        Row(
          children: [
            Text(
              'Hue',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: List.generate(
                      6,
                      (i) =>
                          HSVColor.fromAHSV(1.0, i * 60.0, 1.0, 1.0).toColor(),
                    ),
                  ),
                ),
                child: Slider(
                  value: _hue,
                  min: 0.0,
                  max: 360.0,
                  onChanged: (value) =>
                      _updateColor(value, _saturation, _brightness),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Selected color preview
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: selectedColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.colorValue});
  final int colorValue;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 10,
      backgroundColor: Color(colorValue),
    );
  }
}

class _EditColorCodedItemSheet extends StatefulWidget {
  const _EditColorCodedItemSheet({
    required this.item,
    required this.onSave,
  });

  final ColorCodedItem item;
  final Future<ColorCodedItem> Function(String name, int colorValue) onSave;

  @override
  State<_EditColorCodedItemSheet> createState() =>
      _EditColorCodedItemSheetState();
}

class _EditColorCodedItemSheetState extends State<_EditColorCodedItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late double _hue;
  late double _saturation;
  late double _brightness;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    final color = Color(widget.item.colorValue);
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _brightness = hsv.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _getSelectedColor() {
    return HSVColor.fromAHSV(1.0, _hue, _saturation, _brightness).toColor();
  }

  int _colorToIntValue(Color color) {
    final a = (color.a * 255.0).round().clamp(0, 255);
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true || _saving) return;
    setState(() => _saving = true);
    try {
      final colorValue = _colorToIntValue(_getSelectedColor());
      final updated =
          await widget.onSave(_nameController.text.trim(), colorValue);
      if (mounted) Navigator.of(context).pop(updated);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                _FullColorPicker(
                  hue: _hue,
                  saturation: _saturation,
                  brightness: _brightness,
                  onColorChanged: (h, s, v) {
                    setState(() {
                      _hue = h;
                      _saturation = s;
                      _brightness = v;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Saving...' : 'Save'),
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
