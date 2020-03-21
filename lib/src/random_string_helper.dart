import 'dart:math';

const List<String> _hexCharList = [
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  'a',
  'b',
  'c',
  'd',
  'e',
  'f'
];

class RandomString {
  final Random _random;

  RandomString({bool secure = true, int seed})
      : _random = (secure
            ? Random.secure()
            : (seed == null ? Random() : Random(seed)));

  String generate({int length = 1024, List<String> charList = _hexCharList}) {
    final strings = [];
    for (var point = 0; point < length; ++point) {
      strings.add(charList[_random.nextInt(charList.length - 1)]);
    }
    return strings.join();
  }
}
