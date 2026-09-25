import 'package:intl/intl.dart';

String formatDate(DateTime? dt) =>
    dt == null ? '—' : DateFormat('d MMM yyyy').format(dt);

String formatDateTime(DateTime? dt) =>
    dt == null ? '—' : DateFormat('d MMM yyyy, h:mm a').format(dt);
