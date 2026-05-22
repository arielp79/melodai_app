import 'package:firebase_auth/firebase_auth.dart';

import 'package:http/http.dart' as http;



import '../auth/firebase_session_token_provider.dart';



/// Cliente HTTP que adjunta el ID token de Firebase en cada petición.

class AuthenticatedHttpClient extends http.BaseClient {

  AuthenticatedHttpClient({

    http.Client? inner,

    FirebaseAuth? auth,

    FirebaseSessionTokenProvider? sessionTokenProvider,

    bool useSessionStore = false,

  })  : _inner = inner ?? http.Client(),

        _auth = auth ?? FirebaseAuth.instance,

        _sessionTokenProvider = sessionTokenProvider,

        _useSessionStore = useSessionStore;



  final http.Client _inner;

  final FirebaseAuth _auth;

  final FirebaseSessionTokenProvider? _sessionTokenProvider;

  final bool _useSessionStore;



  @override

  Future<http.StreamedResponse> send(http.BaseRequest request) async {

    final String token;

    if (_useSessionStore) {

      final provider = _sessionTokenProvider;

      if (provider == null) {

        throw StateError('Proveedor de token no configurado.');

      }

      token = await provider.getIdToken();

    } else {

      final user = _auth.currentUser;

      if (user == null) {

        throw StateError('No hay sesión activa para llamar al backend.');

      }

      token = (await user.getIdToken()) ?? '';

    }



    request.headers['Authorization'] = 'Bearer $token';

    return _inner.send(request);

  }



  @override

  void close() => _inner.close();

}

