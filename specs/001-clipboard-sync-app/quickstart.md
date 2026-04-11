# Quickstart: Clip Bridge v1

## Prerequisites

- DevEco Studio 5.0+
- HarmonyOS NEXT SDK (API 12+)
- Physical HarmonyOS device or emulator (API 12+)

## Setup

1. Clone the repository and open in DevEco Studio
2. Sync project: `File > Sync and Refresh Project`
3. Connect a HarmonyOS device or start the emulator
4. Build and run the entry module

## Running Tests

### Unit Tests

```bash
# Run all unit tests via DevEco Studio
# Right-click entry/src/test/ > Run Tests

# Or via hvigor command line
hvigorw --mode module -p product=default -p module=entry@default assembleHap
hvigorw --mode module -p product=default -p module=entry@default unittest
```

### Instrumented Tests

```bash
# Requires connected device or emulator
hvigorw --mode module -p product=default -p module=entry@default instrumentTest
```

## Development Workflow

1. Pick a task from tasks.md (lowest ID first)
2. Write test for the task → verify test fails
3. Implement the task → verify test passes
4. Refactor if needed
5. Commit with conventional commit message

## Key Directories

| Path | Purpose |
|------|---------|
| `entry/src/main/ets/pages/` | ArkUI page components (Views) |
| `entry/src/main/ets/viewmodel/` | ViewModels |
| `entry/src/main/ets/model/` | Domain entity classes |
| `entry/src/main/ets/repository/` | Repository interfaces |
| `entry/src/main/ets/service/` | Business logic services |
| `entry/src/main/ets/data/` | Data layer (DAOs, DB, preferences) |
| `entry/src/main/ets/component/` | Shared UI components |
| `entry/src/main/ets/common/theme/` | Design tokens |
| `entry/src/test/ets/` | Unit tests |
| `entry/src/ohosTest/ets/` | Instrumented tests |

## Permissions Required

The app requires these permissions (declared in `module.json5`):

- `ohos.permission.READ_PASTEBOARD` — Read clipboard content
- `ohos.permission.KEEP_BACKGROUND_RUNNING` — Continuous background task
- `ohos.permission.ACCESS_BIOMETRIC` — Biometric re-authentication (optional)

## First Run Verification

1. Launch app — should show empty history with placeholder
2. Switch to another app, copy some text
3. Return to Clip Bridge — new entry should appear within 2 seconds
4. Tap entry — should open detail page with full content
5. Tap "复制" — content copied to clipboard, toast shown
6. Verify dark mode by switching system theme
