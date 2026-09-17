enum PeriodType { daily, weekly, monthly, yearly }

class DateRangeHelper {
  static DateTime startOf(PeriodType type, DateTime reference) {
    switch (type) {
      case PeriodType.daily:
        return DateTime(reference.year, reference.month, reference.day);
      case PeriodType.weekly:
        final weekday = reference.weekday; // 1 = Dushanba
        final start = reference.subtract(Duration(days: weekday - 1));
        return DateTime(start.year, start.month, start.day);
      case PeriodType.monthly:
        return DateTime(reference.year, reference.month, 1);
      case PeriodType.yearly:
        return DateTime(reference.year, 1, 1);
    }
  }

  static DateTime endOf(PeriodType type, DateTime reference) {
    switch (type) {
      case PeriodType.daily:
        return DateTime(reference.year, reference.month, reference.day, 23, 59, 59);
      case PeriodType.weekly:
        final start = startOf(PeriodType.weekly, reference);
        return start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      case PeriodType.monthly:
        final nextMonth = reference.month == 12
            ? DateTime(reference.year + 1, 1, 1)
            : DateTime(reference.year, reference.month + 1, 1);
        return nextMonth.subtract(const Duration(seconds: 1));
      case PeriodType.yearly:
        return DateTime(reference.year, 12, 31, 23, 59, 59);
    }
  }

  static String label(PeriodType type, DateTime reference) {
    const months = [
      'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
      'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'
    ];
    switch (type) {
      case PeriodType.daily:
        return '${reference.day} ${months[reference.month - 1]}, ${reference.year}';
      case PeriodType.weekly:
        final start = startOf(PeriodType.weekly, reference);
        final end = endOf(PeriodType.weekly, reference);
        return '${start.day}-${end.day} ${months[end.month - 1]}';
      case PeriodType.monthly:
        return '${months[reference.month - 1]} ${reference.year}';
      case PeriodType.yearly:
        return '${reference.year}-yil';
    }
  }

  static DateTime shift(PeriodType type, DateTime reference, int direction) {
    switch (type) {
      case PeriodType.daily:
        return reference.add(Duration(days: direction));
      case PeriodType.weekly:
        return reference.add(Duration(days: 7 * direction));
      case PeriodType.monthly:
        return DateTime(reference.year, reference.month + direction, reference.day);
      case PeriodType.yearly:
        return DateTime(reference.year + direction, reference.month, reference.day);
    }
  }
}