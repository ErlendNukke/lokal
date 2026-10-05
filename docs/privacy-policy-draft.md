# Lokal — privaatsuspoliitika (DRAFT)

> **Staatus:** See dokument on tööversioon. See ei ole veel rakenduses ega veebis avaldatud. Enne avaldamist peab omanik kinnitama kõik `[KINNITAMATA: …]` väljad.

**Viimati uuendatud:** [KINNITAMATA: kuupäev]  
**Andmevastutaja:** [KINNITAMATA: juriidilise isiku või FIE nimi]  
**Kontakt (privaatsus):** [KINNITAMATA: privaatsus@domeen.ee]

---

## 1. Ülevaade

Lokal on Eesti kohalikku toitu ja talutoodet ühendav turuplats (veebirakendus ja mobiilirakendus). Käesolev poliitika kirjeldab, milliseid isikuandmeid rakendus kogub, miks seda tehakse ja kuidas andmeid hoitakse — vastavalt koodibaasis tegelikult rakendatud funktsioonidele.

## 2. Milliseid andmeid kogume

### 2.1 Konto ja profiil

Kui loote konto või logite sisse, kogume ja salvestame serveris (PostgreSQL andmebaas, hostitud [KINNITAMATA: teenusepakkuja, nt Neon]):

- **Nimi** — kuvamiseks profiilis ja tellimuste kontekstis tootjale/ostjale.
- **E-posti aadress** — sisselogimiseks ja konto tuvastamiseks (unikaalne).
- **Parool** — salvestatakse krüpteeritult (räsi); me ei salvesta parooli selges tekstis.
- **Roll** — ostja, tootja või mõlemad; määrab, milliseid funktsioone näete.
- **Asukoht (valikuline)** — laius- ja pikkuskraad ning linn, kui te need profiilis või registreerimisel esitate; kasutatakse lähedal asuvate toodete otsinguks ja kaardil kuvamiseks.
- **Talu / brändi nimi** (tootjatele) — avalik tootja profiil.
- **Autentimise teenusepakkuja** — kohalik konto või (demo/integratsiooni korral) Google sisselogimine.

### 2.2 Tootja ja tooted

Tootjad saavad lisada tooteid koos:

- toote nime, kirjelduse, hinnaga, koguse ja kategooriaga;
- **toote asukoha** koordinaatidega (kaardil);
- **tootefotod**, mis laetakse üles serveri kaudu ja salvestatakse objektsalvestusse (**Cloudflare R2**, S3-ühilduv API).

Fotod ja tooteinfo on teistele kasutajatele turuplatsi kaudu nähtavad.

### 2.3 Tellimused

Ostja tellimisel salvestame:

- tellija seose kontoga;
- toote, koguse ja hinna;
- täitmise viisi (järeletulek või kohaletoimetamine);
- **sõnumi tootjale** (kui sisestate);
- tellimuse oleku (ootel, kinnitatud jne).

Makse toimub rakenduse väliselt **kohapeal käepigistusel**; rakendus ei kogu ega töötle kaardiandmeid.

### 2.4 Arvustused

Pärast tellimust võite jätta tootjale **hinnangu (1–5)** ja **kommentaari**, mis seotakse tellimuse ja teie kontoga.

### 2.5 Asukoht seadmes

Veebi- ja mobiilirakendus võivad küsida **seadme asukohaluba**, et näidata lähedal olevaid tooteid ja kaarti. Kui luba ei anna või teenus on välja lülitatud, kasutatakse vaikeasukohta (Tallinn) või profiilis salvestatud koordinaate. Täpne GPS-jälgimine taustal ei toimu.

### 2.6 Tehnilised andmed seadmes

- **JWT (sisselogimismärk)** ja **profiili koopia** salvestatakse teie seadmes `shared_preferences` / brauseri salvestusruumi kaudu, et teid sisselogituna hoida.
- Veebirakendus kasutab **Firebase Hosting**u staatiliste failide jaoks; Firebase võib logida standardseid hostimise logisid (IP, päringud) vastavalt Google'i tingimustele.

### 2.7 Analüütika

Praeguses koodibaasis **ei ole** integreeritud kolmanda osapoole analüütikat (nt Google Analytics, Firebase Analytics). Kui see muutub, uuendatakse seda poliitikat.

## 3. Kuidas andmeid kasutame

- konto loomine, sisselogimine ja profiili haldamine;
- toodete otsing läheduse järgi;
- tellimuste edastamine ostja ja tootja vahel;
- arvustuste kuvamine;
- piltide üleslaadimine ja kuvamine.

Õiguslik alus EL-is: lepingu täitmine (teenuse osutamine) ja õigustatud huvi (turvalisus, pettuste vähendamine). [KINNITAMATA: õigusliku aluse täpsustus juristi poolt.]

## 4. Kellele andmeid edastame

Andmeid töödeldakse järgmiste teenusepakkujate infrastruktuuril:

| Teenus | Eesmärk |
|--------|---------|
| **Render** | Spring Boot API hostimine |
| **Neon** (või muu) | PostgreSQL andmebaas [KINNITAMATA] |
| **Cloudflare R2** | Tootefotode salvestus |
| **Firebase Hosting** | Veebirakenduse failid |
| **OpenStreetMap** (kaardikiht) | Kaardi kuvamine; päringud lähevad OSM tile serveritele |

Teised kasutajad näevad avalikku teavet (tooted, talu nimi, arvustused, tellimuse kontekstis osapoolte nimesid) vastavalt turuplatsi loogikale.

## 5. Säilitamine ja kustutamine

- Andmeid hoitakse seni, kuni konto on aktiivne või seadus nõuab säilitamist.
- Konto kustutamise protseduur: [KINNITAMATA: kas on self-service või e-posti taotlus].
- Tellimuste ja arvustuste säilitamine raamatupidamise/õigusnõuete tõttu: [KINNITAMATA].

## 6. Teie õigused

Vastavalt GDPRile on teil õigus pöörduda andmevastutaja poole **juurdepääsu, parandamise, kustutamise, töötlemise piiramise ja andmete ülekandmise** osas, kui see on kohaldatav.

Taotlus: [KINNITAMATA: privaatsus@domeen.ee]

Kaebuse esitamine: [KINNITAMATA: Andmekaitse Inspektsioon / teise järelevalveasutuse kontakt].

## 7. Turvalisus

- API kasutab HTTPS-i tootmises.
- Paroolid on räsitud; API päringud on autentitud JWT-ga.
- [KINNITAMATA: täiendavad organisatsioonilised ja tehnilised meetmed.]

## 8. Lapsed

Teenus ei ole suunatud alla [KINNITAMATA: vanusepiir, nt 16] aastastele ilma vanema nõusolekuta. [KINNITAMATA: omaniku otsus.]

## 9. Muudatused

Poliitika uuendamisel avaldatakse uus versioon [KINNITAMATA: kus — veeb, rakendus, e-post]. Oluliste muudatuste korral teavitame [KINNITAMATA: kuidas].

## 10. Kontakt

**Andmevastutaja:** [KINNITAMATA: nimi ja aadress]  
**E-post:** [KINNITAMATA: privaatsus@domeen.ee]

---

# Lokal — Privacy Policy (DRAFT) — English

> **Status:** Working draft. Not published in the app or on the web yet. The owner must confirm all `[UNCONFIRMED: …]` placeholders before publication.

**Last updated:** [UNCONFIRMED: date]  
**Data controller:** [UNCONFIRMED: legal entity or sole proprietor name]  
**Privacy contact:** [UNCONFIRMED: privacy@domain.ee]

---

## 1. Overview

Lokal is an Estonian local marketplace for food and farm products (web and mobile apps). This policy describes what personal data the app actually collects, why, and how it is stored — based on the implemented codebase.

## 2. What we collect

### 2.1 Account and profile

When you register or sign in, we store on the server (PostgreSQL, hosted on [UNCONFIRMED: e.g. Neon]):

- **Name** — shown on your profile and in order context.
- **Email** — for login and account identity (unique).
- **Password** — stored as a hash only; we never store plain-text passwords.
- **Role** — buyer, producer, or both; controls available features.
- **Location (optional)** — latitude, longitude, and city if you provide them; used for nearby product search and map display.
- **Farm / brand name** (producers) — public producer profile.
- **Auth provider** — local account or (where enabled) Google sign-in.

### 2.2 Producer listings

Producers can add products including name, description, price, quantity, category, **location coordinates**, and **photos** uploaded via the API and stored in **Cloudflare R2** (S3-compatible object storage). Listings are visible to other users.

### 2.3 Orders

When placing an order we store the buyer account link, product, quantity, price, fulfillment type (pickup/delivery), **message to producer** (if any), and order status. **Payment is offline at handover**; the app does not collect card data.

### 2.4 Reviews

After an order you may leave a **rating (1–5)** and **comment** tied to the order and your account.

### 2.5 Device location

The app may request **location permission** to show nearby products and the map. If denied, a default (Tallinn) or profile coordinates are used. We do not perform background GPS tracking.

### 2.6 On-device technical data

- **JWT** and a **profile copy** are stored via `shared_preferences` / browser storage to keep you signed in.
- The web app is served from **Firebase Hosting**; Firebase may log standard hosting metadata per Google’s terms.

### 2.7 Analytics

The current codebase has **no** third-party analytics (e.g. Google Analytics). If that changes, this policy will be updated.

## 3. How we use data

Account management, nearby search, order routing between buyers and producers, reviews, and image hosting — as described above.

Legal basis (EU): contract performance and legitimate interests (security). [UNCONFIRMED: legal review.]

## 4. Who processes data

| Service | Purpose |
|---------|---------|
| **Render** | API hosting |
| **Neon** (or other) | PostgreSQL [UNCONFIRMED] |
| **Cloudflare R2** | Product photos |
| **Firebase Hosting** | Web app static files |
| **OpenStreetMap** tiles | Map display |

Other users see public marketplace data as designed (products, farm names, reviews, names in order context).

## 5. Retention and deletion

Data is kept while the account is active or as required by law. Account deletion: [UNCONFIRMED: self-service or email process]. Order/review retention: [UNCONFIRMED].

## 6. Your rights

Under GDPR you may request access, rectification, erasure, restriction, and portability where applicable. Contact: [UNCONFIRMED: privacy@domain.ee]. Supervisory authority: [UNCONFIRMED: Estonian DPA / other].

## 7. Security

HTTPS in production; hashed passwords; JWT-authenticated API. [UNCONFIRMED: additional measures.]

## 8. Children

Not directed at children under [UNCONFIRMED: age] without parental consent. [UNCONFIRMED.]

## 9. Changes

Updates will be published at [UNCONFIRMED: location]. Material changes: [UNCONFIRMED: notification method].

## 10. Contact

**Data controller:** [UNCONFIRMED: name and address]  
**Email:** [UNCONFIRMED: privacy@domain.ee]
