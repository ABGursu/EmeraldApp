import 'dart:async';

import 'package:http/http.dart' as http;

/// Fetches Open Graph metadata using async HTTP (does not block the UI isolate;
/// work is still bounded by [timeout]).
class LinkPreviewResult {
  const LinkPreviewResult({this.title, this.imageUrl});

  final String? title;
  final String? imageUrl;

  static const empty = LinkPreviewResult();
}

abstract class LinkPreviewService {
  static const _userAgent =
      'Mozilla/5.0 (compatible; EmeraldApp/1.0) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  /// Returns best-effort title and image URL; never throws.
  static Future<LinkPreviewResult> fetchPreview(Uri pageUri) async {
    final client = http.Client();
    try {
      final response = await client
          .get(
            pageUri,
            headers: {'User-Agent': _userAgent},
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode < 200 || response.statusCode >= 400) {
        return LinkPreviewResult.empty;
      }

      final body = response.body;
      final snippet = body.length > 400000 ? body.substring(0, 400000) : body;

      final title = _metaContent(snippet, 'og:title') ??
          _metaContent(snippet, 'twitter:title') ??
          _htmlTitle(snippet);
      final rawImage = _metaContent(snippet, 'og:image') ??
          _metaContent(snippet, 'twitter:image');

      String? imageUrl;
      if (rawImage != null && rawImage.trim().isNotEmpty) {
        imageUrl = _resolveUrl(pageUri, rawImage.trim());
      }

      final cleanedTitle =
          title != null ? _decodeBasicEntities(title.trim()) : null;

      return LinkPreviewResult(
        title: cleanedTitle?.isEmpty ?? true ? null : cleanedTitle,
        imageUrl: imageUrl,
      );
    } on TimeoutException {
      return LinkPreviewResult.empty;
    } catch (_) {
      return LinkPreviewResult.empty;
    } finally {
      client.close();
    }
  }

  static Uri? normalizeUserUrl(String input) {
    var t = input.trim();
    if (t.isEmpty) return null;
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(t)) {
      t = 'https://$t';
    }
    final uri = Uri.tryParse(t);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  static String fallbackTitle(Uri uri) {
    final host = uri.host;
    return host.isEmpty ? 'Link' : host;
  }

  static String? _metaContent(String html, String property) {
    final p = RegExp.escape(property);
    final re1 = RegExp(
      '<meta[^>]*property\\s*=\\s*["\']$p["\'][^>]*content\\s*=\\s*["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    final re2 = RegExp(
      '<meta[^>]*content\\s*=\\s*["\']([^"\']*)["\'][^>]*property\\s*=\\s*["\']$p["\']',
      caseSensitive: false,
    );
    final re3 = RegExp(
      '<meta[^>]*name\\s*=\\s*["\']$p["\'][^>]*content\\s*=\\s*["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    return re1.firstMatch(html)?.group(1) ??
        re2.firstMatch(html)?.group(1) ??
        re3.firstMatch(html)?.group(1);
  }

  static String? _htmlTitle(String html) {
    final m = RegExp(
      r'<title[^>]*>([^<]*)</title>',
      caseSensitive: false,
    ).firstMatch(html);
    return m?.group(1)?.trim();
  }

  static String? _resolveUrl(Uri base, String ref) {
    try {
      return base.resolve(ref).toString();
    } catch (_) {
      return ref;
    }
  }

  static String _decodeBasicEntities(String s) {
    return s
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
