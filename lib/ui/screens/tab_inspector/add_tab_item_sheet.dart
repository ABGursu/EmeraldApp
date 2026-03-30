import 'package:flutter/material.dart';

/// English-only form: title + URL (rapid capture).
class AddTabItemSheet extends StatefulWidget {
  const AddTabItemSheet({super.key});

  @override
  State<AddTabItemSheet> createState() => _AddTabItemSheetState();
}

class _AddTabItemSheetState extends State<AddTabItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Save tab for later',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  hintText: 'Site name or your own label',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL *',
                  hintText: 'https://…',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                autofocus: true,
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Enter a link';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() != true) return;
                    Navigator.pop(context, (
                      title: _titleController.text,
                      url: _urlController.text,
                    ));
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
