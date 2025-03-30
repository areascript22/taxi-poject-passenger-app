class RequestDriverUtil {

  //convert duration from Routes to int value
  static int extractMinutes(String duration) {
    RegExp regex = RegExp(r'\d+'); // Extracts numeric digits
    Match? match = regex.firstMatch(duration);

    if (match != null) {
      return int.parse(match.group(0)!); // Convert extracted value to int
    }

    return 0; // Default to 0 if no match is found
  }
}
