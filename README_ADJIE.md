# README_ADJIE.md — Modul: feature/offlineSync

> Dikerjakan oleh: **Adjie Ali Nurfizal (241511034)**  
> Branch: `feature/offlineSync`  
> Sprint: 4 (Week 12)

---

## Apa yang dikerjakan di modul ini

Modul ini mengimplementasikan **SyncManager** — sistem sinkronisasi data antara
Hive lokal (di HP user) dan MongoDB Atlas (cloud) sesuai arsitektur **Offline-First**.

Prinsip utama: **tulis ke Hive lokal dulu, kirim ke cloud belakangan.**
App tidak pernah menunggu response dari cloud sebelum melanjutkan.

---

## File yang dibuat

```
lib/features/sync/
├── models/
│   ├── sync_queue_model.dart       # Model entitas SyncQueue di Hive
│   └── sync_queue_model.g.dart     # Hive adapter (generate: flutter pub run build_runner build)
├── services/
│   ├── sync_repository.dart        # CRUD operasi SyncQueue di Hive
│   ├── api_service.dart            # HTTP calls ke backend Node.js
│   └── sync_manager.dart           # Inti SyncManager (StateNotifier)
├── providers/
│   └── sync_providers.dart         # Semua Riverpod provider untuk sync
├── widgets/
│   └── sync_indicator_widget.dart  # Widget baris indikator 🟢🟡🔴
└── screens/
    └── profil_screen.dart          # Layar Profil + tombol Sync Now

test/features/sync/
└── sync_manager_test.dart          # Unit test (8 group, 20+ test case)
```

File yang diupdate:
- `pubspec.yaml` → tambah `connectivity_plus`, `http`, `uuid`, `hive_generator`, `build_runner`
- `lib/main.dart` → register Hive adapter, buka box `sync_queue`, pasang `ProfilScreen`

---

## Cara kerja SyncManager

```
User melakukan aksi (jawab soal, submit soal, dll.)
        │
        ▼
Tulis ke Hive lokal dulu  ←── Offline-first guarantee
        │
        ▼
Tambahkan ke SyncQueue (status: PENDING, timestamp: now)
        │
        ├──── Kalau online → SyncManager langsung proses
        │
        └──── Kalau offline → tunggu sampai online
                              │
                              ▼
                  connectivity_plus mendeteksi jaringan
                              │
                              ▼
                  SyncManager.processPendingQueue()
                              │
                    ┌─────────┴─────────┐
                    │   FIFO: ambil     │
                    │  entri tertua     │
                    └─────────┬─────────┘
                              │
                    ┌─────────▼─────────┐
                    │  LWW Check:       │
                    │  local vs cloud   │
                    │  updatedAt        │
                    └─────────┬─────────┘
                    local lebih baru?
                    │               │
                   YES              NO
                    │               │
              Kirim ke API    Skip, tandai
              Node.js/Express   SYNCED
                    │
              Berhasil? ──── NO ──→ retryCount++
                    │              kalau >= 3 → ERROR
                   YES
                    │
              Tandai SYNCED
              Hapus dari queue
```

---

## Last Write Wins (LWW)

Sebelum mengirim data ke cloud, SyncManager membandingkan field `updatedAt`:

- **Local lebih baru** → kirim ke cloud (local wins)
- **Cloud lebih baru** → skip, tandai SYNCED (cloud wins)
- **Cloud belum punya data** → kirim (create baru di cloud)

Contoh skenario: User A edit soal di HP offline jam 10:00, User B (online) edit soal yang sama jam 11:00. Saat User A online lagi, LWW memastikan versi jam 11:00 (User B) yang dipakai karena lebih baru.

---

## Retry dengan Exponential Backoff

Kalau pengiriman gagal (network error, server down, dll):

| Retry ke- | Delay    |
|-----------|----------|
| 1         | 1 detik  |
| 2         | 2 detik  |
| 3         | 4 detik  |
| > 3       | ERROR, notifikasi ke user |

Formula: `delay = 2^retryCount` detik, maksimum 30 detik.

---

## Cara pakai SyncManager dari modul lain

Setiap kali ada operasi CRUD di modul lain, panggil `enqueue` di SyncManager:

```dart
// Contoh di modul Seruni (submit soal baru)
final syncManager = ref.read(syncManagerProvider.notifier);

await syncManager.enqueue(
  entityType: 'Question',
  entityId: question.id,
  operation: SyncOperation.create,
  payload: jsonEncode(question.toJson()),  // perlu tambah toJson() di QuestionModel
  departmentId: question.departmentId,
);
```

```dart
// Contoh di modul Revaldi (simpan hasil kuis)
await syncManager.enqueue(
  entityType: 'QuizSession',
  entityId: session.id,
  operation: SyncOperation.create,
  payload: jsonEncode(session.toJson()),
);
```

---

## Cara pakai SyncIndicatorWidget

Pasang di bawah AppBar pada screen manapun:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Bank Soal')),
    body: Column(
      children: [
        const SyncIndicatorWidget(),  // ← tambahkan ini
        Expanded(child: /* isi screen */),
      ],
    ),
  );
}
```

---

## Cara connect dengan modul Auth (Jibril)

Setelah login berhasil di modul Jibril, panggil:

```dart
ref.read(syncManagerProvider.notifier).setAuthToken(jwtToken);
```

Setelah logout:

```dart
ref.read(syncManagerProvider.notifier).clearAuthToken();
```

---

## Jalankan unit test

```bash
flutter test test/features/sync/sync_manager_test.dart
```

Atau semua test:

```bash
flutter test
```

---

## Setup setelah clone (WAJIB)

1. Install dependency baru:
   ```bash
   flutter pub get
   ```

2. Generate Hive adapter:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   Ini akan meng-generate ulang `sync_queue_model.g.dart`.

3. Jalankan app:
   ```bash
   flutter run
   ```

---

## TODO (belum selesai — butuh koordinasi dengan anggota lain)

- [ ] `QuestionModel.toJson()` — butuh dari Seruni/Revaldi
- [ ] `QuizSession.toJson()` — butuh dari Revaldi  
- [ ] `setAuthToken()` dipanggil setelah login — butuh koordinasi Jibril
- [ ] URL backend `_baseUrl` di `api_service.dart` — ganti saat backend Jibril sudah deploy
- [ ] Test integrasi dengan backend nyata (saat ini mock/stub)
