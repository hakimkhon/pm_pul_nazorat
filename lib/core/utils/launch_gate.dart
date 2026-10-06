import 'dart:async';

/// Bildirishnoma tugmasi bilan ochilgan ilovada "launch" javobi qayta ishlanib
/// bo'lguncha Splash qoidalarni qayta rejalashtirmasligi uchun.
final Completer<void> launchHandled = Completer<void>();