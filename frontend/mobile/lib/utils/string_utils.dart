String safeInitial(dynamic value, {String fallback = '?'}) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) {
    return fallback;
  }
  return text.substring(0, 1).toUpperCase();
}