---
name: add-example-group
description: Adds SwiftUI example views for every public method in a service class, one commit per method, then opens a PR. Invoke with the service class name, e.g. "RoutesService", "StopsService", "VehicleService".
---

# Add Example Group

Adds a SwiftUI example view for every `public func` in one ACTransitSwift service class. Works top-to-bottom through the service file, skips methods that already have an example, commits after each new view, then opens a PR.

> **IMPORTANT — Do NOT call `/add-example` from inside this skill.** Nested skill invocations return control to the user instead of continuing the loop. All add-example steps are inlined in Step 4 below.

---

## Argument parsing

The argument is the full service class name, e.g. `RoutesService`, `StopsService`, `VehicleService`.

If the argument is empty, respond:
> Please specify a service class name, e.g. `/add-example-group RoutesService`

Then stop.

---

## Key paths (repo-root-relative)

| What | Path |
|---|---|
| ACTransitClient | `Sources/ACTransitSwift/ACTransitClient.swift` |
| Services | `Sources/ACTransitSwift/Services/` |
| DTOs | `Sources/ACTransitSwift/DTOs/` |
| Endpoints (enums) | `Sources/ACTransitSwift/Endpoints/` |
| Example views | `Example/ACTransitExampleApp/ACTransitExampleApp/ExampleViews/` |
| ContentView | `Example/ACTransitExampleApp/ACTransitExampleApp/ContentView.swift` |

---

## Step 1 — Verify a clean working tree

```bash
git status --porcelain
```

If the output is non-empty, stop and tell the user to commit or stash their changes first.

---

## Step 2 — Create or resume the feature branch

```bash
git checkout -b add_{ServiceName}_examples 2>/dev/null || git checkout add_{ServiceName}_examples
```

The `||` fallback lets the skill resume safely if the branch already exists from a previous partial run.

---

## Step 3 — Build the method work list

Read `Sources/ACTransitSwift/Services/{ServiceName}.swift`. Extract every `public func` declaration **in document order** (top to bottom). For each, record:
- `methodName` — the function name
- all parameter labels, types, and whether each is optional
- the return type (array `[T]` or single `T`)

Also read `Sources/ACTransitSwift/ACTransitClient.swift` to find the `public let` property whose type is `{ServiceName}`. Record its name as `clientAccessor`.

This produces an ordered work list of methods to process.

---

## Step 4 — Process each method

Work through the method list **one at a time**, in order. For each method:

### 4a — Check if already implemented

Check whether `Example/ACTransitExampleApp/ACTransitExampleApp/ExampleViews/{ServiceName}_{MethodNameCapitalized}.swift` exists:

```bash
ls Example/ACTransitExampleApp/ACTransitExampleApp/ExampleViews/{ServiceName}_{MethodNameCapitalized}.swift 2>/dev/null
```

Where `{MethodNameCapitalized}` is the method name with its first letter uppercased (e.g. `routes` → `Routes`, `tripStops` → `TripStops`).

If the file exists, add the method to the skipped-existing list and move to the next method.

### 4b — Resolve each parameter's UI control

| Swift type | Control | Notes |
|---|---|---|
| `String` / `String?` | `TextField` | `.default` keyboard |
| `Int` / `Int?` | `TextField` | `.keyboardType(.numberPad)`; store as `String` state var |
| `Bool` / `Bool?` | `Toggle` | |
| Anything else | `Picker` | Enum — read its source file (search `Endpoints/` then `DTOs/`) to enumerate every `case` |

For every enum parameter: locate its `.swift` file, parse every `case foo = "Bar"` or `case foo` line, and list them in the Picker.

### 4c — Check return type for coordinate fields

Read the DTO file for element type `T`. Recursively inspect every property at any nesting depth. If any property is named (case-insensitively) `latitude`, `longitude`, `lat`, or `lon`, render results using a **Map + list**. Otherwise render as a **ForEach list only**.

To recurse: for each property whose type is another struct defined in `Sources/ACTransitSwift/`, read that file too and repeat.

### 4d — Generate the view file

**Filename:** `{ServiceName}_{MethodNameCapitalized}.swift`
**Location:** `Example/ACTransitExampleApp/ACTransitExampleApp/ExampleViews/`

#### State variables

```swift
// String param
@State private var {paramName}: String = ""

// Int param (stored as String, converted in fetch)
@State private var {paramName}: String = ""

// Bool param
@State private var {paramName}: Bool = false

// Optional enum param
@State private var {paramName}: {EnumType}? = nil

// Required enum param (first case as default)
@State private var {paramName}: {EnumType} = .{firstCase}

// Array result
@State private var results: [{ElementType}] = []

// Single result
@State private var result: {ReturnType}? = nil

@State private var isLoading = false
@State private var errorMessage: String?

private let client = ACTransitClient()
```

For Map views, also add:
```swift
@State private var position: MapCameraPosition = .region(
    MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.8, longitude: -122.27),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
)
```

#### Parameters section

Only emit `Section("Parameters") { ... }` if the method has at least one parameter.

```swift
Section("Parameters") {
    // String / Int TextField
    HStack {
        TextField("{label} (e.g. …)", text: ${paramName})
            // .keyboardType(.numberPad) for Int
        FieldBadge(requirement: .{required|optional})
    }

    // Bool Toggle
    HStack {
        Toggle("{label}", isOn: ${paramName})
        FieldBadge(requirement: .{required|optional})
    }

    // Optional enum Picker
    HStack {
        Picker("{label}", selection: ${paramName}) {
            Text("none").tag({EnumType}?.none)
            Text("{case display}").tag({EnumType}?.some(.{caseName}))
        }
        FieldBadge(requirement: .optional)
    }

    // Required enum Picker
    HStack {
        Picker("{label}", selection: ${paramName}) {
            Text("{case display}").tag({EnumType}.{caseName})
        }
        FieldBadge(requirement: .required)
    }
}
```

#### Search button

```swift
SearchButton(isLoading: isLoading) {
    await fetch()
}
.disabled(isLoading || {requiredStringOrIntField}.isEmpty || …)
```

Only apply `.disabled` for required String/Int fields. Enum and Bool fields never block the button.

#### Loading and error sections

```swift
if isLoading {
    Section {
        HStack { Spacer(); ProgressView(); Spacer() }
    }
}

if let errorMessage {
    Section("Error") {
        Text(errorMessage).foregroundStyle(.red)
    }
}
```

#### Results — ForEach list (no coordinates)

Pick the two most human-readable `String` properties for primary/secondary display. Prefer `name`, `description`, `title`, `id`.

```swift
if !results.isEmpty {
    Section("Results (\(results.count))") {
        ForEach(results, id: \.{uniqueProperty}) { item in
            VStack(alignment: .leading) {
                Text(item.{primaryStringProp})
                    .fontWeight(.medium)
                Text(item.{secondaryStringProp})
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

#### Results — Map + list (coordinates found in type hierarchy)

```swift
if !results.isEmpty {
    Section("Results (\(results.count))") {
        Map(position: $position) {
            ForEach({coordinateItems}, id: \.{uniqueProperty}) { item in
                Marker("{label}", coordinate: CLLocationCoordinate2D(
                    latitude: item.{latField},
                    longitude: item.{lonField}
                ))
            }
        }
        .frame(height: 300)
        .listRowInsets(EdgeInsets())
        ForEach({coordinateItems}, id: \.{uniqueProperty}) { item in
            VStack(alignment: .leading) {
                Text(item.{primaryStringProp})
                    .fontWeight(.medium)
                Text(item.{secondaryStringProp})
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

If coordinates are optional (e.g. `latitude: Double?`), use `compactMap` to collect non-nil values and filter items for the map separately from the full list.

#### fetch() function

**Never force-unwrap.** Always use `guard let` for Int parsing and for collection `min()`/`max()`.

```swift
private func fetch() async {
    isLoading = true
    errorMessage = nil
    do {
        // Int params: parse before the API call
        guard let {parsedParam} = Int({paramName}) else { return }

        results = try await client.{clientAccessor}.{methodName}(
            {label}: {value},
            // String required  → {paramName}
            // String optional  → {paramName}.isEmpty ? nil : {paramName}
            // Int              → {parsedParam} (from guard let above)
            // Bool             → {paramName}
            // Enum             → {paramName}
        )

        // For Map views: fit camera to all results
        let lats = {coordinateItems}.compactMap(\.{latField})
        let lons = {coordinateItems}.compactMap(\.{lonField})
        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLon = lons.min(),
              let maxLon = lons.max() else { return }
        position = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(maxLat - minLat, 0.01) * 1.3,
                longitudeDelta: max(maxLon - minLon, 0.01) * 1.3
            )
        ))
    } catch {
        errorMessage = error.localizedDescription
    }
    isLoading = false
}
```

#### Full file structure

```swift
import SwiftUI
// import MapKit  ← only when using Map
import ACTransitSwift

struct {ServiceName}_{MethodNameCapitalized}: View {
    // state vars

    private let client = ACTransitClient()

    var body: some View {
        Form {
            // Section("Parameters") — omit if no params
            SearchButton(isLoading: isLoading) { await fetch() }
            // loading section
            // error section
            // results section
        }
        .navigationTitle("{serviceName}.{methodName}")
    }

    private func fetch() async { … }
}
```

### 4e — Update ContentView.swift

Read `Example/ACTransitExampleApp/ACTransitExampleApp/ContentView.swift`.

**If a section with header `Text("{ServiceName}")` already exists:**
Append inside its `Section { }` body:
```swift
cell(title: "{methodName}") { {ServiceName}_{MethodNameCapitalized}() }
```

**If no such section exists yet**, add a new section inside the `Form { }`:
```swift
Section {
    cell(title: "{methodName}") { {ServiceName}_{MethodNameCapitalized}() }
} header: {
    Text("{ServiceName}")
}
```

### 4f — Commit

Stage and commit immediately after each successfully generated view:

```bash
git add Example
git commit -m "add {ServiceName}_{MethodNameCapitalized}"
```

Add the method to the added list and proceed to the next method.

---

## Error handling — pause and report

If anything fails during Step 4 (unresolvable return type, missing DTO, unknown enum, write error, etc.):

1. **Delete any partially written file** for the current method before stopping, so the skip check in a future run doesn't mistake it for a completed view:
   ```bash
   rm -f Example/ACTransitExampleApp/ACTransitExampleApp/ExampleViews/{ServiceName}_{MethodNameCapitalized}.swift
   ```
2. **Stop processing** — do not move on to the next method.
3. **Report** the failure with:
   - Which method failed
   - What the specific error was
   - Which methods were completed (and committed) before the failure
   - Which methods remain to be processed
   - What the developer needs to resolve before continuing
4. **Wait** for the user to confirm the issue is resolved.
5. Once the user says to continue, **resume from the failed method** (re-attempt it, then proceed through the remaining methods).

---

## Step 5 — Build the example app

After all methods have been processed, build the example app to confirm it compiles:

```bash
xcodebuild \
  -project Example/ACTransitExampleApp/ACTransitExampleApp.xcodeproj \
  -scheme ACTransitExampleApp \
  -destination 'generic/platform=iOS Simulator' \
  build 2>&1 | tail -20
```

If the build fails, **stop**. Do not open a PR. Report the build output and identify which commit introduced the breakage (`git log --oneline`).

---

## Step 6 — Open a pull request

Push the branch and open a PR:

```bash
git push -u origin add_{ServiceName}_examples
```

```bash
gh pr create \
  --title "add {ServiceName} examples" \
  --body "$(cat <<'EOF'
## Summary

Adds SwiftUI example views for all `{ServiceName}` methods.

### Added ({N} views)
{bullet list of added method names}

### Skipped — already existed ({N})
{bullet list, or "None"}

## Test plan
- [ ] Example app builds without errors
- [ ] Each new view appears in ContentView under the `{ServiceName}` section
- [ ] Search button is disabled until required fields are filled
- [ ] Results render correctly (map pins + list rows for coordinate types; list only for others)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Step 7 — Report completion

```
Service: {ServiceName}
Branch:  add_{ServiceName}_examples
PR:      {PR URL}

Added ({N}):
  ✓ {methodName}
  ✓ {methodName}
  ...

Skipped — already existed ({N}):
  ↩ {methodName}
  ...
```
