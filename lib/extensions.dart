extension IterableExt<T> on Iterable<T> {
  T? safeElementAt(int index) {
    try {
      return this.elementAt(index);
    } catch (e) {
      return null;
    }
  }
}
