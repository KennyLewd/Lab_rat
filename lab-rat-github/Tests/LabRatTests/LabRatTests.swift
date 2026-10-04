import XCTest
@testable import LabRat

final class LabRatTests: XCTestCase {
    func testDilutionConservesConcentrationAndVolume() throws {
        let r = try XCTUnwrap(LabMath.dilution(stock: 100, target: 10, volume: 50))
        XCTAssertEqual(r.stock, 5, accuracy: 0.000001)
        XCTAssertEqual(r.stock + r.diluent, 50, accuracy: 0.000001)
        XCTAssertEqual(100 * r.stock, 10 * 50, accuracy: 0.000001)
        XCTAssertNil(LabMath.dilution(stock: 10, target: 100, volume: 50))
        XCTAssertNil(LabMath.dilution(stock: 0, target: 10, volume: 50))
        XCTAssertNil(LabMath.dilution(stock: .infinity, target: 10, volume: 50))
    }
    func testMassAndMolarityUnitConversion() throws {
        let mg = try XCTUnwrap(LabMath.mass(millimolar: 100, milliliters: 100, molecularWeight: 58.44))
        XCTAssertEqual(mg, 584.4, accuracy: 0.000001)
        XCTAssertEqual(try XCTUnwrap(LabMath.molarity(milligrams: mg, milliliters: 100, molecularWeight: 58.44)), 100, accuracy: 0.000001)
        XCTAssertNil(LabMath.mass(millimolar: -1, milliliters: 100, molecularWeight: 58.44))
    }
    func testODBlankCorrectionAndProteinUnits() throws {
        XCTAssertEqual(try XCTUnwrap(LabMath.correctedOD(measured: 0.35, dilutionFactor: 10, blank: 0.05)), 3, accuracy: 0.000001)
        XCTAssertNil(LabMath.correctedOD(measured: 0.1, dilutionFactor: 10, blank: 0.2))
        XCTAssertNil(LabMath.correctedOD(measured: 0.5, dilutionFactor: 0, blank: 0))
        XCTAssertEqual(try XCTUnwrap(LabMath.micromolar(milligramsPerML: 1, kilodaltons: 50)), 20, accuracy: 0.000001)
    }
    func testIncubationUsesAbsoluteDeadline() {
        let start = Date(timeIntervalSince1970: 1000)
        let timer = Incubation(title: "Protein", temperature: "4°C", startedAt: start, duration: 3600)
        XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(17 * 3600)), -16 * 3600)
        XCTAssertEqual(timer.elapsed(at: start.addingTimeInterval(17 * 3600)), 17 * 3600)
    }
    @MainActor func testRunFinishesOnceAndWaitsForRecovery() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("state.json")
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let store = LabStore(fileURL: file, startTicker: false)
        store.state.soundEnabled = false
        let date = Date()
        store.state.run.deadline = date.addingTimeInterval(-1)
        store.tick(date); store.tick(date.addingTimeInterval(60))
        XCTAssertEqual(store.state.run.completed, 1)
        XCTAssertEqual(store.state.run.phase, .rest)
        XCTAssertNil(store.state.run.deadline)
        XCTAssertEqual(store.state.run.remaining, 300)
        let restored = LabStore(fileURL: file, startTicker: false)
        XCTAssertEqual(restored.state.run.completed, 1)
    }
    @MainActor func testNotebookPersistsAndCorruptOriginalIsPreserved() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("state.json")
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let store = LabStore(fileURL: file, startTicker: false)
        store.createExperiment(title: "GFP", notes: "Tube A", steps: "Lyse\nWash\nElute")
        store.toggleStep(try XCTUnwrap(store.selected?.steps.first?.id))
        let restored = LabStore(fileURL: file, startTicker: false)
        XCTAssertEqual(restored.selected?.title, "GFP")
        XCTAssertEqual(restored.selected?.steps.first?.done, true)
        let corrupt = Data("original-unreadable-data".utf8)
        try corrupt.write(to: file)
        let damaged = LabStore(fileURL: file, startTicker: false)
        XCTAssertNotNil(damaged.storageError)
        damaged.save()
        XCTAssertEqual(try Data(contentsOf: file), corrupt)
    }
}
