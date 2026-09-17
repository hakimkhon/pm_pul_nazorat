import 'package:flutter/material.dart';

class IconHelper {
  // Kengaytirilgan ikonalar to'plami — bo'lim yaratishda foydalanuvchi shu
  // ro'yxatdan tanlaydi. Toifalar bo'yicha guruhlangan (chiqim va kirim uchun).
  static const Map<String, IconData> iconMap = {
    // Oziq-ovqat
    'restaurant': Icons.restaurant,
    'fastfood': Icons.lunch_dining,
    'coffee': Icons.coffee,
    'groceries': Icons.shopping_basket,

    // Transport
    'directions_bus': Icons.directions_bus,
    'car': Icons.directions_car,
    'fuel': Icons.local_gas_station,
    'flight': Icons.flight,
    'train': Icons.train,
    'taxi': Icons.local_taxi,

    // Sog'liq
    'local_hospital': Icons.local_hospital,
    'medication': Icons.medication,
    'fitness': Icons.fitness_center,
    'spa': Icons.spa,

    // Kommunal / uy
    'bolt': Icons.bolt,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'phone_android': Icons.phone_android,
    'home': Icons.home,
    'apartment': Icons.apartment,
    'handyman': Icons.handyman,

    // Ko'ngilochar / turmush tarzi
    'movie': Icons.movie,
    'sports_esports': Icons.sports_esports,
    'music_note': Icons.music_note,
    'menu_book': Icons.menu_book,
    'sports_soccer': Icons.sports_soccer,

    // Ta'lim / bola
    'school': Icons.school,
    'child_care': Icons.child_care,

    // Xarid
    'shopping_cart': Icons.shopping_cart,
    'checkroom': Icons.checkroom,
    'card_giftcard': Icons.card_giftcard,

    // Boshqa
    'pets': Icons.pets,
    'luggage': Icons.luggage,
    'volunteer_activism': Icons.volunteer_activism,
    'receipt_long': Icons.receipt_long,
    'shield': Icons.shield,
    'subscriptions': Icons.subscriptions,

    // Kirim turlari
    'work': Icons.work,
    'attach_money': Icons.attach_money,
    'business_center': Icons.business_center,
    'trending_up': Icons.trending_up,
    'savings': Icons.savings,
    'laptop_mac': Icons.laptop_mac,
    'real_estate_agent': Icons.real_estate_agent,
    'redeem': Icons.redeem,
    'percent': Icons.percent,

    'more_horiz': Icons.more_horiz,
  };

  static IconData getIcon(String code) => iconMap[code] ?? Icons.category;

  // Kengaytirilgan rang palitrasi — brend rangiga uyg'un, lekin
  // bo'limlarni bir-biridan farqlash uchun yetarlicha xilma-xil
  static const List<Color> colorPalette = [
    Color(0xFFFF7043), // to'q sarg'ish
    Color(0xFF42A5F5), // moviy
    Color(0xFFEF5350), // qizil
    Color(0xFFFFCA28), // sariq
    Color(0xFFAB47BC), // siyohrang
    Color(0xFF1B8A6B), // zumrad (brend)
    Color(0xFF26A69A), // teal
    Color(0xFF8D6E63), // jigarrang
    Color(0xFF5C6BC0), // indigo
    Color(0xFFEC407A), // pink
    Color(0xFF78909C), // ko'k-kul
    Color(0xFFE8A33D), // oltin (brend aksent)
    Color(0xFF66BB6A), // yashil
    Color(0xFF7E57C2), // binafsha
    Color(0xFF26C6DA), // firuza
    Color(0xFFD4E157), // laym
  ];
}