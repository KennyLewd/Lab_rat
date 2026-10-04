import SwiftUI
import AppKit

struct ExperimentEditor: View {
    @ObservedObject var store: LabStore
    var experiment: Experiment? = nil
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var steps = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Eyebrow(text: "THE NOTEBOOK")
            Text(experiment == nil ? "What’s on the bench?" : "Edit experiment").font(.system(size: 27, weight: .semibold, design: .rounded))
            field("Experiment name", text: $title, prompt: "e.g. GFP purification · batch 03")
            VStack(alignment: .leading, spacing: 7) { Text("Protocol steps · one per line").font(.system(size: 12, weight: .medium)); TextEditor(text: $steps).font(.system(size: 13)).scrollContentBackground(.hidden).padding(9).background(LabTheme.card, in: RoundedRectangle(cornerRadius: 9)).frame(height: 135) }
            field("Notes", text: $notes, prompt: "Sample IDs, buffer, things future-you should know")
            HStack { Button("Cancel") { dismiss() }.buttonStyle(LabButtonStyle()); Spacer(); Button(experiment == nil ? "Create experiment" : "Save changes") { commit(); dismiss() }.buttonStyle(LabButtonStyle(primary: true)).disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        }.padding(30).frame(width: 490).background(LabTheme.bg).foregroundStyle(LabTheme.white).preferredColorScheme(.dark)
            .onAppear { if let experiment { title = experiment.title; notes = experiment.notes; steps = experiment.steps.map(\.title).joined(separator: "\n") } }
    }
    private func commit() {
        if var existing = experiment {
            existing.title = title.trimmingCharacters(in: .whitespacesAndNewlines); existing.notes = notes
            var oldSteps = existing.steps
            existing.steps = steps.split(separator: "\n").map { line in
                let name = String(line).trimmingCharacters(in: .whitespaces)
                if let i = oldSteps.firstIndex(where: { $0.title == name }) { return oldSteps.remove(at: i) }
                return ExperimentStep(title: name)
            }.filter { !$0.title.isEmpty }
            store.updateExperiment(existing)
        } else { store.createExperiment(title: title, notes: notes, steps: steps) }
    }
}

func field(_ title: String, text: Binding<String>, prompt: String = "") -> some View {
    VStack(alignment: .leading, spacing: 7) { Text(title).font(.system(size: 12, weight: .medium)); TextField(prompt, text: text).textFieldStyle(.plain).font(.system(size: 13)).padding(11).background(LabTheme.card, in: RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(LabTheme.line, lineWidth: 1)) }
}

struct IncubationEditor: View {
    @ObservedObject var store: LabStore
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var temperature = "4°C"
    @State private var duration = "60"
    @State private var units = "minutes"
    @State private var alreadyStarted = false
    @State private var startDate = Date()
    private var seconds: Double? {
        guard let number = Double(duration), number.isFinite, number > 0 else { return nil }
        let result = number * (units == "hours" ? 3600 : units == "seconds" ? 1 : 60)
        return result >= 1 && result <= 31_536_000 ? result : nil
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Eyebrow(text: "SAMPLE SITTING")
            Text("I’ll watch the clock.").font(.system(size: 27, weight: .semibold, design: .rounded))
            field("Sample name", text: $title, prompt: "e.g. Protein elution · tube A")
            HStack(alignment: .bottom, spacing: 12) { field("Check after", text: $duration, prompt: "60"); Picker("Time unit", selection: $units) { ForEach(["seconds", "minutes", "hours"], id: \.self) { Text($0).tag($0) } }.labelsHidden().frame(width: 120).padding(.bottom, 7) }
            Picker("Temperature", selection: $temperature) { ForEach(["4°C", "−20°C", "−80°C", "Room temp", "25°C", "30°C", "37°C", "42°C", "65°C"], id: \.self) { Text($0).tag($0) } }
            Toggle("Already started", isOn: $alreadyStarted).toggleStyle(.switch).tint(LabTheme.lime)
            if alreadyStarted { DatePicker("Started at", selection: $startDate, in: ...Date(), displayedComponents: [.date, .hourAndMinute]) }
            Text("\(store.selected.map { "Linked to \($0.title). " } ?? "")Choose the check time from your protocol. Temperature is a label you set.").font(.system(size: 11)).foregroundStyle(LabTheme.muted).lineSpacing(4)
            if seconds == nil { Text("Enter a duration from 1 second to 365 days.").font(.system(size: 11)).foregroundStyle(LabTheme.amber) }
            HStack { Button("Cancel") { dismiss() }.buttonStyle(LabButtonStyle()); Spacer(); Button("Start sample timer") { if let seconds { store.addIncubation(title: title.trimmingCharacters(in: .whitespacesAndNewlines), temperature: temperature, seconds: seconds, startedAt: alreadyStarted ? startDate : Date()); dismiss() } }.buttonStyle(LabButtonStyle(primary: true)).disabled(seconds == nil || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
        }.padding(30).frame(width: 470).background(LabTheme.bg).foregroundStyle(LabTheme.white).preferredColorScheme(.dark)
    }
}

enum Calculation: String, CaseIterable {
    case dilution = "Dilution", mass = "Mass to weigh", molarity = "Molarity", od = "OD600", protein = "Protein / MW"
    var formula: String {
        switch self { case .dilution: return "C₁V₁ = C₂V₂"; case .mass: return "mass = concentration × volume × MW"; case .molarity: return "molarity = mass / (MW × volume)"; case .od: return "OD = (reading − blank) × dilution factor"; case .protein: return "µM = 1000 × (mg/mL) / MW in kDa" }
    }
    var labels: [String] {
        switch self {
        case .dilution: return ["Stock concentration · mM", "Target concentration · mM", "Final volume · mL"]
        case .mass: return ["Target concentration · mM", "Final volume · mL", "Molecular weight · g/mol"]
        case .molarity: return ["Mass · mg", "Final volume · mL", "Molecular weight · g/mol"]
        case .od: return ["Measured OD600", "Dilution factor · fold", "Blank OD600"]
        case .protein: return ["Protein concentration · mg/mL", "Molecular weight · kDa"]
        }
    }
    var defaults: [String] {
        switch self { case .dilution: return ["100", "10", "50"]; case .mass: return ["100", "100", "58.44"]; case .molarity: return ["584.4", "100", "58.44"]; case .od: return ["0.35", "10", "0.05"]; case .protein: return ["1", "50"] }
    }
    var note: String {
        switch self {
        case .dilution: return "Volumes assume additive mixing. The target must be at or below the stock concentration."
        case .mass: return "Bring the solution to the final volume after dissolving. Use the MW for the exact reagent, including hydrates."
        case .molarity: return "Use the final solution volume and the MW for the exact reagent."
        case .od: return "Use a reading within your instrument’s linear range. OD600 does not give a universal cell count."
        case .protein: return "Uses the MW you supply. This converts mass concentration to molar concentration; it does not predict MW from sequence."
        }
    }
}

struct CalculatorView: View {
    @State private var calculation: Calculation = .dilution
    @State private var inputs = Calculation.dilution.defaults
    @State private var copied = false
    private func formatted(_ value: Double) -> String { String(format: "%.6g", value) }
    private var result: (main: String, detail: String)? {
        let values = inputs.compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard values.count == calculation.labels.count else { return nil }
        switch calculation {
        case .dilution:
            guard let r = LabMath.dilution(stock: values[0], target: values[1], volume: values[2]) else { return nil }
            return ("\(formatted(r.stock)) mL stock", "Add \(formatted(r.diluent)) mL diluent · \(formatted(values[2])) mL final")
        case .mass:
            guard let r = LabMath.mass(millimolar: values[0], milliliters: values[1], molecularWeight: values[2]) else { return nil }
            return ("\(formatted(r)) mg", "= \(formatted(r / 1000)) g to weigh")
        case .molarity:
            guard let r = LabMath.molarity(milligrams: values[0], milliliters: values[1], molecularWeight: values[2]) else { return nil }
            return ("\(formatted(r)) mM", "= \(formatted(r / 1000)) mol/L")
        case .od:
            guard let r = LabMath.correctedOD(measured: values[0], dilutionFactor: values[1], blank: values[2]) else { return nil }
            return ("\(formatted(r)) OD600", "Blank corrected, adjusted for dilution")
        case .protein:
            guard let r = LabMath.micromolar(milligramsPerML: values[0], kilodaltons: values[1]) else { return nil }
            return ("\(formatted(r)) µM", "= \(formatted(r / 1000)) mM")
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Less mental math. More actual science.").font(.system(size: 13)).foregroundStyle(LabTheme.muted)
            HStack(spacing: 6) { ForEach(Calculation.allCases, id: \.self) { type in Button { calculation = type; inputs = type.defaults; copied = false } label: { Text(type.rawValue).font(.system(size: 11, weight: .medium)).padding(.horizontal, 12).padding(.vertical, 10).foregroundStyle(calculation == type ? LabTheme.bg : LabTheme.muted).background(calculation == type ? LabTheme.lime : LabTheme.card, in: RoundedRectangle(cornerRadius: 8)) }.buttonStyle(.plain) } }
            Card {
                VStack(alignment: .leading, spacing: 23) {
                    HStack { Text(calculation.rawValue).font(.system(size: 23, weight: .semibold, design: .rounded)); Spacer(); Image(systemName: "function").foregroundStyle(LabTheme.lime) }
                    Text(calculation.formula).font(.system(size: 15, design: .monospaced)).foregroundStyle(LabTheme.lime).textSelection(.enabled)
                    ForEach(calculation.labels.indices, id: \.self) { i in field(calculation.labels[i], text: Binding(get: { inputs.indices.contains(i) ? inputs[i] : "" }, set: { if inputs.indices.contains(i) { inputs[i] = $0; copied = false } })) }
                    VStack(alignment: .leading, spacing: 9) {
                        Eyebrow(text: "RESULT")
                        if let result {
                            HStack { Text(result.main).font(.system(size: 32, weight: .medium, design: .rounded)).foregroundStyle(LabTheme.lime).textSelection(.enabled); Spacer(); Button(copied ? "Copied ✓" : "Copy result") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString("\(calculation.rawValue): \(result.main). \(result.detail)", forType: .string); copied = true }.buttonStyle(LabButtonStyle()) }
                            Text(result.detail).font(.system(size: 13)).foregroundStyle(LabTheme.muted).textSelection(.enabled)
                        } else { Text(calculation == .od ? "Use finite numbers: reading ≥ blank ≥ 0, dilution factor ≥ 1." : calculation == .dilution ? "Use positive numbers. Target concentration must not exceed stock." : "Enter positive, finite numbers in every field.").font(.system(size: 12)).foregroundStyle(LabTheme.amber) }
                    }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(LabTheme.bg, in: RoundedRectangle(cornerRadius: 10))
                    Text(calculation.note).font(.system(size: 11)).foregroundStyle(LabTheme.muted).lineSpacing(4)
                }
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var store: LabStore
    @State private var focus = 25
    @State private var rest = 5
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Card {
                VStack(alignment: .leading, spacing: 18) {
                    Eyebrow(text: "RHYTHM OF THE BENCH")
                    Stepper("Run length: \(focus) minutes", value: $focus, in: 1...180)
                    Stepper("Recovery: \(rest) minutes", value: $rest, in: 1...60)
                    Button("Apply timer lengths") { store.setDurations(focus: focus, rest: rest); store.showToast("Timer lengths updated. Current phase reset.") }.buttonStyle(LabButtonStyle())
                    Text("Applying lengths resets the current focus timer.").font(.system(size: 11)).foregroundStyle(LabTheme.muted)
                }.font(.system(size: 13))
            }
            Card {
                VStack(alignment: .leading, spacing: 18) {
                    Eyebrow(text: "COMPANION")
                    Toggle("Keep floating buddy above other windows", isOn: $store.state.alwaysOnTop)
                    Toggle("Play a sound when a timer finishes", isOn: $store.state.soundEnabled)
                    Toggle("Show fake PI approval button", isOn: $store.state.showPI)
                    Text("PI approval is a joke button. It has no effect on experiments.").font(.system(size: 11)).foregroundStyle(LabTheme.muted)
                }.font(.system(size: 13)).toggleStyle(.switch).tint(LabTheme.lime)
                    .onChange(of: store.state.alwaysOnTop) { _, _ in store.preferencesChanged() }
                    .onChange(of: store.state.soundEnabled) { _, _ in store.preferencesChanged() }
                    .onChange(of: store.state.showPI) { _, _ in store.preferencesChanged() }
            }
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    Eyebrow(text: "NOTIFICATIONS")
                    HStack { Text(store.notificationStatus).font(.system(size: 13)); Spacer(); Button("Enable notifications") { store.enableNotifications() }.buttonStyle(LabButtonStyle(primary: true)) }
                    Text("The buddy and menu bar keep running when you close the workspace. macOS notifications require permission. After quitting the app, existing scheduled alerts depend on macOS delivery.").font(.system(size: 11)).foregroundStyle(LabTheme.muted).lineSpacing(4)
                }
            }
            Card { VStack(alignment: .leading, spacing: 12) { Eyebrow(text: "YOUR LOCAL NOTEBOOK"); Text("Saved on this Mac in Application Support/LabRat/state.json. No account or network connection needed.").font(.system(size: 12)).foregroundStyle(LabTheme.muted); Button("Show saved data") { let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("LabRat"); try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true); NSWorkspace.shared.open(folder) }.buttonStyle(LabButtonStyle()) } }
        }.onAppear { focus = store.state.run.focusMinutes; rest = store.state.run.restMinutes; store.refreshNotificationStatus() }
    }
}
