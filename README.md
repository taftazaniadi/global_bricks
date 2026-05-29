# 🧱 Mason Brick — Feature Clean

**Feature Clean** adalah custom brick Mason yang membantu kamu membuat struktur **Clean Architecture** berbasis **Flutter + BLoC + GetIt** secara otomatis.  
Brick ini mendukung pembuatan **multi sub-feature**, lengkap dengan struktur folder `data`, `domain`, `presentation`, dan file injector.

---

## 🚀 Fitur

✅ Clean Architecture lengkap (data, domain, presentation)  
✅ Support **multi sub-feature** dengan input comma-separated  
✅ Otomatis membuat **injector per feature/sub-feature**  
✅ Dapat dipakai lokal atau global lintas proyek  
✅ Siap pakai untuk arsitektur Flutter + BLoC + GetIt

---

## 📂 Struktur Folder yang Dihasilkan

Contoh tanpa sub-feature:

```
lib/features/auth/
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
│   ├── page/
│   └── widget/
└── auth_injector.dart
```

Contoh dengan multi sub-feature (`login, register`):

```
lib/features/auth/
├── login/
│   ├── data/
│   ├── domain/
│   ├── presentation/
│   └── auth_login_injector.dart
└── register/
    ├── data/
    ├── domain/
    ├── presentation/
    └── auth_register_injector.dart
```

---

## ⚙️ Cara Instalasi

### 1️⃣ Tambahkan Mason ke proyek kamu
Jika belum punya Mason, install dulu secara global:
```bash
dart pub global activate mason_cli
```

### 2️⃣ Inisialisasi Mason di proyek kamu
```bash
mason init
```

### 3️⃣ Tambahkan Brick ke proyek kamu
Jika brick ini ada di dalam folder proyek:

```bash
mason add feature_clean --path ./bricks/feature_clean
```

Atau jika kamu gunakan dari GitHub repo:

```bash
mason add feature_clean --git-url https://github.com/taftazaniadi/global_bricks.git
```

### 4️⃣ Update brick list
```bash
mason get
```

---

## 🧩 Cara Menggunakan

### 🔹 Buat satu feature tanpa sub-feature:
```bash
mason make feature_clean
```
Lalu isi prompt:
```
What is the feature name : auth
Enter subfeatures (comma separated) : 
```

📁 Output:
```
lib/features/auth/
└── auth_injector.dart
```

---

### 🔹 Buat feature dengan beberapa sub-feature:
```bash
mason make feature_clean
```
Lalu isi prompt:
```
What is the feature name : auth
Enter subfeatures (comma separated) : login, register
```

📁 Output:
```
lib/features/auth/login/
└── auth_login_injector.dart

lib/features/auth/register/
└── auth_register_injector.dart
```

---

## 🧠 Catatan Penting

- Injector otomatis dibuat di level **feature** atau **sub-feature**, tergantung input.  
- Nama file injector mengikuti format:
  ```
  {feature_name}_{subfeature_name}_injector.dart
  ```
- Gunakan fungsi:
  ```dart
  void injectAuthLogin() {
    // Register dependency untuk auth/login
  }
  ```

---

## 💡 Tips Penggunaan

- Gunakan **GetIt** (`sl`) untuk dependency injection per feature.
- Kamu bisa memperluas `post_gen.dart` untuk auto-register ke `global_injector.dart`.
- Cocok digunakan bersama **BLoC**, **Dartz**, **Retrofit**, dan **Freezed**.

---

## 📜 Lisensi

MIT License © 2025 — Created by [M Taftazani Adi](https://github.com/taftazaniadi)

---

✨ Selamat membangun proyek Flutter kamu dengan arsitektur yang rapi dan scalable!
