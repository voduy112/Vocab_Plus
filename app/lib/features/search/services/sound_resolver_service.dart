class SoundResolverService {
  // Resolve a Commons file name to a direct playable URL via redirect endpoint
  Future<String?> resolveCommonsUrl(String fileName) async {
    if (fileName.isEmpty) return null;
    // Use Special:Redirect which returns a 302 to the actual file URL
    // Most audio players (like audioplayers with UrlSource) can follow redirects.
    final encoded = Uri.encodeComponent(fileName);
    return 'https://commons.wikimedia.org/wiki/Special:Redirect/file/$encoded';
  }
}
