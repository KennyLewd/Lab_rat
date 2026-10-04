import Foundation

struct ExperimentStep: Codable, Identifiable {
    var id = UUID()
    var title: String
    var done = false
}

struct Experiment: Codable, Identifiable {
    var id = UUID()
    var title: String
    var notes = ""
    var steps: [ExperimentStep] = []
    var archived = false
    var createdAt = Date()
}

struct Incubation: Codable, Identifiable {
    var id = UUID()
    var experimentID: UUID?
    var title: String
    var temperature: String
    var startedAt: Date
    var duration: TimeInterval
    var acknowledged = false
    var notified = false
    var deadline: Date { startedAt.addingTimeInterval(duration) }
    func remaining(at date: Date) -> TimeInterval { deadline.timeIntervalSince(date) }
    func elapsed(at date: Date) -> TimeInterval { max(0, date.timeIntervalSince(startedAt)) }
}

enum RunPhase: String, Codable, CaseIterable {
    case focus = "Run", rest = "Recovery"
}

struct FocusRun: Codable {
    var phase: RunPhase = .focus
    var focusMinutes = 25
    var restMinutes = 5
    var remaining: TimeInterval = 25 * 60
    var deadline: Date?
    var completed = 0
    var progressDuration: TimeInterval { Double(phase == .focus ? focusMinutes : restMinutes) * 60 }
    func seconds(at date: Date) -> TimeInterval { max(0, deadline?.timeIntervalSince(date) ?? remaining) }
}

struct SavedState: Codable {
    var experiments: [Experiment] = []
    var incubations: [Incubation] = []
    var selectedExperimentID: UUID?
    var run = FocusRun()
    var showPI = true
    var alwaysOnTop = true
    var soundEnabled = true
}

enum LabMath {
    struct DilutionResult { let stock: Double; let diluent: Double }
    static func dilution(stock: Double, target: Double, volume: Double) -> DilutionResult? {
        guard stock.isFinite, target.isFinite, volume.isFinite,
              stock > 0, target > 0, volume > 0, target <= stock else { return nil }
        let v = target / stock * volume
        guard v.isFinite else { return nil }
        return DilutionResult(stock: v, diluent: volume - v)
    }
    static func mass(millimolar: Double, milliliters: Double, molecularWeight: Double) -> Double? {
        guard valid([millimolar, milliliters, molecularWeight]) else { return nil }
        let mg = millimolar * milliliters * molecularWeight / 1000
        return mg.isFinite && mg > 0 ? mg : nil
    }
    static func molarity(milligrams: Double, milliliters: Double, molecularWeight: Double) -> Double? {
        guard valid([milligrams, milliliters, molecularWeight]) else { return nil }
        let mM = milligrams * 1000 / (milliliters * molecularWeight)
        return mM.isFinite && mM > 0 ? mM : nil
    }
    static func correctedOD(measured: Double, dilutionFactor: Double, blank: Double) -> Double? {
        guard measured.isFinite, blank.isFinite, dilutionFactor.isFinite,
              blank >= 0, measured >= blank, dilutionFactor >= 1 else { return nil }
        let value = (measured - blank) * dilutionFactor
        return value.isFinite ? value : nil
    }
    static func micromolar(milligramsPerML: Double, kilodaltons: Double) -> Double? {
        guard valid([milligramsPerML, kilodaltons]) else { return nil }
        let value = milligramsPerML * 1000 / kilodaltons
        return value.isFinite && value > 0 ? value : nil
    }
    private static func valid(_ values: [Double]) -> Bool { values.allSatisfy { $0.isFinite && $0 > 0 } }
}

func clockText(_ seconds: TimeInterval) -> String {
    let s = Int(max(0, seconds).rounded(.up))
    return s >= 3600 ? String(format: "%02d:%02d:%02d", s / 3600, s / 60 % 60, s % 60) : String(format: "%02d:%02d", s / 60, s % 60)
}

func elapsedText(_ seconds: TimeInterval) -> String {
    let s = Int(max(0, seconds))
    if s >= 3600 { return "\(s / 3600)h \(s / 60 % 60)m" }
    return "\(s / 60)m"
}

struct LabFact {
    let text: String
    let source: String
    let url: String
    static let all: [LabFact] = [
        .init(text: "One mole contains exactly 6.02214076 × 10²³ entities. Even the rat thinks that’s a lot.", source: "BIPM · The mole", url: "https://www.bipm.org/en/history-si/mole"),
        .init(text: "The SI has seven base units. The mole is the one for amount of substance.", source: "BIPM · SI base units", url: "https://www.bipm.org/en/measurement-units/si-base-units"),
        .init(text: "The modern SI is defined using seven fixed constants, including the Avogadro constant.", source: "BIPM · The SI", url: "https://www.bipm.org/en/measurement-units"),
        .init(text: "The mole’s current definition was adopted in 2018. It counts entities directly.", source: "BIPM · Resolution 1", url: "https://www.bipm.org/en/committees/cg/cgpm/26-2018/resolution-1")
    ]
}
