# 🧱 Mason Brick — Features

**Features** adalah template yang membantu kamu membuat struktur proyek `Flutter` dengan cara yang lebih rapi dan teratur.

Repository ini bukan aplikasi `Flutter`, melainkan paket `Mason` yang berisi `brick`. `Brick` ini digunakan di proyek `Flutter` lain untuk membuat struktur fitur secara otomatis, sehingga kamu tidak perlu menulis struktur dasar dari nol setiap kali membuat fitur baru.

---

## ✨ Apa yang bisa dilakukan brick ini?

`Brick` ini akan membantu kamu membuat:

- folder untuk fitur seperti `data`, `domain`, dan `presentation`
- file awal untuk `repository`, `use case`, `entity`, `bloc`, `page`, dan `widget`
- file injector otomatis untuk kebutuhan `dependency injection`
- struktur feature sederhana, baik untuk satu fitur maupun beberapa sub-fitur

---

## 📂 Contoh hasil yang dibuat

### Jika hanya satu fitur

Berikut contoh struktur yang akan dibuat saat kamu membuat fitur `auth` tanpa sub-fitur:

```text
lib/
└── features/
    └── auth/
        ├── data/
        │   ├── datasources/
        │   ├── mappers/
        │   ├── models/
        │   └── repositories/
        ├── domain/
        │   ├── entities/
        │   ├── repositories/
        │   └── usecases/
        ├── presentation/
        │   ├── bloc/
        │   ├── pages/
        │   └── widgets/
        └── auth_injector.dart
```

Penjelasan singkat:

- `data/`: tempat file untuk sumber data, mapper, model, dan repository implementasi
- `domain/`: tempat entity, repository interface, dan use case
- `presentation/`: tempat file bloc, halaman, dan widget UI
- `auth_injector.dart`: file untuk mendaftarkan dependency fitur ini

### Jika ada beberapa sub-fitur

Berikut contoh ketika kamu membuat fitur `auth` dengan sub-fitur `login` dan `register`:

```text
lib/
└── features/
    └── auth/
        ├── login/
        │   ├── data/
        │   ├── domain/
        │   ├── presentation/
        │   └── login_injector.dart
        ├── register/
        │   ├── data/
        │   ├── domain/
        │   ├── presentation/
        │   └── register_injector.dart
        └── auth_injector.dart
```

Penjelasan singkat:

- tiap sub-fitur akan punya struktur folder sendiri
- setiap sub-fitur juga akan mendapatkan file injector tersendiri
- file `auth_injector.dart` di bagian atas berfungsi sebagai injector utama yang menghubungkan sub-fitur

---

## 🤝 Kapan brick ini cocok dipakai?

`Brick` ini cocok digunakan jika kamu:

- sedang membuat proyek `Flutter` dengan banyak fitur
- ingin struktur folder yang rapi sejak awal
- ingin mempercepat pembuatan fitur berdasarkan arsitektur `Clean Architecture`
- ingin mengurangi pekerjaan menulis boilerplate berulang-ulang

Contoh sederhana: saat kamu membuat fitur login, kamu bisa langsung membuat struktur `auth` beserta file-file awalnya dengan satu perintah.

---

## ⚙️ Cara memasang

### 1. Install Mason

```bash
dart pub global activate mason_cli
```

### 2. Siapkan Mason di proyek kamu

```bash
mason init
```

### 3. Tambahkan brick ini

Jika brick ada di folder lokal, jalankan dari direktori repository brick ini:

```bash
mason add features --path .
```

Jika ingin mengambil dari GitHub:

```bash
mason add features --git-url https://github.com/taftazaniadi/global_bricks.git
```

### 4. Ambil list brick

```bash
mason get
```

---

## 🧩 Cara pakai

Jalankan perintah berikut:

```bash
mason make features
```

Lalu isi input yang diminta, misalnya:

```text
Target directory path : lib/features
Feature name (e.g., auth or checkout/payment) : auth
Subfeatures (comma-separated, optional) : login, register
```

---

## 📝 Catatan penting

- File yang dibuat awalnya masih berupa template. Kamu masih perlu mengisi logika sesuai kebutuhan proyek.
- Injector akan dibuat otomatis supaya memudahkan pengaturan dependency.
- Brick ini cocok untuk proyek Flutter yang ingin struktur kodenya lebih rapi sejak awal.

---

## 📜 Lisensi

MIT License © 2025

Dibuat oleh [M Taftazani Adi](https://github.com/taftazaniadi)

