// DOmain/IP Endpoint API
const String ipServer = 'api-service.toscaflow.id';

// =========================================================
// DAFTAR ENDPOINT API
// =========================================================

// Endpoint Autentikasi
const String endpointRegister = 'https://$ipServer/api/register';
const String endpointLogin = 'https://$ipServer/api/login';

// Endpoint Materi & Cerita
const String endpointMateri = 'https://$ipServer/api/materi';

// Endpoint Favorit / Bookmark
const String endpointFavorit = 'https://$ipServer/api/favorit';

//Endpoint Komentar
const String endpointKomentar = 'https://$ipServer/api/komentar';

// Endpoint User (Profil & Keamanan)
const String endpointUserProfil = 'https://$ipServer/api/user/profil';
const String endpointUserPassword = 'https://$ipServer/api/user/password';

// Endpoint Lupa Password
const String endpointCekEmail = 'https://$ipServer/api/cek-email';
const String endpointResetPassword = 'https://$ipServer/api/reset-password';

// Endpoint Kuis
const String endpointQuiz = 'https://$ipServer/api/quiz';
const String endpointQuizSubmit = 'https://$ipServer/api/quiz/submit';
const String endpointQuizScore = 'https://$ipServer/api/quiz/score';
const String staticAuthToken = 'Bearer T0sc4Fl0w_S3cr3t_2026';
