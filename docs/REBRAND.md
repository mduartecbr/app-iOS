# Plano de rebrand — MacMagazine → Esporte para Todos

Documento de planejamento. Lista todas as mudanças necessárias pra transformar o fork do `MacMagazine/app-iOS` no app do Esporte para Todos. **Nada foi executado ainda** — esse doc é pra revisão antes de aplicar.

Última atualização: 2026-05-02.

---

## 1. Decisões já travadas

| Item | Valor |
|---|---|
| Nome interno (código, classes, scheme, packages) | `EsporteParaTodos` |
| Display name (home screen iPhone) | `Esporte para Todos` |
| Bundle identifier raiz | `com.esporteparatodos.app` |
| Domínio do feed | `esporteparatodos.com` (consumido via `/feed/` RSS) |
| Canal YouTube | `UCXBnKQ_Yq92QXQFAFnw_e-w` (Programa Fôlego) |
| Escopo v1 | Paridade quase completa, em ondas |
| Plataforma | iOS only (Android depois) |

## 2. Estratégia: rebrand híbrido

Rebrand "profundo total" (renomear `.xcodeproj`, diretórios container, todas classes) tem risco alto de quebrar build (schemes, SPM resolution, derived data). Rebrand "raso" (só strings de UI) deixa o código com cara de MacMagazine pra sempre.

**Adotando híbrido:**

- **Renomear**: `.xcodeproj`, scheme principal, os 2 packages SPM com "MacMagazine" no nome, bundle IDs, display name, copyright, asset catalogs, strings de UI
- **Manter como está**: diretórios container (`./MacMagazine/`, `./MacMagazine/MacMagazine/`) — vão virar `./EsporteParaTodos/EsporteParaTodos/` numa segunda passada se valer a pena, mas não é gating pro v1
- **Manter**: nomes de packages SPM já genéricos (`FeedLibrary`, `NewsLibrary`, `PodcastLibrary`, etc.)

Justificativa: maximiza limpeza visível pro usuário e contribuidor, minimiza risco de quebrar build.

## 3. Inventário de mudanças

### 3.1 Bundle identifiers (`MacMagazine.xcodeproj/project.pbxproj`)

| De | Para |
|---|---|
| `com.brit.macmagazine` | `com.esporteparatodos.app` |
| `com.brit.macmagazine.MacMagazinePushNotificationServiceExtension` | `com.esporteparatodos.app.NotificationService` |
| `com.brit.macmagazine.MacMagazineWidgetExtension` | `com.esporteparatodos.app.widget` |
| `com.brit.macmagazine.watchkitapp` | `com.esporteparatodos.app.watchkitapp` |
| `com.brit.macmagazine.watchkitapp.WidgetWatch` | `com.esporteparatodos.app.watchkitapp.WidgetWatch` |

### 3.2 App groups & entitlements

| De | Para |
|---|---|
| `group.com.brit.macmagazine.onesignal.push` (Info.plist) | `group.com.esporteparatodos.app.onesignal.push` |
| Demais entries em `*.entitlements` (4 arquivos) | Substituir prefixo `com.brit.macmagazine` → `com.esporteparatodos.app` |

### 3.3 Info.plist

- **Adicionar** `CFBundleDisplayName = Esporte para Todos`
- Manter `CFBundleName` apontando pra `$(PRODUCT_NAME)` (= `EsporteParaTodos` após rename do scheme)
- **Strings em PT-BR já existentes** (UIApplicationShortcutItems): mantêm sentido, sem mudança

### 3.4 Domínio do feed (`Definitions/URLs.swift` + `FeedEndpoint.swift`)

| De | Para |
|---|---|
| `macmagazine.com.br` | `esporteparatodos.com` |
| `https://macmagazine.com.br/loginpatrao` | **REMOVER** (assinatura MM, não aplica ao EpT) |
| `https://macmagazine.com.br/wp-admin/profile.php` | **REMOVER** |
| `https://macmagazine.com.br/politica-privacidade/` | `https://esporteparatodos.com/politica-privacidade/` ← **criar página no WP** |
| `https://macmagazine.com.br/termos-de-uso/` | `https://esporteparatodos.com/termos-de-uso/` ← **criar página no WP** |

### 3.5 Renomeações (Xcode + SPM)

| De | Para |
|---|---|
| `MacMagazine.xcodeproj` | `EsporteParaTodos.xcodeproj` |
| Scheme `MacMagazine.xcscheme` | `EsporteParaTodos.xcscheme` |
| Scheme `WatchApp.xcscheme` | (mantém) |
| Package `MacMagazineLibrary` | `EsporteParaTodosLibrary` |
| Package `MacMagazineUILibrary` | `EsporteParaTodosUILibrary` |
| Test plan `MacMagazine.xctestplan` | `EsporteParaTodos.xctestplan` |

### 3.6 Strings dentro do código Swift (131 arquivos)

A maioria das ocorrências em `.swift` são:
- Imports dos packages renomeados (`import MacMagazineLibrary` → `import EsporteParaTodosLibrary`)
- Nomes de classes (`MacMagazineApp`, `MacMagazineApp+Extensions`, etc.) → `EsporteParaTodosApp`
- Strings de UI hardcoded ("MacMagazine", "Equipe MM", etc.) → "Esporte para Todos", "Equipe EpT"
- Copyright headers (se houver) → atualizar autor

### 3.7 Recursos visuais

- App Icon (todas as resoluções no asset catalog)
- Launch Screen (storyboard ou SwiftUI view)
- Cores primárias/secundárias no asset catalog (definir paleta EpT)
- Splash screen
- Logo SVG/PDF se houver no projeto

### 3.8 Configurações de serviços externos

| Serviço | Estado atual | Ação |
|---|---|---|
| Firebase Analytics | Placeholder do MM via `setup-firebase.sh` | Criar projeto Firebase do EpT, baixar `GoogleService-Info.plist` próprio |
| OneSignal (push) | Configurado pra MM | **DECISÃO ABERTA**: criar conta OneSignal do EpT ou migrar pra FCM puro? |
| YouTube Data API | Provavelmente chave do MM | Criar projeto Google Cloud do EpT, gerar API key, substituir |

### 3.9 Documentação no repo

- `README.md` → reescrever pro EpT (mantendo crédito ao MacMagazine como base)
- `Support/CONTRIBUTING.md` → adaptar pro fork (URLs, branch names)
- `Support/FIREBASE.md` → adaptar
- `CLAUDE.md` → manter (é instruções pra IA, não tem branding)
- `.github/ISSUE_TEMPLATE/config.yml` → atualizar URLs

## 4. Decisões fechadas (2026-05-02)

1. **Push**: **OneSignal mantido pro MVP**. Só trocar app group `com.brit.macmagazine.onesignal.push` → `com.esporteparatodos.app.onesignal.push`. Migração pra FCM fica pra fase futura se necessário.
2. **Login WordPress**: **descartado**. Remover `/loginpatrao`, `/wp-admin/profile.php`, e a UI de "Login Patrão" das Settings (Bloco F).
3. **Categorias**: **feed cronológico único**, sem abas por categoria. Simplifica MainView/tabbar.
4. **Podcast**: EpT não tem por enquanto. **Manter o módulo PodcastLibrary** mas substituir o conteúdo da aba por placeholder "Em breve" (Bloco F).
5. **Watch app**: **cortar da onda 1**, fica pra fase futura. Desabilitar targets `WatchApp` e `WatchWidget` no Xcode.
6. **Widgets** (iOS): **mantidos** no escopo da onda 2.

## 5. Plano de execução (ordem das edições)

Quando aprovares, executo nesta ordem — cada bloco é commitável e testável:

1. **Bloco A — domínio + URLs** (10 min): edita `URLs.swift` e `FeedEndpoint.swift`. Build deve continuar passando. Feed do EpT começa a aparecer no simulador (sem ícone novo, ainda com cara de MacMagazine).
2. **Bloco B — bundle IDs + entitlements** (15 min): edita `project.pbxproj`, `Info.plist`, todos `.entitlements`. Necessário antes de rodar em device real.
3. **Bloco C — display name + copyright + strings UI** (20 min): adiciona `CFBundleDisplayName`, atualiza textos visíveis ao usuário.
4. **Bloco D — rename Xcode project + scheme + 2 packages SPM** (30 min, alto risco): renomeia `.xcodeproj`, scheme principal, 2 packages. Atualiza todos os `import` no Swift. Roda build pra validar.
5. **Bloco E — assets de marca** (depende dos teus assets): substitui app icon, launch screen, paleta de cores.
6. **Bloco F — desabilitar/limpar features cortadas** (login patrão, podcast se não tiver, etc.).
7. **Bloco G — validar build**: rodar em simulador, listar erros se houver, corrigir.

Após bloco G: pronto pra te entregar pra primeiro test run em iPhone físico.
