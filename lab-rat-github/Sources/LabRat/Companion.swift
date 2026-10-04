import SwiftUI

struct CompanionView: View {
    @ObservedObject var store: LabStore
    var showWorkspace: () -> Void
    var hide: () -> Void
    var body: some View {
        VStack(spacing: 13) {
            HStack { HStack(spacing: 6) { Circle().fill(LabTheme.lime).frame(width: 5, height: 5); Text("BENCH BUDDY").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1.5) }; Spacer(); Button(action: hide) { Image(systemName: "xmark").font(.system(size: 10)) }.buttonStyle(.plain).foregroundStyle(LabTheme.muted).help("Hide companion; reopen from menu bar") }
            TimerRing(fraction: store.runSeconds / store.state.run.progressDuration, size: 107)
            VStack(spacing: 5) { Text(clockText(store.runSeconds)).font(.system(size: 32, weight: .light, design: .monospaced)).monospacedDigit(); Text(store.selected?.title ?? "Ready for a little science?").font(.system(size: 11)).foregroundStyle(LabTheme.muted).lineLimit(1) }
            Button { store.toggleRun() } label: { Label(store.runRunning ? "Pause \(store.state.run.phase.rawValue.lowercased())" : "Start \(store.state.run.phase.rawValue.lowercased())", systemImage: store.runRunning ? "pause.fill" : "play.fill").frame(maxWidth: .infinity) }.buttonStyle(LabButtonStyle(primary: true))
            if let timer = store.activeTimers.first {
                let remaining = timer.remaining(at: store.now)
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Image(systemName: "thermometer.snowflake"); Text(timer.title).lineLimit(1); Spacer(); Text(timer.temperature) }.font(.system(size: 10, weight: .medium))
                    if remaining <= 0 { Text("\(elapsedText(timer.elapsed(at: store.now))) at \(timer.temperature). Still meant to be there?").font(.system(size: 11)).foregroundStyle(LabTheme.amber) }
                    else { Text("\(clockText(remaining)) remaining").font(.system(size: 11, design: .monospaced)).foregroundStyle(LabTheme.lime) }
                }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(LabTheme.bg, in: RoundedRectangle(cornerRadius: 9))
            } else { Text("You handle the science.\nI’ll handle the clock.").font(.system(size: 11)).foregroundStyle(LabTheme.muted).multilineTextAlignment(.center).lineSpacing(3) }
            HStack(spacing: 8) {
                Button(action: showWorkspace) { Label("Workspace", systemImage: "arrow.up.right") }.buttonStyle(LabButtonStyle())
                if store.state.showPI { Button { store.fakeApproval() } label: { Text("PI ✓") }.buttonStyle(LabButtonStyle()).help("Request very fake PI approval") }
            }
            if let toast = store.toast { Text(toast).font(.system(size: 10)).foregroundStyle(LabTheme.lime).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true) }
        }.padding(19).frame(width: 284).background(LabTheme.card).foregroundStyle(LabTheme.white).preferredColorScheme(.dark)
    }
}
