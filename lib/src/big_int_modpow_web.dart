@JS()
library bigint_modpow;

import 'package:js/js.dart';

@JS('jsBigIntModPow')
external String jsBigIntModPow(String b, String e, String m);

BigInt modPow(BigInt? b, BigInt e, BigInt? m) {
  if (b != null && m != null) {
    try {
      return BigInt.parse(
        jsBigIntModPow(b.toString(), e.toString(), m.toString()),
      );
    } on NoSuchMethodError {
      return b.modPow(e, m);
    }
  }

  return BigInt.one;
}
