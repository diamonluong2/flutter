class Blacklist {
  // Danh sách các từ bị cấm (có thể mở rộng thêm)
  static const List<String> bannedWords = [
    'fuck',
    'f*ck',
    'f**k',
    'shit',
    'sh*t',
    'damn',
    'dammit',
    'bitch',
    'b*tch',
    'asshole',
    'a**hole',
    'bastard',
    'crap',
    'piss',
    'dick',
    'd*ck',
    'pussy',
    'p*ssy',
    'cock',
    'c*ck',
    'whore',
    'slut',
    'cunt',
    'c*nt',
    'nigger',
    'n*gger',
    'nigga',
    'n*gga',
    // Thêm các từ tiếng Việt nếu cần
    'đụ',
    'đ*t',
    'đm',
    'đcm',
    'địt',
    'đ*t mẹ',
    'đ*t má',
    'cặc',
    'c*c',
    'lồn',
    'l*n',
    'buồi',
    'b*oi',
    'đéo',
    'đ*o',
    'dm',
    'đcm',
    'địt',
    'đ*t',
    'ma'
        'lon',
  ];

  /// Kiểm tra xem nội dung có chứa từ bị cấm không
  /// Trả về danh sách các từ vi phạm nếu có, null nếu không có
  static List<String>? checkContent(String content) {
    if (content.isEmpty) return null;

    // Chuyển nội dung về chữ thường để so sánh không phân biệt hoa thường
    final lowerContent = content.toLowerCase();

    final foundWords = <String>[];

    // Kiểm tra từng từ trong blacklist
    for (final word in bannedWords) {
      final lowerWord = word.toLowerCase();

      // Tạo pattern để tìm từ, xử lý cả trường hợp có dấu sao (*)
      // Thay thế * bằng \w* để match bất kỳ ký tự nào
      final escapedWord = lowerWord.replaceAll('*', r'\w*');

      // Tạo regex pattern để tìm từ đầy đủ (word boundary)
      final wordPattern = RegExp(
        r'\b' + escapedWord + r'\b',
        caseSensitive: false,
      );

      if (wordPattern.hasMatch(lowerContent)) {
        foundWords.add(word);
      }
    }

    return foundWords.isEmpty ? null : foundWords;
  }

  /// Kiểm tra và trả về true nếu nội dung vi phạm
  static bool hasBannedWords(String content) {
    return checkContent(content) != null;
  }

  /// Lấy thông báo lỗi khi phát hiện từ vi phạm
  static String getErrorMessage(List<String> bannedWords) {
    if (bannedWords.isEmpty) {
      return 'Nội dung chứa từ ngữ không phù hợp';
    }

    if (bannedWords.length == 1) {
      return 'Nội dung chứa từ ngữ không phù hợp: "${bannedWords.first}"';
    }

    return 'Nội dung chứa ${bannedWords.length} từ ngữ không phù hợp';
  }
}
