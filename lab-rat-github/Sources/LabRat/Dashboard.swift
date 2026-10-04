import SwiftUI
import AppKit

enum LabPage: String, CaseIterable {
    case bench = "My bench", timers = "Incubations", calculator = "Calculators", archive = "Archive", settings = "Settings"
    var icon: String {
        switch self { case .bench: return "square.grid.2x2"; case .timers: return "timer"; case .calculator: return "function"; case .archive: return "archivebox"; case .settings: return "slider.horizontal.3" }
    }
}

struct Dashboard: View {
    @ObservedObject var store: LabStore
    @State private var page: LabPage = .bench
    @State private var newExperiment = false
    @State private var newTimer = false
    @State private var editExperiment = false
    @State private var archiveConfirmation = false
    var showCompanion: () -> Void
    var body: some View {
        HStack(spacing: 0) {
            sidebar
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow(text: "YOUR RESEARCH, A LITTLE LESS CHAOTIC")
                        Text(page.rawValue).font(.system(size: 29, weight: .semibold, design: .rounded))
                    }
                    Spacer()
                    Button(action: showCompanion) { Label("Float buddy", systemImage: "rectangle.on.rectangle") }.buttonStyle(LabButtonStyle())
                    if page == .bench {
                        Button { newExperiment = true } label: { Label("New experiment", systemImage: "plus") }.buttonStyle(LabButtonStyle(primary: true))
                    } else if page == .timers {
                        Button { newTimer = true } label: { Label("New timer", systemImage: "plus") }.buttonStyle(LabButtonStyle(primary: true))
                    }
                }.padding(.horizontal, 28).padding(.top, 30).padding(.bottom, 25)
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let error = store.storageError { Text(error).foregroundStyle(LabTheme.amber).padding().background(LabTheme.card, in: RoundedRectangle(cornerRadius: 12)) }
                        switch page {
                        case .bench: bench
                        case .timers: timers
                        case .calculator: CalculatorView()
                        case .archive: archive
                        case .settings: SettingsView(store: store)
                        }
                    }.padding(.horizontal, 28).padding(.bottom, 28)
                }
                HStack {
                    Circle().fill(LabTheme.lime).frame(width: 5, height: 5)
                    Text("LOCAL NOTEBOOK").tracking(1.3)
                    Spacer()
                    Text("\(store.activeTimers.count) timers on the bench  ·  \(store.state.run.completed) runs completed")
                }.font(.system(size: 9, design: .monospaced)).foregroundStyle(LabTheme.muted).padding(.horizontal, 28).padding(.vertical, 13).background(LabTheme.sidebar)
            }
        }.foregroundStyle(LabTheme.white).background(LabTheme.bg).preferredColorScheme(.dark)
            .frame(minWidth: 980, minHeight: 720)
            .overlay(alignment: .bottom) {
                if let toast = store.toast { Text(toast).font(.system(size: 12, weight: .medium)).padding(14).background(LabTheme.lime, in: RoundedRectangle(cornerRadius: 10)).foregroundStyle(LabTheme.bg).shadow(radius: 12).padding(.bottom, 48).padding(.horizontal, 30).transition(.opacity) }
            }
            .sheet(isPresented: $newExperiment) { ExperimentEditor(store: store) }
            .sheet(isPresented: $newTimer) { IncubationEditor(store: store) }
            .sheet(isPresented: $editExperiment) { if let experiment = store.selected { ExperimentEditor(store: store, experiment: experiment) } }
            .alert("Archive this experiment?", isPresented: $archiveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Archive") { store.archiveSelected() }
            } message: { Text("You can restore it from Archive. Its incubation timers will keep running.") }
    }
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                RatMascot(size: 33)
                Text("lab rat").font(.system(size: 23, weight: .bold, design: .rounded))
                Text("β").foregroundStyle(LabTheme.lime).font(.system(size: 12))
            }.padding(.bottom, 8)
            Text("A LITTLE LAB COMPANY").font(.system(size: 8, design: .monospaced)).tracking(1.8).foregroundStyle(LabTheme.muted).padding(.bottom, 35)
            ForEach([LabPage.bench, .timers, .calculator], id: \.self) { destination in nav(destination) }
            Eyebrow(text: "EXPERIMENTS").padding(.top, 29).padding(.bottom, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(store.state.experiments.filter { !$0.archived }) { experiment in
                        Button { store.select(experiment.id); page = .bench } label: {
                            HStack(spacing: 8) {
                                Circle().fill(experiment.id == store.state.selectedExperimentID ? LabTheme.lime : LabTheme.muted).frame(width: 5, height: 5)
                                Text(experiment.title).lineLimit(2).multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }.font(.system(size: 11)).padding(10).background(experiment.id == store.state.selectedExperimentID ? LabTheme.card : .clear, in: RoundedRectangle(cornerRadius: 8))
                        }.buttonStyle(.plain)
                    }
                    if store.state.experiments.filter({ !$0.archived }).isEmpty { Text("Your next discovery\nstarts here.").font(.system(size: 11)).foregroundStyle(LabTheme.muted).lineSpacing(5).padding(10) }
                }
            }
            Spacer(minLength: 10)
            nav(.archive); nav(.settings)
            HStack(spacing: 10) { RatMascot(size: 44); VStack(alignment: .leading, spacing: 3) { Text("On your side.").font(.system(size: 11, weight: .medium)); Text("Even on run #47.").font(.system(size: 10)).foregroundStyle(LabTheme.muted) } }.padding(.top, 20)
        }.padding(.horizontal, 18).padding(.top, 33).padding(.bottom, 20).frame(width: 196).background(LabTheme.sidebar)
    }
    private func nav(_ destination: LabPage) -> some View {
        Button { page = destination } label: {
            HStack(spacing: 11) { Image(systemName: destination.icon).frame(width: 17); Text(destination.rawValue); Spacer(); if destination == .timers && !store.activeTimers.isEmpty { Text("\(store.activeTimers.count)").font(.system(size: 10, design: .monospaced)) } }
                .font(.system(size: 12, weight: page == destination ? .semibold : .regular)).foregroundStyle(page == destination ? LabTheme.lime : LabTheme.muted)
                .padding(.horizontal, 12).padding(.vertical, 12).background(page == destination ? LabTheme.lime.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 9))
        }.buttonStyle(.plain).padding(.bottom, 3)
    }
    private var bench: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 18) {
                Card { FocusCard(store: store) }.frame(width: 272)
                Card {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack { Eyebrow(text: "ACTIVE EXPERIMENT"); Spacer(); if store.selected != nil { Button { editExperiment = true } label: { Image(systemName: "pencil") }.buttonStyle(.plain).foregroundStyle(LabTheme.muted).help("Edit experiment") } }
                        if let experiment = store.selected {
                            Text(experiment.title).font(.system(size: 21, weight: .semibold, design: .rounded))
                            let done = experiment.steps.filter(\.done).count
                            HStack { ProgressView(value: Double(done), total: Double(max(1, experiment.steps.count))).tint(LabTheme.lime); Text("\(done)/\(experiment.steps.count)").font(.system(size: 10, design: .monospaced)).foregroundStyle(LabTheme.muted) }
                            if experiment.steps.isEmpty { Text("Add your protocol steps with the edit button.").font(.system(size: 12)).foregroundStyle(LabTheme.muted) }
                            ForEach(experiment.steps) { step in
                                Button { store.toggleStep(step.id) } label: {
                                    HStack(alignment: .top, spacing: 10) { Image(systemName: step.done ? "checkmark.circle.fill" : "circle").foregroundStyle(step.done ? LabTheme.lime : LabTheme.muted); Text(step.title).strikethrough(step.done).foregroundStyle(step.done ? LabTheme.muted : LabTheme.white); Spacer(minLength: 0) }.font(.system(size: 12)).multilineTextAlignment(.leading)
                                }.buttonStyle(.plain).accessibilityLabel("\(step.title), \(step.done ? "complete" : "incomplete")")
                            }
                            if !experiment.notes.isEmpty { Text(experiment.notes).font(.system(size: 11)).foregroundStyle(LabTheme.muted).padding(.top, 3).textSelection(.enabled) }
                            HStack { Button { newTimer = true } label: { Label("Incubate", systemImage: "timer") }.buttonStyle(LabButtonStyle()); Spacer(); Button { archiveConfirmation = true } label: { Image(systemName: "archivebox") }.buttonStyle(.plain).foregroundStyle(LabTheme.muted).help("Archive experiment") }
                        } else {
                            Text("Make room for discovery.").font(.system(size: 23, weight: .semibold, design: .rounded))
                            Text("Give your experiment a name, add your steps, and let your bench buddy watch the clock.").font(.system(size: 13)).foregroundStyle(LabTheme.muted).lineSpacing(5)
                            Button { newExperiment = true } label: { Label("Create first experiment", systemImage: "plus") }.buttonStyle(LabButtonStyle(primary: true))
                            Text("No account. Just you and the rat.").font(.system(size: 10, design: .monospaced)).foregroundStyle(LabTheme.muted)
                        }
                    }.frame(maxWidth: .infinity, minHeight: 289, alignment: .topLeading)
                }
            }
            HStack { Eyebrow(text: "ON THE CLOCK"); Spacer(); Button { page = .timers } label: { Text("View all →").font(.system(size: 11)).foregroundStyle(LabTheme.muted) }.buttonStyle(.plain) }
            if store.activeTimers.isEmpty {
                Card { HStack(spacing: 14) { Image(systemName: "thermometer.medium").font(.system(size: 22)).foregroundStyle(LabTheme.muted); VStack(alignment: .leading, spacing: 5) { Text("Nothing incubating. Yet.").font(.system(size: 13, weight: .medium)); Text("Set a sample timer, including one already in progress.").font(.system(size: 11)).foregroundStyle(LabTheme.muted) }; Spacer(); Button { newTimer = true } label: { Text("Add timer +") }.buttonStyle(LabButtonStyle()) } }
            } else { ForEach(Array(store.activeTimers.prefix(2))) { timer in IncubationRow(store: store, timer: timer) } }
            FactCard(store: store)
        }
    }
    private var timers: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Every sample has its own clock. You choose the check-in time.").font(.system(size: 13)).foregroundStyle(LabTheme.muted)
            if store.activeTimers.isEmpty { Card { VStack(alignment: .leading, spacing: 14) { RatMascot(); Text("I’m ready to sample-sit.").font(.system(size: 24, weight: .semibold, design: .rounded)); Text("Add a timer above for your next incubation.").foregroundStyle(LabTheme.muted) } } }
            ForEach(store.activeTimers) { timer in IncubationRow(store: store, timer: timer) }
            let finished = store.state.incubations.filter(\.acknowledged).sorted { $0.startedAt > $1.startedAt }
            if !finished.isEmpty {
                Eyebrow(text: "CHECKED SAMPLES").padding(.top, 12)
                ForEach(finished) { timer in Card { HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(LabTheme.lime); Text(timer.title); Spacer(); Text(timer.temperature).foregroundStyle(LabTheme.muted); Text(timer.startedAt, style: .date).foregroundStyle(LabTheme.muted) }.font(.system(size: 12)) } }
            }
        }
    }
    private var archive: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Completed work, kept for the next time you need it.").foregroundStyle(LabTheme.muted).font(.system(size: 13))
            let archived = store.state.experiments.filter(\.archived)
            if archived.isEmpty { Card { Text("Your archive is empty. Finish something wonderful.").font(.system(size: 14)) } }
            ForEach(archived) { experiment in Card { HStack { VStack(alignment: .leading, spacing: 6) { Text(experiment.title).font(.system(size: 17, weight: .medium)); Text("\(experiment.steps.filter(\.done).count) of \(experiment.steps.count) steps complete").font(.system(size: 11)).foregroundStyle(LabTheme.muted) }; Spacer(); Button("Restore") { store.restore(experiment.id); page = .bench }.buttonStyle(LabButtonStyle()) } } }
        }
    }
}

struct FocusCard: View {
    @ObservedObject var store: LabStore
    var body: some View {
        VStack(spacing: 14) {
            HStack { Eyebrow(text: "FOCUS TIMER"); Spacer(); Pill(text: store.runRunning ? "LIVE" : "READY") }
            HStack(spacing: 4) { ForEach(RunPhase.allCases, id: \.self) { phase in Button { store.setPhase(phase) } label: { Text(phase.rawValue).font(.system(size: 10, weight: .medium)).padding(.horizontal, 13).padding(.vertical, 6).foregroundStyle(store.state.run.phase == phase ? LabTheme.lime : LabTheme.muted).background(store.state.run.phase == phase ? LabTheme.line : .clear, in: Capsule()) }.buttonStyle(.plain) } }
            ZStack { TimerRing(fraction: store.runSeconds / store.state.run.progressDuration, size: 118) }
            VStack(spacing: 3) { Text(clockText(store.runSeconds)).font(.system(size: 37, weight: .light, design: .monospaced)).monospacedDigit(); Text(store.state.run.phase == .focus ? "One run. One thing at a time." : "Drink some water. Look away.").font(.system(size: 10)).foregroundStyle(LabTheme.muted) }
            HStack(spacing: 8) { Button { store.toggleRun() } label: { Label(store.runRunning ? "Pause" : "Start \(store.state.run.phase.rawValue.lowercased())", systemImage: store.runRunning ? "pause.fill" : "play.fill").frame(maxWidth: .infinity) }.buttonStyle(LabButtonStyle(primary: true)); Button { store.resetRun() } label: { Image(systemName: "arrow.counterclockwise") }.buttonStyle(LabButtonStyle()).help("Reset timer") }
        }
    }
}

struct IncubationRow: View {
    @ObservedObject var store: LabStore
    let timer: Incubation
    var body: some View {
        let remaining = timer.remaining(at: store.now)
        Card {
            HStack(alignment: .center, spacing: 15) {
                Image(systemName: remaining <= 0 ? "exclamationmark.circle" : "thermometer.snowflake").font(.system(size: 24)).foregroundStyle(remaining <= 0 ? LabTheme.amber : LabTheme.lime).frame(width: 33)
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text(timer.title).font(.system(size: 13, weight: .semibold)); Pill(text: timer.temperature, color: remaining <= 0 ? LabTheme.amber : LabTheme.lime) }
                    if remaining <= 0 { Text("At \(timer.temperature) for \(elapsedText(timer.elapsed(at: store.now))). Still meant to be there?").foregroundStyle(LabTheme.amber).font(.system(size: 11)) }
                    else { Text("\(elapsedText(timer.elapsed(at: store.now))) elapsed · \(store.state.experiments.first(where: { $0.id == timer.experimentID })?.title ?? "Bench timer")").foregroundStyle(LabTheme.muted).font(.system(size: 10)) }
                }
                Spacer(minLength: 5)
                VStack(alignment: .trailing, spacing: 4) { Text(clockText(abs(remaining))).font(.system(size: 22, weight: .light, design: .monospaced)).foregroundStyle(remaining <= 0 ? LabTheme.amber : LabTheme.white).monospacedDigit(); Text(remaining <= 0 ? "OVERDUE" : "REMAINING").font(.system(size: 8, design: .monospaced)).tracking(1.2).foregroundStyle(LabTheme.muted) }
                Button(remaining <= 0 ? "Checked" : "Finish") { store.acknowledge(timer.id) }.buttonStyle(LabButtonStyle()).help("Mark sample checked and stop its alert")
            }
        }
    }
}

struct FactCard: View {
    @ObservedObject var store: LabStore
    var body: some View {
        Card { HStack(alignment: .top, spacing: 14) { Image(systemName: "sparkles").foregroundStyle(LabTheme.lime).padding(.top, 2); VStack(alignment: .leading, spacing: 9) { Eyebrow(text: "A SMALL DOSE OF SCIENCE"); Text(store.fact.text).font(.system(size: 12)).lineSpacing(4); Link(store.fact.source + " ↗", destination: URL(string: store.fact.url)!).font(.system(size: 9)).foregroundStyle(LabTheme.muted) }; Spacer(); Button { store.nextFact() } label: { Image(systemName: "shuffle") }.buttonStyle(.plain).foregroundStyle(LabTheme.muted).help("Another lab fact") } }
    }
}
