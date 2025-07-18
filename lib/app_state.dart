class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();
  String? userId;

  void setUserResponse(String id) => userId = id;
  String? getUserResponse() => userId;
}
