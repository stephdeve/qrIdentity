String flagEmoji(String isoCode) {
  if (isoCode.isEmpty) return '';
  final code = isoCode.toUpperCase();
  if (code.length != 2) return '';
  final int first = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
  final int second = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
  return String.fromCharCode(first) + String.fromCharCode(second);
}
