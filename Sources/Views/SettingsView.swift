import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var stats: [ElementStat]

    @AppStorage("soundOn") private var soundOn = true
    @AppStorage("speechOn") private var speechOn = true
    @AppStorage("showPictureHint") private var showPictureHint = true

    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Sound") {
                    Toggle("Sound effects", isOn: $soundOn)
                    Toggle("Read names out loud", isOn: $speechOn)
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
