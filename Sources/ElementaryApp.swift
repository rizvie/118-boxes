import SwiftUI
import SwiftData

@main
struct ElementaryApp: App {
    @AppStorage("soundOn") private var soundOn = true
    @AppStorage("speechOn") private var speechOn = true

    var body: some Scene {
        WindowGroup {
            HomeView()
                .onAppear {
                    SoundEngine.shared.enabled = soundOn
                    Speaker.shared.enabled = speechOn
                }
                .onChange(of: soundOn) { _, on in SoundEngine.shared.enabled = on }
                .onChange(of: speechOn) { _, on in Speaker.shared.enabled = on }
        }
        .modelContainer(for: ElementStat.self)
    }
}
