import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/tab_inspector_item_model.dart';
import '../../data/repositories/i_tab_inspector_repository.dart';
import '../../data/repositories/sql_tab_inspector_repository.dart';
import '../../services/link_preview_service.dart';
import '../../utils/id_generator.dart';

class TabInspectorViewModel extends ChangeNotifier {
  TabInspectorViewModel({ITabInspectorRepository? repository})
      : _repository = repository ?? SqlTabInspectorRepository();

  final ITabInspectorRepository _repository;

  List<TabInspectorItem> _items = [];
  bool _loading = false;

  List<TabInspectorItem> get items => _items;
  bool get isLoading => _loading;

  List<TabInspectorItem> get openItems =>
      _items.where((e) => !e.isDone).toList();

  List<TabInspectorItem> get doneItems =>
      _items.where((e) => e.isDone).toList();

  Future<void> init() async {
    await loadItems();
  }

  Future<void> loadItems() async {
    _loading = true;
    notifyListeners();
    _items = await _repository.getAll();
    _loading = false;
    notifyListeners();
  }

  Future<bool> addLink({
    required String titleInput,
    required String urlInput,
  }) async {
    final uri = LinkPreviewService.normalizeUserUrl(urlInput);
    if (uri == null) return false;

    final manualTitle = titleInput.trim();
    final hadManualTitle = manualTitle.isNotEmpty;
    final provisionalTitle =
        hadManualTitle ? manualTitle : LinkPreviewService.fallbackTitle(uri);

    final item = TabInspectorItem(
      id: generateId(),
      title: provisionalTitle,
      url: uri.toString(),
      isDone: false,
      previewImageUrl: null,
      createdAt: DateTime.now(),
    );

    await _repository.create(item);
    await loadItems();

    unawaited(_enrichAfterAdd(item.id, hadManualTitle));
    return true;
  }

  Future<void> _enrichAfterAdd(String id, bool hadManualTitle) async {
    final current = await _repository.getById(id);
    if (current == null) return;

    final preview = await LinkPreviewService.fetchPreview(Uri.parse(current.url));

    final title = hadManualTitle
        ? current.title
        : (preview.title?.isNotEmpty == true
            ? preview.title!
            : LinkPreviewService.fallbackTitle(Uri.parse(current.url)));

    final updated = current.copyWith(
      title: title,
      previewImageUrl: preview.imageUrl ?? current.previewImageUrl,
    );

    await _repository.update(updated);
    await loadItems();
  }

  /// Updates title and URL. Re-fetches preview when the URL changes.
  Future<bool> updateItem({
    required String id,
    required String titleInput,
    required String urlInput,
  }) async {
    final uri = LinkPreviewService.normalizeUserUrl(urlInput);
    if (uri == null) return false;

    final current = await _repository.getById(id);
    if (current == null) return false;

    final manualTitle = titleInput.trim();
    final hadManualTitle = manualTitle.isNotEmpty;
    final newUrl = uri.toString();
    final urlChanged = newUrl != current.url;

    final provisionalTitle = hadManualTitle
        ? manualTitle
        : LinkPreviewService.fallbackTitle(uri);

    final updated = current.copyWith(
      title: provisionalTitle,
      url: newUrl,
      previewImageUrl: urlChanged ? null : current.previewImageUrl,
    );

    await _repository.update(updated);
    await loadItems();

    if (urlChanged) {
      unawaited(_enrichAfterEdit(id, hadManualTitle));
    }
    return true;
  }

  Future<void> _enrichAfterEdit(String id, bool hadManualTitle) async {
    final current = await _repository.getById(id);
    if (current == null) return;

    final preview = await LinkPreviewService.fetchPreview(Uri.parse(current.url));

    final title = hadManualTitle
        ? current.title
        : (preview.title?.isNotEmpty == true
            ? preview.title!
            : LinkPreviewService.fallbackTitle(Uri.parse(current.url)));

    final merged = current.copyWith(
      title: title,
      previewImageUrl: preview.imageUrl ?? current.previewImageUrl,
    );

    await _repository.update(merged);
    await loadItems();
  }

  Future<void> setDone(String id, bool done) async {
    TabInspectorItem? item;
    for (final e in _items) {
      if (e.id == id) {
        item = e;
        break;
      }
    }
    if (item == null) return;
    await _repository.update(item.copyWith(isDone: done));
    await loadItems();
  }

  Future<void> deleteItem(String id) async {
    await _repository.delete(id);
    await loadItems();
  }

  /// Persists order for open items only (0 .. n-1).
  Future<void> reorderOpenItems(int oldIndex, int newIndex) async {
    final open = openItems.toList();
    if (oldIndex < 0 || oldIndex >= open.length) return;
    if (newIndex < 0 || newIndex > open.length) return;
    var dest = newIndex;
    if (dest > oldIndex) dest -= 1;
    final moved = open.removeAt(oldIndex);
    open.insert(dest, moved);
    for (var i = 0; i < open.length; i++) {
      await _repository.update(open[i].copyWith(sortOrder: i));
    }
    await loadItems();
  }
}
