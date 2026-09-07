import SwiftUI
import SwiftData
import AVFoundation

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var stats: [ElementStat]

    @AppStorage("soundOn") private var soundOn = true
    @AppStorage("speechOn") private var speechOn = true
    @AppStorage("showPictureHint") private var showPictureHint = true
    @AppStorage(Speaker.voiceDefaultsKey) private var voiceIdentifier = ""

    @State private var confirmReset = false

    /// Read once. Installed voices don't change while the sheet is open, and
    /// speechVoices() is slow enough that calling it per redraw is noticeable.
    private let voices = Speaker.englishVoices()

    private var versionText: String {
        let d = Bundle.main.infoDictionary
        let v = d?["CFBundleShortVersionString"] as? String ?? "?"
        let b = d?["CFBundleVersion"] as? String ?? "?"
        return "Version \(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sound") {
                    Toggle("Sound effects", isOn: $soundOn)
                    Toggle("Read names out loud", isOn: $speechOn)
                }
                if speechOn && !voices.isEmpty {
                    Section {
                        Picker("Voice", selection: $voiceIdentifier) {
                            Text("Australian (default)").tag("")
                            ForEach(voices, id: \.identifier) { voice in
                                Text(Speaker.label(for: voice)).tag(voice.identifier)
                            }
                        }
                    } footer: {
                        Text("More voices, including higher quality ones, can be downloaded in Settings \u{2192} Accessibility \u{2192} Spoken Content \u{2192} Voices. Only voices already on this iPad or iPhone appear here.")
                    }
                }
                Section {
                    Toggle("Show the picture as a clue", isOn: $showPictureHint)
                } footer: {
                    Text("Off makes the symbol rounds harder: the picture only appears once they've answered.")
                }
                Section {
                    Button("Reset progress", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("\(stats.filter(\.isLearned).count) of 118 learned so far.")
                }

                // No parental gate on these links. That is only required in the
                // Kids Category; this ships under Education, where a plain
                // outbound link is fine.
                Section("About") {
                    Link(destination: URL(string: "https://riz.io")!) {
                        Label("Made by Riz Jaimon", systemImage: "person.crop.circle")
                    }
                    Link(destination: URL(string: "https://github.com/rizvie/118-boxes")!) {
                        Label("Source on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    Link(destination: URL(string: "https://riz.io/118-boxes/privacy")!) {
                        Label("Privacy", systemImage: "hand.raised")
                    }
                    Link(destination: URL(string: "https://riz.io/118-boxes/support")!) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                    Text(versionText)
                        .foregroundStyle(Theme.textLo)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: soundOn) { _, on in SoundEngine.shared.enabled = on }
            .onChange(of: speechOn) { _, on in Speaker.shared.enabled = on }
            .onChange(of: voiceIdentifier) { _, _ in
                // Say something so the choice is audible immediately. Magnesium
                // because it's the word that started all this.
                Speaker.shared.preview("Magnesium")
            }
            .alert("Start again?", isPresented: $confirmReset) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    for s in stats { context.delete(s) }
                    try? context.save()
                }
            } message: {
                Text("This clears every element they've learned.")
            }
        }
    }
}
