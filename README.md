# Panduan Konfigurasi Server

Dokumen ini menjelaskan langkah-langkah untuk mengkonfigurasi server Linux dengan menggunakan skrip otomatis. Skrip ini mencakup berbagai fungsi untuk memudahkan proses konfigurasi.

## Fungsi-fungsi Utama

### 1. Fungsi `get_distro`
Fungsi ini mendeteksi distribusi Linux yang digunakan server dengan membaca file seperti `/etc/os-release` atau `/etc/lsb-release`.  
**Output:** Nama distribusi Linux (contoh: `ubuntu`, `almalinux`, `arch`, dll.).

### 2. Fungsi `get_plugins`
Fungsi ini menentukan daftar plugin Zsh yang akan digunakan berdasarkan distribusi Linux.  
**Plugin dasar:** `git`, `zsh-syntax-highlighting`, dll.  
**Plugin spesifik distribusi:** `yum`, `pacman`, `zypper`, dll.

### 3. Fungsi `create_zshrc`
Fungsi ini membuat file `.zshrc` di direktori home user dan root. Konfigurasi yang disertakan adalah:
- Menggunakan tema **Powerlevel10k**.
- Menambahkan plugin **Oh My Zsh**.
- Mengaktifkan fitur seperti auto-correction dan completion dots.
- Mengimpor alias dari file `.zsh_aliases`.

### 4. Fungsi `create_aliases`
Fungsi ini membuat file `.zsh_aliases` berisi berbagai alias untuk mempercepat perintah, seperti:
- **Systemd:** `sc-start`, `sc-stop`, dll.
- **File management:** `ll`, `..`, dll.
- **Git:** `gs`, `ga`, `gp`, dll.

### 5. Fungsi `install_packages`
Fungsi ini menginstal paket yang diperlukan seperti Zsh, Git, dan curl berdasarkan manajer paket distribusi Linux:
- `apt` untuk Debian/Ubuntu.
- `yum`/`dnf` untuk RHEL/CentOS/AlmaLinux.
- `zypper` untuk openSUSE.
- `pacman` untuk Arch/Manjaro.

### 6. Fungsi `configure_firewall`
Fungsi ini menonaktifkan firewall default distribusi seperti:
- **UFW** untuk Debian/Ubuntu.
- **firewalld** untuk RHEL/AlmaLinux/Fedora.

## Konfigurasi User dan SSH

### Input Pengguna:
- **Hostname**
- **Username, password, dan password root**
- **Kunci SSH publik** (dapat berupa banyak kunci, dipisah koma)

### Proses:
1. Membuat user baru (jika belum ada) atau memperbarui password user yang sudah ada.
2. Menyimpan kunci SSH ke `~/.ssh/authorized_keys` untuk user dan root.
3. Mengamankan SSH:
   - Menonaktifkan login root.
   - Mengaktifkan `PubkeyAuthentication`.
   - Menonaktifkan `PasswordAuthentication`.

## Instalasi Oh My Zsh
- Menginstal **Oh My Zsh** untuk root dan user.
- Menambahkan plugin tambahan seperti:
  - `zsh-syntax-highlighting`
  - `zsh-autosuggestions`
- Menginstal tema **Powerlevel10k**.
- Menentukan Zsh sebagai shell default untuk root dan user.

## Konfigurasi Hostname
Mengatur nama host server menggunakan perintah `hostnamectl`.

## Restart SSH
Memastikan SSH (atau SSHD) direstart untuk menerapkan perubahan konfigurasi.

## Output Akhir
Menampilkan pesan sukses setelah konfigurasi selesai, dengan catatan agar user logout dan login ulang untuk mulai menggunakan shell baru.

## Manfaat Script
- **Efisiensi:** Otomatisasi tugas konfigurasi server dasar.
- **Keamanan:** Memastikan SSH menggunakan kunci publik.
- **Produktivitas:** Menambahkan alias dan plugin Zsh yang meningkatkan pengalaman terminal.