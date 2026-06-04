# Repository Guidelines

## Project Structure & Module Organization

This is a HarmonyOS ArkTS application. The entry module lives in `entry/`.

- `entry/src/main/ets/pages/`: top-level pages such as `Index.ets`, `MainTabs.ets`, `HomePage.ets`, and `MinePage.ets`.
- `entry/src/main/ets/features/`: feature code grouped by domain, for example `auth`, `banner`, and `music`.
- `entry/src/main/ets/common/`: shared utilities, including network, storage, and error handling.
- `entry/src/main/resources/`: app resources, media, profiles, and localized elements.
- `docs/`: API notes and integration documentation.
- `AppScope/`, `build-profile.json5`, `hvigorfile.ts`, and `oh-package.json5`: HarmonyOS project and build configuration.

## Build, Test, and Development Commands

Use the DevEco Studio bundled Node and hvigor wrapper. If DevEco Studio is installed elsewhere, update the paths.

```bash
"C:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon
```

This builds the `entry` HAP and runs ArkTS compilation. Test dependencies include `@ohos/hypium` and `@ohos/hamock`, but no dedicated test command or test directory is currently defined.

## Coding Style & Naming Conventions

Write ArkTS with clear, explicit types. Avoid structural typing and nested object literal type declarations; define named `interface`s instead. Use PascalCase for components, classes, and exported interfaces, and camelCase for fields, methods, and local variables.

Keep feature-specific code under `features/<domain>/` and shared code under `common/`. Prefer existing helpers such as `HttpClient`, `SessionStore`, and `ApiException` before adding new utilities.

## Testing Guidelines

When adding logic-heavy code, add Hypium tests where practical and keep test names behavior-focused, for example `AuthServiceStoresQrCookie`. For UI changes, verify at least the affected navigation path and run the HAP build command before handing off.

## Commit & Pull Request Guidelines

Git history is not available in this workspace, so use concise conventional-style commits such as `feat: add qr login` or `fix: handle account loading error`.

Pull requests should include the user-visible change, affected files or features, validation performed, and screenshots for UI changes. Link related issues or docs when the change depends on an API contract.

## Security & Configuration Tips

Do not commit real cookies, tokens, or account identifiers. Keep backend endpoints in `common/network/ApiConfig.ets` or documented configuration files, and treat `local.properties` as machine-specific.
