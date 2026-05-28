# FormForge

A server-driven UI form builder for iOS that renders dynamic fields from a local JSON file. Built with SwiftUI and MVVM — no hardcoded UI.

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 15+
- No external dependencies<img width="1179" height="2556" alt="Simulator Screenshot - iPhone 16 - 2026-05-28 at 16 22 05" src="https://github.com/user-attachments/assets/dd877cae-e147-495f-bd31-6bc9b4fbc092" />
<img width="1179" height="2556" alt="Simulator Screenshot - iPhone 16 - 2026-05-28 at 16 22 10" src="https://github.com/user-attachments/assets/202d885e-13ef-403b-8707-a467a4f09f95" />


https://github.com/user-attachments/assets/7fb8cf56-6d55-418b-b2dd-834c088de6db



## Project Structure

```
FormForge/
├── FormForgeApp.swift       # @main entry point
├── MainView.swift           # Root view — loading / error / form states
├── FormFieldView.swift      # Field components (TEXT, DROPDOWN, TOGGLE, CHECKBOX)
├── FormViewModel.swift      # State management, validation, submission
├── FormModel.swift          # Codable models + Color(hex:) extension
├── FormDataService.swift    # JSON loading from bundle
└── form.json                # Form definition (must be in Copy Bundle Resources)
```

## Architecture

MVVM — the ViewModel owns all state and validation. Views are purely declarative and receive data via bindings and init parameters.

**Key decisions:**

- `AnyFormField` is a polymorphic enum — each field type has its own strongly-typed data struct. Unknown types fall back to `.unknown` and render as `EmptyView()` — no crashes on unexpected JSON.
- `FieldState` is a typed enum (`text`, `multiSelect`, `toggle`, `checkbox`) instead of `[String: Any]` — compile-time safety, no runtime casting.
- `@MainActor` on the ViewModel eliminates all `DispatchQueue.main` calls.
- All JSON decoding uses `(try? decode()) ?? default` — missing keys never throw.

## Supported Field Types

| Type | Notes |
|------|-------|
| TEXT | Subtypes: PLAIN, NUMBER, URI, MULTILINE, SECURE |
| DROPDOWN | Single or multi-select via `allow_multiple` |
| TOGGLE | Standard on/off switch |
| CHECKBOX | Supports tappable metadata links via `AttributedString` |

## Validation

Runs on Save tap. Errors display inline below each field.

- Required fields — empty check with custom `error_message` from JSON
- NUMBER subtype — must parse as a valid `Double`; non-numeric input stripped in real time
- TEXT maxLength — blocks submission if exceeded; inline counter turns red while typing

## Setup

1. Open `FormForge.xcodeproj` in Xcode 15+
2. Confirm `form.json` is listed in **Target → Build Phases → Copy Bundle Resources**
3. Run on Simulator or device (iOS 16+)

## Future Improvements

- `@FocusState` keyboard toolbar with Next / Done navigation
- Regex validation patterns defined in JSON per field
- Unit tests for JSON decoding and validation logic
- Remote JSON loading instead of bundle-only

## AI Collaboration

See `AI_COLLABORATION_LOG.md`
