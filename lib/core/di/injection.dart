import 'dart:io' show Platform;



import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart' show kIsWeb;



import '../../firebase_options.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';

import '../../features/auth/data/datasources/firebase_auth_remote_datasource.dart';

import '../../features/auth/data/datasources/windows_rest_auth_remote_datasource.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';

import '../../features/auth/domain/usecases/sign_in_with_email_password.dart';

import '../../features/auth/domain/usecases/sign_out.dart';

import '../../features/auth/domain/usecases/sign_up_with_email_password.dart';

import '../../features/auth/presentation/viewmodels/auth_view_model.dart';

import '../../features/upload/data/datasources/audio_file_picker_datasource.dart';

import '../../features/upload/data/datasources/storage_upload_datasource.dart';

import '../../features/upload/data/datasources/upload_api_datasource.dart';

import '../../features/upload/data/repositories/upload_repository_impl.dart';

import '../../features/upload/domain/repositories/upload_repository.dart';

import '../../features/upload/domain/usecases/pick_audio_file.dart';

import '../../features/upload/domain/usecases/upload_audio_file.dart';

import '../../features/upload/presentation/viewmodels/upload_view_model.dart';
import '../../features/separation/data/datasources/separation_api_datasource.dart';
import '../../features/separation/data/repositories/separation_repository_impl.dart';
import '../../features/separation/domain/repositories/separation_repository.dart';
import '../../features/separation/domain/usecases/create_separation_job.dart';
import '../../features/separation/domain/usecases/get_separation_job.dart';
import '../../features/separation/presentation/viewmodels/separation_view_model.dart';
import '../../features/mixer/presentation/viewmodels/mixer_view_model.dart';
import '../../features/export/data/datasources/stem_file_exporter.dart';
import '../../features/export/domain/usecases/export_stem_file.dart';
import '../../features/export/domain/usecases/export_stems_zip.dart';
import '../../features/export/presentation/viewmodels/export_view_model.dart';

import '../auth/auth_session_store.dart';

import '../auth/firebase_session_token_provider.dart';

import '../network/authenticated_http_client.dart';

import '../utils/file_hash_calculator.dart';



late final AuthSessionStore authSessionStore;

late final FirebaseSessionTokenProvider? sessionTokenProvider;

late final AuthRepository authRepository;

late final AuthViewModel authViewModel;

late final UploadRepository uploadRepository;

late final UploadViewModel uploadViewModel;
late final SeparationRepository separationRepository;
late final SeparationViewModel separationViewModel;
late final MixerViewModel mixerViewModel;
late final ExportViewModel exportViewModel;



bool get _useWindowsRestAuth => !kIsWeb && Platform.isWindows;



void initDependencies() {

  authSessionStore = AuthSessionStore();



  final AuthRemoteDataSource remote = _useWindowsRestAuth

      ? WindowsRestAuthRemoteDataSource(

          apiKey: DefaultFirebaseOptions.windows.apiKey,

          sessionStore: authSessionStore,

        )

      : FirebaseAuthRemoteDataSource(FirebaseAuth.instance);



  authRepository = AuthRepositoryImpl(remote);

  sessionTokenProvider = _useWindowsRestAuth
      ? FirebaseSessionTokenProvider(
          apiKey: DefaultFirebaseOptions.windows.apiKey,
          sessionStore: authSessionStore,
        )
      : null;

  authViewModel = AuthViewModel(

    signIn: SignInWithEmailPassword(authRepository),

    signUp: SignUpWithEmailPassword(authRepository),

    signOut: SignOut(authRepository),

  );



  final authenticatedClient = AuthenticatedHttpClient(

    auth: FirebaseAuth.instance,

    sessionTokenProvider: sessionTokenProvider,

    useSessionStore: _useWindowsRestAuth,

  );

  uploadRepository = UploadRepositoryImpl(

    picker: AudioFilePickerDataSource(),

    uploadApi: UploadApiDataSource(authenticatedClient),

    storageUpload: StorageUploadDataSource(),

    hashCalculator: FileHashCalculator(),

  );



  uploadViewModel = UploadViewModel(

    pickAudioFile: PickAudioFile(uploadRepository),

    uploadAudioFile: UploadAudioFile(uploadRepository),

  );

  separationRepository = SeparationRepositoryImpl(
    SeparationApiDataSource(authenticatedClient),
  );

  separationViewModel = SeparationViewModel(
    createJob: CreateSeparationJob(separationRepository),
    getJob: GetSeparationJob(separationRepository),
  );

  mixerViewModel = MixerViewModel(
    getSeparationJob: GetSeparationJob(separationRepository),
  );

  final exportRepository = StemFileExporter();
  exportViewModel = ExportViewModel(
    getSeparationJob: GetSeparationJob(separationRepository),
    exportStemFile: ExportStemFile(exportRepository),
    exportStemsZip: ExportStemsZip(exportRepository),
  );
}

