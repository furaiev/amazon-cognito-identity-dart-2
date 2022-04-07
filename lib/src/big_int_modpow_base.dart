BigInt modPow(BigInt? b, BigInt e, BigInt? m) {
  if (b != null && m != null) {
    return b.modPow(e, m);
  }

  return BigInt.one;
}
