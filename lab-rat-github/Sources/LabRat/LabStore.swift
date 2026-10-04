import AppKit
import Combine
import UserNotifications

@MainActor final class LabStore: ObservableObject {
    @Published var state: SavedState
    @Published var now = Date()
    @Published var toast: String?
    @Published var storageError: String?
    @Published var notificationStatus = "Not enabled"
    @Published var factIndex = Int.random(in: 0..<LabFact.all.count)
    private var ticker: AnyCancellable?
    private var toastJob: DispatchWorkItem?
    private let fileURL: URL
    var onTick: (() -> Void)?
    var onPreferencesChanged: (() -> Void)?

    var selected: Experiment? { state.experiments.first { $0.id == state.selectedExperimentID } }
    var activeTimers: [Incubation] { state.incubations.filter { !$0.acknowledged }.sorted { $0.deadline < $1.deadline } }
    var fact: LabFact { LabFact.all[factIndex] }
    var runSeconds: TimeInterval { state.run.seconds(at: now) }
    var runRunning: Bool { state.run.deadline != nil }

    init(fileURL: URL? = nil, startTicker: Bool = true) {
        self.fileURL = fileURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LabRat/state.json")
        if FileManager.default.fileExists(atPath: self.fileURL.path) {
            do { state = try JSONDecoder().decode(SavedState.self, from: Data(contentsOf: self.fileURL)) }
            catch {
                state = SavedState()
                storageError = "Your saved data couldn’t be read. The original file is preserved. \(error.localizedDescription)"
            }
        } else { state = SavedState() }
        if startTicker {
            ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] date in self?.tick(date) }
            refreshNotificationStatus()
        }
    }

    func save() {
        // Never overwrite an unreadable original file without explicit recovery.
        guard storageError == nil else { return }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(state).write(to: fileURL, options: .atomic)
        } catch { storageError = "Couldn’t save experiments: \(error.localizedDescription)" }
    }

    func tick(_ date: Date) {
        now = date
        if let deadline = state.run.deadline, deadline <= date {
            let oldPhase = state.run.phase
            if oldPhase == .focus { state.run.completed += 1 }
            state.run.phase = oldPhase == .focus ? .rest : .focus
            state.run.deadline = nil
            state.run.remaining = state.run.progressDuration
            announce(oldPhase == .focus ? "Run complete. Take a recovery break." : "Recovery complete. Ready for another run?")
            save()
        }
        var changed = false
        for i in state.incubations.indices where !state.incubations[i].acknowledged && !state.incubations[i].notified && state.incubations[i].deadline <= date {
            state.incubations[i].notified = true
            announce("\(state.incubations[i].title) at \(state.incubations[i].temperature) is ready. Check your sample.")
            changed = true
        }
        if changed { save() }
        onTick?()
    }

    func select(_ id: UUID) { state.selectedExperimentID = id; save(); onTick?() }
    func createExperiment(title: String, notes: String, steps: String) {
        let experiment = Experiment(title: title.trimmingCharacters(in: .whitespacesAndNewlines), notes: notes,
            steps: steps.split(separator: "\n").map { ExperimentStep(title: String($0).trimmingCharacters(in: .whitespaces)) }.filter { !$0.title.isEmpty })
        guard !experiment.title.isEmpty else { return }
        state.experiments.insert(experiment, at: 0)
        state.selectedExperimentID = experiment.id
        save(); onTick?(); showToast("New experiment, fresh notebook energy.")
    }
    func updateExperiment(_ updated: Experiment) {
        guard let i = state.experiments.firstIndex(where: { $0.id == updated.id }) else { return }
        state.experiments[i] = updated; save(); onTick?()
    }
    func toggleStep(_ id: UUID) {
        guard let e = state.experiments.firstIndex(where: { $0.id == state.selectedExperimentID }),
              let s = state.experiments[e].steps.firstIndex(where: { $0.id == id }) else { return }
        state.experiments[e].steps[s].done.toggle(); save()
    }
    func archiveSelected() {
        guard let i = state.experiments.firstIndex(where: { $0.id == state.selectedExperimentID }) else { return }
        state.experiments[i].archived = true
        state.selectedExperimentID = state.experiments.first(where: { !$0.archived })?.id
        save(); onTick?(); showToast("Experiment filed in the archive.")
    }
    func restore(_ id: UUID) {
        guard let i = state.experiments.firstIndex(where: { $0.id == id }) else { return }
        state.experiments[i].archived = false; select(id)
    }
    func toggleRun() {
        now = Date()
        if state.run.deadline != nil {
            state.run.remaining = state.run.seconds(at: now); state.run.deadline = nil
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["focus-run"])
        } else {
            state.run.deadline = now.addingTimeInterval(state.run.remaining)
            schedule(id: "focus-run", title: "\(state.run.phase.rawValue) complete", body: state.run.phase == .focus ? "Step away from the bench. You earned a break." : "Ready for the next run?", delay: state.run.remaining)
        }
        save(); onTick?()
    }
    func resetRun() {
        state.run.deadline = nil; state.run.remaining = state.run.progressDuration
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["focus-run"])
        save(); onTick?()
    }
    func setPhase(_ phase: RunPhase) { state.run.phase = phase; resetRun() }
    func setDurations(focus: Int, rest: Int) {
        state.run.focusMinutes = min(180, max(1, focus)); state.run.restMinutes = min(60, max(1, rest)); resetRun()
    }
    func addIncubation(title: String, temperature: String, seconds: Double, startedAt: Date) {
        guard seconds.isFinite, seconds >= 1, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let timer = Incubation(experimentID: state.selectedExperimentID, title: title, temperature: temperature, startedAt: startedAt, duration: seconds)
        state.incubations.append(timer)
        schedule(id: timer.id.uuidString, title: "Incubation ready", body: "\(title) at \(temperature). Time to check your sample.", delay: timer.deadline.timeIntervalSinceNow)
        save(); tick(Date()); showToast("Sample on the clock. I’ll keep watch.")
    }
    func acknowledge(_ id: UUID) {
        guard let i = state.incubations.firstIndex(where: { $0.id == id }) else { return }
        state.incubations[i].acknowledged = true
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
        save()
    }
    func showToast(_ message: String) {
        toastJob?.cancel(); toast = message
        let job = DispatchWorkItem { [weak self] in self?.toast = nil }
        toastJob = job; DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: job)
    }
    func announce(_ message: String) {
        showToast(message)
        if state.soundEnabled && (NSApp.isActive || notificationStatus != "Enabled") { NSSound(named: "Glass")?.play() }
    }
    func nextFact() { factIndex = (factIndex + 1) % LabFact.all.count }
    func fakeApproval() {
        showToast(["PI approved.*  *The PI is a rat. This is a joke.", "Reviewer 2 requests more cheese. (Just a joke.)", "Looks promising. Have you tried doing it three more times? — Fake PI"].randomElement()!)
    }
    func preferencesChanged() { save(); onPreferencesChanged?() }
    func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.notificationStatus = settings.authorizationStatus == .authorized ? "Enabled" : settings.authorizationStatus == .denied ? "Disabled in System Settings" : "Not enabled"
            }
        }
    }
    func enableNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] allowed, error in
            Task { @MainActor in
                guard let self else { return }
                self.refreshNotificationStatus()
                if let error { self.showToast(error.localizedDescription) }
                else if allowed {
                    self.showToast("Notifications enabled. Your rat has a voice.")
                    if let deadline = self.state.run.deadline { self.schedule(id: "focus-run", title: "Run complete", body: "Check Lab Rat for your next phase.", delay: deadline.timeIntervalSinceNow) }
                    for timer in self.activeTimers where timer.deadline > Date() {
                        self.schedule(id: timer.id.uuidString, title: "Incubation ready", body: "\(timer.title) at \(timer.temperature). Check your sample.", delay: timer.deadline.timeIntervalSinceNow)
                    }
                } else { self.showToast("Enable Lab Rat in System Settings → Notifications.") }
            }
        }
    }
    private func schedule(id: String, title: String, body: String, delay: TimeInterval) {
        guard delay > 0 else { return }
        let content = UNMutableNotificationContent(); content.title = title; content.body = body
        if state.soundEnabled { content.sound = .default }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, delay), repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger)) { _ in }
    }
}
