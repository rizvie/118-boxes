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
                    Text("Off makes the symbol rounds harder: the picture only appears once he's answered.")
                }
                Section {
                    Button("Reset progress", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("\(stats.filter(\.isLearned).count) of 118 learned so far.")
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
                // because it's the word he couldn't say.
                Speaker.shared.preview("Magnesium")
            }
            .alert("Start again?", isPresented: $confirmReset) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    for s in stats { context.delete(s) }
                    try? context.save()
                }
            } message: {
                Text("This clears every element he's learned.")
            }
        }
    }
}
