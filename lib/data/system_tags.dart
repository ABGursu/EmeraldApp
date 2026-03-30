import 'models/tag_model.dart';

/// App-defined tags that must stay on both Balance and Shopping.
/// Only [TagModel.colorValue] may change; name, visibility, and delete are blocked.
class SystemTags {
  SystemTags._();

  static const Set<String> _normalizedNames = {'shopping', 'rented'};

  static bool isSystemTagName(String name) =>
      _normalizedNames.contains(name.trim().toLowerCase());

  static bool isSystemTag(TagModel tag) => isSystemTagName(tag.name);
}
