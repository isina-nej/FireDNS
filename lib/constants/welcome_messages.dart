/// متن‌های خوش‌آمدگویی برای زبان‌های مختلف
class WelcomeMessages {
  static const Map<String, Map<String, String>> messages = {
    'fa': {
      'title': '🔥 به Fire DNS خوش آمدید!',
      'message': '''سلام و درود! 👋

به جمع کاربران Fire DNS خوش آمدید! 🎉

🔒 حریم خصوصی شما محفوظ
⚡ سرعت اتصال بهتر
🛡️ امنیت بالا
🌐 دسترسی آزاد به اینترنت

از همین الان می‌توانید DNS دلخواه خود را انتخاب کرده و از اینترنت سریع‌تر و امن‌تری لذت ببرید.

موفق باشید! 🚀'''
    },
    'en': {
      'title': '🔥 Welcome to Fire DNS!',
      'message': '''Hello there! 👋

Welcome to the Fire DNS community! 🎉

🔒 Your privacy is protected
⚡ Better connection speed  
🛡️ High security
🌐 Free internet access

You can now choose your preferred DNS and enjoy faster, more secure internet.

Best of luck! 🚀'''
    },
    'ar': {
      'title': '🔥 مرحباً بكم في Fire DNS!',
      'message': '''السلام عليكم! 👋

مرحباً بكم في مجتمع Fire DNS! 🎉

🔒 خصوصيتكم محمية
⚡ سرعة اتصال أفضل
🛡️ أمان عالي
🌐 وصول مجاني للإنترنت

يمكنكم الآن اختيار DNS المفضل والاستمتاع بإنترنت أسرع وأكثر أماناً.

حظاً موفقاً! 🚀'''
    },
    'ru': {
      'title': '🔥 Добро пожаловать в Fire DNS!',
      'message': '''Привет! 👋

Добро пожаловать в сообщество Fire DNS! 🎉

🔒 Ваша конфиденциальность защищена
⚡ Лучшая скорость соединения
🛡️ Высокая безопасность  
🌐 Свободный доступ к интернету

Теперь вы можете выбрать предпочитаемый DNS и наслаждаться более быстрым и безопасным интернетом.

Удачи! 🚀'''
    },
    'zh': {
      'title': '🔥 欢迎使用 Fire DNS！',
      'message': '''你好！👋

欢迎加入 Fire DNS 社区！🎉

🔒 您的隐私受到保护
⚡ 更好的连接速度
🛡️ 高安全性
🌐 自由访问互联网

现在您可以选择首选的DNS，享受更快、更安全的互联网。

祝您好运！🚀'''
    }
  };

  /// دریافت پیام خوش‌آمدگویی بر اساس زبان
  static Map<String, String> getWelcomeMessage(String languageCode) {
    // اگر زبان پیدا نشد، از فارسی به عنوان پیش‌فرض استفاده کن
    return messages[languageCode] ?? messages['fa']!;
  }

  /// دریافت عنوان خوش‌آمدگویی
  static String getWelcomeTitle(String languageCode) {
    return getWelcomeMessage(languageCode)['title']!;
  }

  /// دریافت متن خوش‌آمدگویی
  static String getWelcomeMessageText(String languageCode) {
    return getWelcomeMessage(languageCode)['message']!;
  }

  /// لیست زبان‌های پشتیبانی شده
  static List<String> get supportedLanguages => messages.keys.toList();
}
