# ISM Digital Museum · SWE334

**СЭЗИС-ийн Мэдээллийн системийн менежментийн тэнхимийн интерактив дижитал музей** — React + JavaScript + Vite + Tailwind CSS + Supabase + Vercel.

## Гол боломжууд

- Багш нарын 10 дэлгэрэнгүй профайл, тэнхимийн хамт олны зураг
- Тэнхимийн 6 арга хэмжээ, постер, цомог, ангилал болон хайлт
- Хэрэглэгчийн өгсөн 1964–2005 оны түүхээр эхэлсэн **ISM Time Machine** интерактив timeline
- 21st.dev-ийн хэрэглэгчийн өгсөн Circular Gallery-г JavaScript JSX болгон өөрчилсөн 3D зурагт цомог
- Оюутны үзмэрийг нэр, он, ангилал, технологиор хайх, шүүх
- Supabase Auth бүртгэл, нэвтрэлт, гаралт
- Бүтээл нэмэх, засах, устгах болон зураг Supabase Storage-д оруулах (5MB хүртэл)
- Админ бүтээлийг батлах, буцаах; багш, арга хэмжээ CRUD
- Хуудас бүр responsive, гар утасны цэс, `prefers-reduced-motion` тохиргоо

## Хөгжүүлэлтийн орчинд ажиллуулах

Node.js 20.19+ буюу 22+ суулгасан байна.

```bash
npm install
cp .env.example .env
npm run dev
```

Windows PowerShell хэрэглэвэл `Copy-Item .env.example .env` гэж хуулна.

Браузер дээр Vite-ийн заасан хаягийг (`http://localhost:5173` ихэвчлэн) нээнэ. Хэрэв `.env` үүсгээгүй бол нийтийн жишээ өгөгдлөөр харагдах **demo mode** ажиллана. Энэ горимд бүртгэл, CRUD ажиллахгүй — Supabase хэрэгтэй.

## Supabase тохиргоо — ШИНЭ ТӨСӨЛ

> **ЧУХАЛ:** Энэ музейг хэрэглэгчийн ургамлын дэлгүүрийн Supabase төслөөс тусад нь үүсгэнэ. Өмнөх `public.profiles` хүснэгттэй байгаа төсөл дээр `schema.sql` ажиллуулахыг хориглоно.

1. [Supabase](https://supabase.com/dashboard) дээр шинэ төсөл үүсгэ. `Project Settings → API Keys` эсвэл `Connect` хэсгээс **Project URL** ба public `publishable` key-г ав.
2. `SQL Editor → New query` нээж `supabase/schema.sql` файлын агуулгыг ажиллуул. Дараа нь `supabase/seed.sql`-ийг ажиллуул.
3. `.env` дотор:

```env
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=<public-publishable-key>
```

4. `Authentication → URL Configuration` хэсэгт локал болон Vercel production URL-аа тохируул. Имэйлээр баталгаажуулалт шаардах бол `Authentication → Providers → Email` тохиргоог шалга.
5. Өөрийн хэрэглэгчийг сайтаар бүртгэсний **дараа**, итгэмжлэгдсэн SQL Editor-д зөвхөн өөрийн и-мэйлийг оруулж админ эрх олго:

```sql
insert into public.museum_admins(user_id)
select id from auth.users where email = 'YOUR_EMAIL@example.com'
on conflict do nothing;
```

Энэ SQL-ийг frontend код, GitHub Action, browser console-оос ажиллуулахгүй. Админ эрхийг хэрэглэгч өөрөө авах боломжгүй.

## Supabase өгөгдлийн сан

Дараах хүснэгтүүд бүгд RLS хамгаалалттай:

| Хүснэгт | Primary key | Foreign key | Зориулалт |
|---|---|---|---|
| `profiles` | `id` (uuid) | `id → auth.users.id` | Хэрэглэгчийн нэр, зураг |
| `museum_admins` | `user_id` | `user_id → auth.users.id` | Админы эрхийн trusted хүснэгт |
| `exhibits` | `id` | `creator_id → auth.users.id` | Оюутны бүтээл; status: draft, pending, published |
| `teachers` | `id` | — | Багшийн профайл |
| `events` | `id` | — | Арга хэмжээ |
| `event_photos` | `id` | `event_id → events.id` | Арга хэмжээний зургийн цомог |
| `exhibition_categories` | `id` | — | Үзэсгэлэнгийн ангиллууд |
| `milestones` | `id` | — | Түүхэн онцлох үе шат |

ERD-г `docs/ERD.md`-д оруулсан.

### RLS зан төлөв

- **Зочин**: зөвхөн `published` бүтээлийг үзнэ, багш/арга хэмжээг уншина.
- **Оюутан**: зөвхөн өөрийн үзмэрийг нэмэх/засах/устгах; шинээр оруулах үед `pending` эсвэл `draft` төлөвтэй. `published` төлөвт шууд шилжүүлэх боломжгүй.
- **Админ**: `museum_admins` хүснэгтэд байгаа хэрэглэгч; үзмэр батлах/буцаах, багш/арга хэмжээ удирдах.
- **Storage**: `museum-assets` нийтийн унших bucket, зөвхөн өөрийн UUID хавтас руу authenticated оюутан зураг оруулна. Админ `admin/...` хавтсанд зураг оруулна. `service_role`, secret key frontend-д **оруулахгүй**.

## Vercel руу байршуулалт

1. [Vercel](https://vercel.com/new) → **Add New Project** → **Import** → `B23FA1882/SWE334_ISMmuseum` repository.
2. Framework preset **Vite**; Build command `npm run build`; Output directory `dist`.
3. Environment Variables хэсэгт `VITE_SUPABASE_URL` ба `VITE_SUPABASE_PUBLISHABLE_KEY` (public key) нэм.
4. Deploy. Дараа нь шинэ Vercel URL-ыг Supabase-ийн Auth URL Configuration хэсэгт оруул.

`vercel.json` нь React Router-ийн nested path refresh хийхэд `/index.html` руу чиглүүлэх SPA rewrite-тэй.

## Бүтэц

```text
SWE_ISMmuseum/
├── public/images/                   # Хэрэглэгчээс өгсөн 17 зураг, WEBP болгон шахсан
├── src/
│   ├── components/ui/circular-gallery.jsx  # 3D gallery
│   ├── lib/supabase.js               # Supabase public client
│   ├── App.jsx                       # Routing, components, CRUD, Auth
│   ├── data.js                       # Demo контент
│   ├── main.jsx                      # React entry
│   └── styles.css                    # UI, responsive design
├── supabase/schema.sql              # Tables, grants, RLS, Storage
├── supabase/seed.sql                # Хэрэглэгчийн өгсөн багш, арга хэмжээ, түүх
├── docs/ERD.md
├── docs/TESTING.md
├── .env.example
├── vercel.json
└── package.json
```

## Өгөгдлийн тухай

Багш, арга хэмжээний мэдээлэл ба зураг нь хэрэглэгчийн өгсөн эх сурвалжаас авсан. Оюутны бодит үзмэр/зохиогчдын нэр өгөөгүй учраас тэдгээрийг зохиомлоор үүсгээгүй; зөвшөөрөлтэй оюутан бүртгүүлээд нэмнэ.

Эх сурвалжид “2025 оны Бүтээлийн Уралдаан” постын гарчиг `2025.04.25`, постерын үйл ажиллагааны огноо `2025.04.24` байсан тул `2025-04-24`-ийг сонгосон. “2025 оны Password Day” текстэд `2025.01.05` ба 5 сарын 1-ний мэдээлэл хамт байсан тул зургийн арга хэмжээний тайлбарын `2025-05-01`-ийг ашигласан. Баталгаажуулах шаардлагатай.

## Хөгжүүлэлтийн статус

- Код болон schema бэлтгэгдсэн, **шинэ Supabase project-д ажиллуулаагүй**.
- Эцсийн production URL нь таны Vercel төслийг импортлон амжилттай deploy хийсний дараа үүснэ.
- `npm install`/`npm run build`-ийг dependency internet хязгаарлагдсан энэ орчинд бүрэн ажиллуулан баталгаажуулаагүй.

Лиценз: сургалтын зорилгоор. Зургийн эрхийг агуулга эзэмшигчээс тодруулна уу.
