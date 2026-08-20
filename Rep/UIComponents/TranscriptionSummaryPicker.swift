import SwiftUI
import SwiftData


struct TranscriptionSummaryPicker: View {
    @Binding var transcriptTab: TrancriptTab
    
    enum TrancriptTab: String {
        case notes
        case transcript
    }
    
    var body: some View {
        ZStack {
            Capsule().frame(width: 200, height: 30).foregroundStyle(Color.mmBackground)
            
            Picker("", selection: $transcriptTab) {
                Text("Notes").tag(TrancriptTab.notes)
                Text("Transcript").tag(TrancriptTab.transcript)
                
            }.pickerStyle(.segmented)
                .frame(width: 200)
        }
    }
}

#Preview {
    TranscriptionSummaryPicker(transcriptTab: .constant(.notes))
}
