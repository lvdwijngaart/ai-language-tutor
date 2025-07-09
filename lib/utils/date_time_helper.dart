DateTime getDateTimeFromMapItem(dateTime) {
  if (dateTime is String) {
    return DateTime.parse(dateTime);
  } else if (dateTime is DateTime) {
    return dateTime;
  } else {
    throw ArgumentError(
      'created_at must be a valid DateTime string or DateTime object',
    );
  }
}
