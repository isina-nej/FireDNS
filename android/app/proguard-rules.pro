# جلوگیری از حذف کلاس‌های مورد نیاز dnsjava توسط R8
-keep class sun.net.spi.nameservice.** { *; }
-keep class sun.net.spi.nameservice.NameServiceDescriptor { *; }
-dontwarn sun.net.spi.nameservice.**
