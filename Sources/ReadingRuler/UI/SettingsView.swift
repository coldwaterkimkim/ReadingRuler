import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                generalSection
                shortcutsSection
                barSection
                highlightSection
                spotlightSection
                accessibilitySection
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 640, minHeight: 700)
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("General")

            Picker("Mode", selection: $appState.settings.mode) {
                ForEach(RulerMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Sticky ruler enabled", isOn: $appState.settings.stickyEnabled)
            Toggle("Hide menu bar icon", isOn: $appState.settings.hideMenuBarIcon)

            Button("Reset Current Mode Size / Offset") {
                appState.resetCurrentModeSizeAndOffset()
            }

            Text("Hold-to-show remains available even when sticky mode is off.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Shortcuts")

            VStack(alignment: .leading, spacing: 8) {
                Text("Hold-to-show")
                    .font(.subheadline.weight(.medium))
                ShortcutRecorder(shortcut: $appState.settings.shortcuts.holdToShow, allowsModifierOnly: false)
                    .frame(width: 210, height: 30)
                Text("Default: Option + Space. Modifier-only shortcuts are not finalized.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Toggle sticky ruler")
                    .font(.subheadline.weight(.medium))
                ShortcutRecorder(shortcut: $appState.settings.shortcuts.toggleSticky, allowsModifierOnly: false)
                    .frame(width: 210, height: 30)
                Text("Default: Control + Command + R")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Select Bar mode")
                    .font(.subheadline.weight(.medium))
                ShortcutRecorder(shortcut: $appState.settings.shortcuts.selectBarMode, allowsModifierOnly: false)
                    .frame(width: 210, height: 30)
                Text("Default: Control + Command + 1")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Select Highlight mode")
                    .font(.subheadline.weight(.medium))
                ShortcutRecorder(shortcut: $appState.settings.shortcuts.selectHighlightMode, allowsModifierOnly: false)
                    .frame(width: 210, height: 30)
                Text("Default: Control + Command + 2")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Select Spotlight mode")
                    .font(.subheadline.weight(.medium))
                ShortcutRecorder(shortcut: $appState.settings.shortcuts.selectSpotlightMode, allowsModifierOnly: false)
                    .frame(width: 210, height: 30)
                Text("Default: Control + Command + 3")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var barSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Bar Mode")

            sliderRow("Width", value: $appState.settings.bar.width, range: 40 ... 2400, format: "%.0f")
            sliderRow("Height", value: $appState.settings.bar.height, range: 2 ... 280, format: "%.0f")
            sliderRow("Corner Radius", value: $appState.settings.bar.cornerRadius, range: 0 ... 40, format: "%.0f")
            sliderRow("Opacity", value: $appState.settings.bar.opacity, range: 0.05 ... 1.0, format: "%.2f")
            sliderRow("Offset X", value: $appState.settings.bar.offsetX, range: -600 ... 600, format: "%.0f")
            sliderRow("Offset Y", value: $appState.settings.bar.offsetY, range: -600 ... 600, format: "%.0f")

            ColorPicker("Color", selection: colorBinding(for: \.bar.color))
        }
    }

    private var highlightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Highlight Mode")

            sliderRow("Width", value: $appState.settings.highlight.width, range: 40 ... 2600, format: "%.0f")
            sliderRow("Height", value: $appState.settings.highlight.height, range: 10 ... 500, format: "%.0f")
            sliderRow("Corner Radius", value: $appState.settings.highlight.cornerRadius, range: 0 ... 60, format: "%.0f")
            sliderRow("Opacity", value: $appState.settings.highlight.opacity, range: 0.05 ... 1.0, format: "%.2f")
            sliderRow("Offset X", value: $appState.settings.highlight.offsetX, range: -600 ... 600, format: "%.0f")
            sliderRow("Offset Y", value: $appState.settings.highlight.offsetY, range: -600 ... 600, format: "%.0f")

            ColorPicker("Color", selection: colorBinding(for: \.highlight.color))
        }
    }

    private var spotlightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Spotlight Mode")

            sliderRow("Width", value: $appState.settings.spotlight.width, range: 40 ... 2600, format: "%.0f")
            sliderRow("Height", value: $appState.settings.spotlight.height, range: 40 ... 1800, format: "%.0f")
            sliderRow("Dim Opacity", value: $appState.settings.spotlight.dimOpacity, range: 0.05 ... 0.95, format: "%.2f")
            sliderRow("Edge Feather", value: $appState.settings.spotlight.feather, range: 0 ... 80, format: "%.0f")
            sliderRow("Corner Radius", value: $appState.settings.spotlight.cornerRadius, range: 0 ... 100, format: "%.0f")
            sliderRow("Offset X", value: $appState.settings.spotlight.offsetX, range: -600 ... 600, format: "%.0f")
            sliderRow("Offset Y", value: $appState.settings.spotlight.offsetY, range: -600 ... 600, format: "%.0f")

            Picker("Shape", selection: $appState.settings.spotlight.shape) {
                ForEach(SpotlightShape.allCases) { shape in
                    Text(shape.title).tag(shape)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Permissions")

            HStack {
                Circle()
                    .fill(appState.accessibilityGranted ? Color.green : Color.orange)
                    .frame(width: 9, height: 9)
                Text(appState.accessibilityGranted ? "Accessibility access granted" : "Accessibility access may be required for some global shortcut setups")
            }

            HStack(spacing: 12) {
                Button("Refresh Permission Status") {
                    appState.refreshAccessibilityStatus()
                }

                Button("Open Accessibility Settings") {
                    appState.refreshAccessibilityStatus(promptIfNeeded: true)
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            Text("\(AppLabels.combinedName) does not capture text, record the screen, or send data over the network. It only tracks cursor position and draws overlays.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .padding(.bottom, 2)
    }

    private func sliderRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, format: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
            Slider(value: value, in: range)
            Text(String(format: format, value.wrappedValue))
                .font(.system(.body, design: .monospaced))
                .frame(width: 70, alignment: .trailing)
        }
    }

    private func colorBinding(for keyPath: WritableKeyPath<AppSettings, CodableColor>) -> Binding<Color> {
        Binding(
            get: {
                appState.settings[keyPath: keyPath].swiftUIColor
            },
            set: { newValue in
                if let nsColor = NSColor(newValue).usingColorSpace(.sRGB) {
                    appState.settings[keyPath: keyPath] = CodableColor(nsColor: nsColor)
                }
            }
        )
    }
}
