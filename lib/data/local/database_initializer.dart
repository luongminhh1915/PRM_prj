import 'database_initializer_stub.dart'
    if (dart.library.html) 'database_initializer_web.dart'
    if (dart.library.io) 'database_initializer_io.dart'
    as platform_init;

Future<void> initDatabase() => platform_init.initDatabase();
