# Repository Guidelines

## Project Structure & Module Organization
This is a HarmonyOS ArkTS app. Main module code is under `entry/`.

- `entry/src/main/ets/pages/`: top-level pages (`Index.ets`, `MainTabs.ets`, `MusicPlayerPage.ets`)
- `entry/src/main/ets/features/`: domain features (for example `auth`, `banner`, `music`, `search`)
- `entry/src/main/ets/common/`: shared networking, storage, errors, and UI helpers
- `entry/src/main/resources/`: colors, media assets, profiles, and localized strings
- `docs/`: API notes and integration references
- `AppScope/`, `hvigorfile.ts`, `build-profile.json5`, `oh-package.json5`: app/build config

## Build, Test, and Development Commands
Use DevEco Studio toolchain for builds:

- Build HAP:
  `"C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon`
- Notes:
  this repository currently has `@ohos/hypium` and `@ohos/hamock` dependencies, but no dedicated test command is defined.

## Coding Style & Naming Conventions
- Write strict ArkTS with explicit types; define named `interface`s instead of nested structural types.
- Use `PascalCase` for components/classes/interfaces; `camelCase` for fields/methods/locals.
- Keep feature logic in `features/<domain>/`, shared logic in `common/`.
- Prefer existing utilities (`HttpClient`, `SessionStore`, `ApiException`) before adding new helpers.

## Testing Guidelines
- Test framework dependencies include `@ohos/hypium` and `@ohos/hamock`.
- For logic-heavy changes, add behavior-focused tests (for example `AuthServiceStoresQrCookie`).
- For UI changes, verify the affected navigation flow and run a HAP build before submitting.

## Commit & Pull Request Guidelines
- Use concise conventional commits, e.g. `feat: add playlist detail route fix`, `fix: hide tabs on subpage`.
- PRs should include:
  - user-visible behavior change
  - affected modules/files
  - validation performed (build/tests)
  - screenshots for UI changes
  - linked issue/doc when API contracts are involved

## Security & Configuration Tips
- Never commit real cookies, tokens, or account identifiers.
- Keep endpoint config in `entry/src/main/ets/common/network/ApiConfig.ets`.
- Treat `local.properties` as machine-specific and non-portable.
