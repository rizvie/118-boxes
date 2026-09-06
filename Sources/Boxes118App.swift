import SwiftUI
import SwiftData

@main
struct Boxes118App: App {
    @AppStorage("soundOn") private var soundOn = true
    @AppStorage("speechOn") private var speechOn = true
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false

    var body: some Scene {
        WindowGroup {
            HomeView()
                // Once, on first launch. fullScreenCover rather than a sheet so
                // it cannot be swiped away by accident before it is read.
                .fullScreenCover(isPresented: .constant(!hasSeenIntro)) {
                    IntroView { hasSeenIntro = true }
                }
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
