# Instagram Video to Text: Batch Reel & Video Transcriber (Whisper)

[English](README.en.md) | **Türkçe**

Instagram videolarını ve Reels'leri **yazıya / metne çeviren**, birden fazla linki tek seferde işleyebilen, ücretsiz ve bilgisayarında çalışan küçük bir Mac/Terminal araç seti. Varsayılan dil Türkçedir.

`links.txt` dosyasına linkleri yazarsın, script'i çalıştırırsın; video veya ses indirilir, [OpenAI Whisper](https://github.com/openai/whisper) ile metne çevrilir ve sonuçlar tek bir `all_transcripts.txt` dosyasında toplanır. İstersen altyazı dosyası (`.srt`, `.vtt`) olarak da alabilirsin.

> **Not:** Bu proje, Instagram, Meta, OpenAI veya yt-dlp ile bağlantılı değildir. Ayrıntılar için [Yasal Uyarı](#yasal-uyarı-ve-sorumluluk) bölümüne bak.

---

## İçindekiler

- [Ne işe yarar?](#ne-işe-yarar)
- [Hangi script ne yapar?](#hangi-script-ne-yapar)
- [Gereksinimler](#gereksinimler)
- [Kurulum](#kurulum)
- [Kullanım](#kullanım)
- [Ayarlar](#ayarlar)
- [Çıktı formatları](#çıktı-formatları)
- [Çıktı yapısı](#çıktı-yapısı)
- [Sorun giderme](#sorun-giderme)
- [Sık sorulan sorular](#sık-sorulan-sorular)
- [İsteğe bağlı: Claude ile kullanım](#isteğe-bağlı-claude-ile-kullanım)
- [Yasal uyarı ve sorumluluk](#yasal-uyarı-ve-sorumluluk)
- [Lisans](#lisans)

---

## Ne işe yarar?

- Birden fazla Instagram linkini (Reels ve video gönderileri) sırayla işler.
- Konuşmaları Türkçe (veya istersen İngilizce vb.) metne çevirir. Whisper 99 dili destekler.
- Çıktıyı düz metin (`txt`), altyazı (`srt`, `vtt`), `tsv` veya `json` olarak verebilir.
- Çıkan metinleri her video için ayrı dosya olarak ve ayrıca tek bir `all_transcripts.txt` dosyasında verir.
- İndirilemeyen bir link olursa durmaz, o linki atlar ve sonuç dosyasına not düşer.
- Bütün işlem **kendi bilgisayarında** çalışır. Whisper modeli yerelde çalışır; ses ve metin verin üçüncü bir transkripsiyon servisine gönderilmez.

## Hangi script ne yapar?

| Script | Videoyu indirir | Metne çevirir | Dosyaları saklar |
|---|---|---|---|
| `transcribe.sh` | Sadece ses (mp3) | Evet | Ses dosyası varsayılan olarak silinir (ayarlanabilir) |
| `transcribe_video.sh` | Video (mp4) | Evet | Video kalıcı olarak saklanır |
| `download_video.sh` | Video (mp4) | Hayır | Video kalıcı olarak saklanır |
| `setup.sh` | - | - | Gerekli araçları kurar |

Hangisini seçeceğini bilmiyorsan: sadece metin istiyorsan `transcribe.sh`, hem video hem metin istiyorsan `transcribe_video.sh`, sadece video istiyorsan `download_video.sh`.

## Gereksinimler

- **macOS** (Mac için hazırlandı; Linux'ta da benzer şekilde çalışması beklenir ama test edilmedi)
- [Homebrew](https://brew.sh) paket yöneticisi
- Şu araçlar (kurulum bölümündeki komutla otomatik kurulur):
  - [`yt-dlp`](https://github.com/yt-dlp/yt-dlp): videoyu indirir
  - [`ffmpeg`](https://ffmpeg.org): sesi/videoyu işler
  - [`openai-whisper`](https://github.com/openai/whisper): konuşmayı metne çevirir
- Instagram'a giriş yapılmış bir tarayıcı (Chrome, Safari veya Firefox). Instagram çoğu içeriği giriş yapılmamış isteklere kapattığı için script, giriş çerezini tarayıcından okur.
- Yeterli boş disk alanı. Whisper modeli ilk çalıştırmada indirilir (yaklaşık: `small` ≈ 0,5 GB, `medium` ≈ 1,5 GB), videolar da yer kaplar.

## Kurulum

### 1. Projeyi indir

Git kullanıyorsan:

```bash
git clone https://github.com/ozdemirveysel81/instagram-video-to-text.git
cd instagram-video-to-text
```

Git kullanmıyorsan GitHub sayfasında yeşil **Code** düğmesine bas, **Download ZIP** seç ve ZIP'i bir klasöre çıkar.

### 2. Gerekli araçları kur

Homebrew yüklü değilse önce [brew.sh](https://brew.sh) adresindeki tek satırlık komutla kur. Sonra proje klasöründe:

```bash
bash setup.sh
```

Bu komut şunu çalıştırır:

```bash
brew install yt-dlp ffmpeg openai-whisper
```

İstersen bu komutu doğrudan Terminal'e de yapıştırabilirsin.

### 3. Linklerini hazırla

`links.example.txt` dosyasını `links.txt` olarak kopyala ve içini kendi linklerinle doldur:

```bash
cp links.example.txt links.txt
open -e links.txt
```

Her satıra bir link yaz. `#` ile başlayan satırlar yok sayılır.

```
https://www.instagram.com/p/XXXXXXXXXXX/
https://www.instagram.com/reel/YYYYYYYYYYY/
# Bu satır yok sayılır
```

## Kullanım

Terminal'de proje klasörüne gidip istediğin script'i çalıştır:

```bash
cd ~/Desktop/instagram-video-to-text

# Sadece metin istiyorsan (ses indirilir, metne çevrilir):
bash transcribe.sh

# Hem video hem metin istiyorsan:
bash transcribe_video.sh

# Sadece video indirmek istiyorsan:
bash download_video.sh
```

> `bash script_adi.sh` şeklinde çalıştırmak "izin verilmedi (permission denied)" hatasını önler. Script'i doğrudan `./transcribe.sh` ile çalıştırmak istersen önce `chmod +x *.sh` komutunu bir kez çalıştırman gerekir.

**İlk çalıştırma:** Whisper, seçtiğin modeli ilk kullanımda indirir. Bu birkaç dakika sürebilir ve ekranda bir süre hiçbir şey olmuyormuş gibi görünebilir. Bu normaldir.

**Çok sayıda link:** Instagram, kısa sürede çok sayıda ardışık istekte erişimi geçici olarak sınırlayabilir. Uzun listeleri birkaç parçaya bölmen daha güvenlidir.

## Ayarlar

Her script'in en üstündeki `SETTINGS` bölümünü bir metin düzenleyiciyle değiştirebilirsin.

| Ayar | Değerler | Açıklama |
|---|---|---|
| `BROWSER` | `chrome`, `safari`, `firefox` | Instagram'a giriş yaptığın tarayıcı |
| `MODEL` | `tiny`, `base`, `small`, `medium` | Büyük model daha doğru ama daha yavaştır. Türkçe için `small` dengeli, `medium` daha doğrudur |
| `SPOKEN_LANGUAGE` | `Turkish`, `English` vb. | Videodaki konuşma dili |
| `FORMATS` | `txt`, `srt`, `vtt`, `tsv`, `json` | Çıktı formatları. Boşlukla ayırarak birden fazla yazabilirsin |
| `DELETE_AUDIO` | `yes`, `no` | Sadece `transcribe.sh` içinde: işlem sonunda mp3 dosyalarını silsin mi |

Örnek: ses dosyalarını saklamak için `transcribe.sh` içinde şu satırı değiştir:

```bash
DELETE_AUDIO="no"
```

## Çıktı formatları

`FORMATS` ayarıyla hangi dosyaların kalacağını seçersin:

| Format | Ne içerir | Ne zaman kullanılır |
|---|---|---|
| `txt` | Düz metin | Okumak, kopyalamak, özetlemek için |
| `srt` | Zaman damgalı altyazı | Videoya altyazı eklemek, kurgu programlarında kullanmak için |
| `vtt` | Zaman damgalı altyazı (web) | Web video oynatıcılarında altyazı olarak |
| `tsv` | Tablo (başlangıç, bitiş, metin) | Excel/Numbers'ta açmak için |
| `json` | Ayrıntılı veri | Kendi kodunda işlemek için |

Örnekler (script'in en üstündeki ayarda):

```bash
FORMATS="txt"          # sadece düz metin (varsayılan)
FORMATS="srt"          # sadece altyazı
FORMATS="txt srt vtt"  # üçü birden
```

Hangi format seçilirse seçilsin, `transcripts/all_transcripts.txt` her zaman oluşturulur; tüm videoların düz metni linkleriyle birlikte bu dosyada toplanır.

## Çıktı yapısı

Çalıştırdıktan sonra proje klasöründe şunlar oluşur:

```
instagram-video-to-text/
├── videos/                # mp4 dosyaları (transcribe_video.sh ve download_video.sh)
├── audio/                 # mp3 dosyaları (transcribe.sh, DELETE_AUDIO="no" ise kalır)
└── transcripts/
    ├── 01_XXXXXXXXXXX_00001.txt   # her video için ayrı metin (seçtiğin formatlarda)
    ├── 01_XXXXXXXXXXX_00001.srt
    ├── 02_YYYYYYYYYYY_00001.txt
    └── all_transcripts.txt        # tüm metinler tek dosyada, linkleriyle birlikte
```

Dosya adları sıra numarası ve gönderi kodundan oluşur. Birden fazla videosu olan (carousel) gönderilerde her video ayrı bir dosya olur.

## Sorun giderme

**`'yt-dlp' is not installed` / `command not found`**  
Kurulumu yap: `bash setup.sh`


**Instagram "login required", "empty media response" veya benzeri bir hata veriyor**  
- Seçtiğin tarayıcıda Instagram'a giriş yaptığından emin ol.
- `BROWSER` ayarının doğru tarayıcıyı gösterdiğini kontrol et.
- yt-dlp'yi güncelle: `brew upgrade yt-dlp`. Instagram sık sık değişir ve eski sürümler çalışmayabilir.
- Çok sayıda linki arka arkaya denediysen bir süre bekle ve listeyi küçült.

**`invalid format`**  
`FORMATS` ayarında sadece şunları kullanabilirsin: `txt srt vtt tsv json`. Birden fazlasını boşlukla ayır.

**Chrome ile Mac "anahtar zinciri erişimi" soruyor**  
Tarayıcı çerezlerini okumak için macOS sana bir izin penceresi gösterebilir. Bu istek senin kendi bilgisayarındaki script'ten geliyorsa izin verebilirsin.

**Safari ile izin hatası**
Sistem Ayarları > Gizlilik ve Güvenlik > Tam Disk Erişimi bölümünden Terminal'e izin ver, sonra Terminal'i kapatıp yeniden aç.

**`No video formats found`**
Gönderi sadece fotoğraf içeriyor olabilir; sesi veya videosu olmayan gönderiler indirilemez.

**Whisper çok yavaş**
`MODEL` değerini `base` veya `tiny` yap. Doğruluk düşer, hız artar.

**Türkçe metinde çok hata var**
`MODEL="medium"` dene. Arka plan müziği yüksek olan videolarda hata oranı artabilir.

**`permission denied`**
`bash transcribe.sh` şeklinde çalıştır ya da `chmod +x *.sh` komutunu bir kez çalıştır.

## Sık sorulan sorular

**Verilerim bir yere gönderiliyor mu?**
Whisper bu kurulumda bilgisayarında yerel olarak çalışır; ses ve metin üçüncü bir servise gönderilmez. Videoyu indirmek için elbette Instagram'a bağlanılır.

**Hesabımın şifresini kullanıyor mu?**
Hayır. Script şifre istemez. Sadece tarayıcında zaten açık olan oturumun çerezlerini yt-dlp'ye verir.

**Altyazı dosyası (SRT/VTT) alabilir miyim?**
Evet. Script'in en üstündeki `FORMATS` ayarına `srt` veya `vtt` yaz. Ayrıntılar için [Çıktı formatları](#çıktı-formatları) bölümüne bak.

**Windows'ta çalışır mı?**
Bu script'ler bash ve Homebrew için yazıldı. Windows'ta WSL ile çalışabilir ama test edilmedi.

**Metnin doğruluğu nasıl?**
Whisper güçlüdür ama hata yapabilir. Özellikle özel isimlerde, kötü ses kalitesinde ve müzik üzerine konuşmalarda çıkan metni gözden geçirmeni öneririz.

**Aynı linkleri tekrar çalıştırırsam ne olur?**
Dosya adlarında sıra numarası olduğu için üzerine yazılmaz, ayrı bir kopya oluşabilir. Aynı videoyu iki kez işlememek için `links.txt` içine sadece yeni linkleri yaz.

## İsteğe bağlı: Claude ile kullanım

Script'leri Terminal'den çalıştırmak Claude'u hiç kullanmaz. İstersen Claude Desktop uygulamasının **Code** sekmesinde bu klasörü seçip "transcribe_video.sh dosyasını çalıştır" diyebilirsin. Bu durumda Claude'un kullanımı abonelik limitlerine sayılır. Rutin kullanım için doğrudan Terminal yeterlidir.

## Yasal uyarı ve sorumluluk

- Bu araç **yalnızca kişisel kullanım ve öğrenme** amacıyla paylaşılmıştır.
- Videolar ve içindeki konuşmalar, içerik sahibine aittir ve telif hakkıyla korunuyor olabilir. Sadece **kendi içeriklerin veya kullanım hakkın olan içerikler** için kullanmanı öneririz.
- Instagram'ın [Kullanım Koşulları](https://help.instagram.com/581066165581870) içerik indirmeyi veya otomatik erişimi kısıtlayabilir. Bu koşullara uymak senin sorumluluğundadır.
- Başkalarının içeriğini izinsiz indirmek, saklamak, yeniden yayınlamak veya kişisel verileri işlemek hukuki sorun doğurabilir. Bulunduğun ülkenin mevzuatına (örneğin KVKK, telif hakkı yasaları) dikkat et.
- Bu proje Instagram, Meta, OpenAI veya yt-dlp ile resmi bir bağlantıya sahip değildir. Instagram'ın yapısı değişirse araç çalışmayı bırakabilir.
- Yazılım "olduğu gibi" sunulur ve herhangi bir garanti verilmez. Kullanımdan doğan sorunlardan geliştirici sorumlu tutulamaz.

## Lisans

[MIT Lisansı](LICENSE) ile paylaşılmıştır.

## Teşekkürler

Bu proje şu açık kaynak projelere dayanır: [yt-dlp](https://github.com/yt-dlp/yt-dlp), [FFmpeg](https://ffmpeg.org) ve [OpenAI Whisper](https://github.com/openai/whisper).
