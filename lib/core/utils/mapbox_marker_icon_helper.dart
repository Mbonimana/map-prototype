class MapboxIconHelper {
  static String getAsset(String category) {
    switch (category) {
      case "user":
        return "assets/icons/user.png";

      case "landmark":
        return "assets/icons/landmark.png";

      case "business":
        return "assets/icons/business.png";

      case "service":
        return "assets/icons/service.png";

      default:
        return "assets/icons/default.png";
    }
  }
}
