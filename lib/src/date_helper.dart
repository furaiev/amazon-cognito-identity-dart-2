final List<String> monthNames = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];
final List<String> weekNames = [
  '',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun'
];

class DateHelper {
  /// The current time in "ddd MMM D HH:mm:ss UTC YYYY" format.
  String getNowString() {
    final now = DateTime.now().toUtc();

    final weekDay = weekNames[now.weekday];
    final month = monthNames[now.month];
    final day = now.day.toString();
    var hours = now.hour.toString();
    if (now.hour < 10) {
      hours = '0${now.hour.toString()}';
    }
    var minutes = now.minute.toString();
    if (now.minute < 10) {
      minutes = '0${now.minute.toString()}';
    }
    var seconds = now.second.toString();
    if (now.second < 10) {
      seconds = '0${now.second.toString()}';
    }
    var year = now.year.toString();

    return '$weekDay $month $day $hours:$minutes:$seconds UTC $year';
  }
}
