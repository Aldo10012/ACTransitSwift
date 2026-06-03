Add a complete SwiftUI example view for one ACTransitSwift service method, wire it into ContentView, and register it in the Xcode project.

## Argument parsing

The user invokes this as `/add-example <target>`. `$ARGUMENTS` contains the target.

Accepted formats:
- `RoutesService.routes` → serviceName = `RoutesService`, methodName = `routes`
- `ACTransitClient().routes.routes()` → resolve serviceName by reading ACTransitClient.swift (see Step 2)

If `$ARGUMENTS` is empty, respond:
> Please specify the service method, e.g. `/add-example RoutesService.routes`

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
| project.pbxproj | `Example/ACTransitExampleApp/ACTransitExampleApp.xcodeproj/project.pbxproj` |

---

## Step 1 — Resolve serviceName and methodName

From `$ARGUMENTS`:
- If format is `XxxService.method` → `serviceName = XxxService`, `methodName = method`
- If format is `ACTransitClient().prop.method()` → read ACTransitClient.swift to find which service type is exposed as `.prop`, derive `serviceName` from that type

---

## Step 2 — Read ACTransitClient.swift

Find the `public let` property whose type equals `serviceName`.
Record its property name as `clientAccessor` (e.g. `public let routes: RoutesService` → `clientAccessor = routes`).

---

## Step 3 — Read the service method signature

Read `Sources/ACTransitSwift/Services/{serviceName}.swift`.
Find the `public func {methodName}(...)` declaration.

Extract for each parameter:
- `label` (external name)
- `type` (raw Swift type string)
- `isOptional`: true if type ends with `?` or default is `nil`

Extract the return type (e.g. `[RouteDivision]`, `Route`).
Note whether it is an array (`[T]`) or a single value (`T`). Unwrap the element type `T`.

---

## Step 4 — Resolve each parameter's UI control

| Swift type | Control | Notes |
|---|---|---|
| `String` / `String?` | `TextField` | `.default` keyboard |
| `Int` / `Int?` | `TextField` | `.numberPad` keyboard; store as `String`, convert on submit |
| `Bool` / `Bool?` | `Toggle` | |
| Anything else | `Picker` | It's an enum — read its source file (search Endpoints/ then DTOs/) to enumerate all `case` lines and their raw values |

For every enum parameter: locate the enum's `.swift` file, parse every `case foo = "Bar"` or `case foo` line, and list them in the Picker.

---

## Step 5 — Check return type for coordinate fields

Read the DTO file for element type `T`. Recursively inspect every property at any nesting depth. If any property is named (case-insensitively) `latitude`, `longitude`, `lat`, or `lon`, plan to render results using a `Map`. Otherwise render as a `ForEach` list.

To recurse: for each property whose type is another struct defined in `Sources/ACTransitSwift/`, read that file too and repeat.

---

## Step 6 — Generate the view file

**Filename:** `{serviceName}_{methodName_capitalized_first_letter}.swift`
(e.g. `RoutesService_Routes.swift`, `RoutesService_Stops.swift`)

**Location:** `Example/ACTransitExampleApp/ACTransitExampleApp/ExampleViews/`

### State variables

```swift
// String param → stores as String
@State private var {paramName}: String = ""

// Int param → stores as String, convert to Int on submit
@State private var {paramName}: String = ""

// Bool param
@State private var {paramName}: Bool = false

// Optional enum param
@State private var {paramName}: {EnumType}? = nil

// Required enum param (use first case as default)
@State private var {paramName}: {EnumType} = .{firstCase}

// Result — array return type
@State private var results: [{ElementType}] = []

// Result — single return type
@State private var result: {ReturnType}? = nil

@State private var isLoading = false
@State private var errorMessage: String?

private let client = ACTransitClient()
```

### Parameters section

Only emit the `Section("Parameters") { ... }` block if the method has at least one parameter.

```swift
Section("Parameters") {
    // String / Int TextField
    HStack {
        TextField("{label} (e.g. …)", text: ${paramName})
            // add .keyboardType(.numberPad) for Int
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
            // … one per case
        }
        FieldBadge(requirement: .optional)
    }

    // Required enum Picker
    HStack {
        Picker("{label}", selection: ${paramName}) {
            Text("{case display}").tag({EnumType}.{caseName})
            // … one per case
        }
        FieldBadge(requirement: .required)
    }
}
```

### Search button disabled condition

Disabled when `isLoading == true` OR when any required String/Int field is empty.

```swift
SearchButton(isLoading: isLoading) {
    await fetch()
}
// SearchButton internally disables itself when isLoading; pass a combined condition:
// .disabled(isLoading || {requiredStringField}.isEmpty || ...)
// Apply .disabled on SearchButton if there are required fields.
```

### Loading and error sections

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

### Results — ForEach list (no coordinates)

Pick the two most human-readable `String` properties from `T` for primary/secondary display. Prefer properties named `name`, `description`, `title`, `id`, or similar.

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

For a single-value return, wrap the result display in `if let result { ... }`.

### Results — Map (coordinates found anywhere in type hierarchy)

```swift
import MapKit

// State
@State private var region = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 37.8, longitude: -122.27),
    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
)

// In body, after error section:
if !results.isEmpty {
    Section("Results (\(results.count))") {
        Map(coordinateRegion: $region, annotationItems: {flattenedCoordinateItems}) { item in
            MapMarker(coordinate: CLLocationCoordinate2D(
                latitude: item.{latField},
                longitude: item.{lonField}
            ))
        }
        .frame(height: 300)
        .listRowInsets(EdgeInsets())
    }
}
```

Flatten nested arrays if needed to reach the coordinate-bearing type.

### Navigation title

```swift
.navigationTitle("{serviceName}.{methodName}")
```

### fetch() function

```swift
private func fetch() async {
    isLoading = true
    errorMessage = nil
    do {
        results = try await client.{clientAccessor}.{methodName}(
            {label}: {conversion},
            // String → {paramName}.isEmpty ? nil : {paramName}   (optional)
            //       → {paramName}                                  (required)
            // Int   → Int({paramName})                            (force-unwrap safe: button disabled when empty)
            // Bool  → {paramName}
            // Enum  → {paramName}
        )
    } catch {
        errorMessage = error.localizedDescription
    }
    isLoading = false
}
```

### Full file template

```swift
import SwiftUI
// import MapKit  ← only when using Map
import ACTransitSwift

struct {ServiceName}_{MethodName}: View {
    // … state vars …

    private let client = ACTransitClient()

    var body: some View {
        Form {
            // Section("Parameters") { … }   ← omit if no params
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

---

## Step 7 — Register the file in project.pbxproj

1. Read `Example/ACTransitExampleApp/ACTransitExampleApp.xcodeproj/project.pbxproj`.

2. Generate two 24-character uppercase hex UUIDs:
   ```bash
   uuidgen | tr -d '-' | cut -c1-24 | tr 'a-z' 'A-Z'
   ```
   Call them `UUID_REF` and `UUID_BUILD`.

3. In the `/* Begin PBXFileReference section */` block, insert:
   ```
   		UUID_REF /* {Filename}.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {Filename}.swift; sourceTree = "<group>"; };
   ```

4. In the `/* Begin PBXBuildFile section */` block, insert:
   ```
   		UUID_BUILD /* {Filename}.swift in Sources */ = {isa = PBXBuildFile; fileRef = UUID_REF /* {Filename}.swift */; };
   ```

5. Find the PBXGroup for `ExampleViews` (search for `ExampleViews` in the file). Add `UUID_REF /* {Filename}.swift */,` to its `children` array.
   - If the `ExampleViews` group doesn't exist, find the main app group and add a new child group entry for it, then add the file reference inside.

6. Find the `PBXSourcesBuildPhase` section (search for `Sources */` then the `files = (` array). Add `UUID_BUILD /* {Filename}.swift in Sources */,` to that array.

**If any of the above edits fail**, tell the user:
> I couldn't edit the Xcode project file automatically. Please add a new Swift file named `{Filename}.swift` inside the `ExampleViews` group in Xcode (File → New → File → Swift File). Once you've added it, let me know and I'll fill in the contents.

Wait for confirmation before writing the file contents.

---

## Step 8 — Update ContentView.swift

Read `Example/ACTransitExampleApp/ACTransitExampleApp/ContentView.swift`.

**If a section with header `Text("{serviceName}")` already exists:**
Append inside its `Section { }` body:
```swift
cell(title: "{methodName}") { {ServiceName}_{MethodName}() }
```

**If no such section exists**, add a new section inside the `Form { }`:
```swift
Section {
    cell(title: "{methodName}") { {ServiceName}_{MethodName}() }
} header: {
    Text("{serviceName}")
}
```

---

## Done

Summarise what was created:
- New file: `ExampleViews/{ServiceName}_{MethodName}.swift`
- Xcode project: file registered (or prompt issued)
- ContentView: cell added under `{serviceName}` section
