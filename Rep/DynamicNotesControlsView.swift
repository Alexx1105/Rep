//
//  DynamicRepControlsView.swift

import SwiftData
import SwiftUI
import KimchiKit
import ActivityKit


fileprivate struct FrequencyOption: Identifiable {
    var id: String { label }
    let label: String
    let interval: DateComponents
    
    init(label: String, interval: DateComponents) {
        self.label = label
        self.interval = interval
    }
}

struct QueryIDs: Codable {
    let id: Int
}

struct Offset: Codable {
    let offset_date: Date
}

struct SliderSelection: Equatable {
    let label: String
    let interval: DateComponents
    
}

struct ClusterPickerView: View {
    enum ClusterPicker: String, CaseIterable {
        case oneCard = "1 card"
        case twoCards = "2 cards"
        case threeCards = "3 cards"
        
        var batchSize: Int {
            switch self {
            case .oneCard:
                return 1
            case .twoCards:
                return 2
            case .threeCards:
                return 3
            }
        }
    }
    
    @Binding public var clusterPicker: ClusterPicker
    
    var body: some View {
        Picker("", selection: $clusterPicker) {
            ForEach(ClusterPicker.allCases, id: \.self) { card in
                Text(card.rawValue).tag(card)
            }
        }.pickerStyle(.segmented)
    }
}

var lastSelected: SliderSelection?

final class Query: ObservableObject {
    @Published var queryID: [String] = []
    static let accessQuery = Query()
}


struct DynamicRepControlsView: View {
    @ObservedObject public var childQuery = Query.accessQuery
    
    @Environment(\.dismiss) var dismissControlsTab
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var modelContextPage
    
    @StateObject var dynamicNotesCoordinator: DynamicNotesCoordinator
    
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    @Query var pageContent: [UserPageContent]
    @Query var pageTitle: [UserPageTitle]
    
    @AppStorage var storeSelectedOption: Int
    @AppStorage var storeSelectedHyperModeOption: Int
    @AppStorage("hypermodetoggle") private var hyperToggleEnabled = false
    @AppStorage("repeattoggle") private var repeatEnabled = true
    @AppStorage("notesOrder") private var notesOrder: NotesConfig.NotesOrder = .asc
    @AppStorage("notesCluster") private var picker: ClusterPickerView.ClusterPicker = .oneCard
    
    init(pageID: String, dataSource: CombinedDataSource) {
        self.pageID = pageID
        self.dataSource = dataSource
        self._storeSelectedOption = AppStorage(wrappedValue: 0, "intervalOption_\(pageID)")
        self._storeSelectedHyperModeOption = AppStorage(wrappedValue: 0, "intervalHyperOption_\(pageID)")
        self._hyperToggleEnabled = AppStorage(wrappedValue: false, "hypermodetoggle_\(pageID)")
        self._dynamicNotesCoordinator = StateObject(wrappedValue: DynamicNotesCoordinator(dataSource: dataSource))
        self._notesOrder = AppStorage(wrappedValue: .asc, "notesOrder_\(pageID)")
        self._picker = AppStorage(wrappedValue: .oneCard, "notesCluster_\(pageID)")
        self._repeatEnabled = AppStorage(wrappedValue: true, "repeattoggle_\(pageID)")
    }
    
    @State var localPage: [String: Date] = [:]          ///acts as local per-page base compute
    
    var pageID: String
    var filterTitle: String {
        return pageTitle.first(where: { $0.pageID == pageID})?.text ?? ""
    }
    
    let dataSource: CombinedDataSource
    
    private func runSliderOperation() {
        dynamicNotesCoordinator.runSliderOperation(localPage: $localPage, hyperToggleEnabled: hyperToggleEnabled,
                                                   storeSelectedOption: storeSelectedOption,
                                                   storeSelectedHyperModeOption: storeSelectedHyperModeOption)
    }
    
    var body: some View {
        VStack(spacing: 50) {
            
            HStack(alignment: .top) {
                
                Button {
                    dismissControlsTab()
                } label: {
                    Image(systemName: "arrow.backward").foregroundStyle(Color.mmDark).padding(17)
                }.glassEffect()
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: -5) {
                    Text("Dynamic notes controls")
                        .fontWeight(.semibold)
                        .opacity(textOpacity)
                    
                    switch dataSource {
                    case .notionContent(_ ):
                        Text(filterTitle)
                            .font(.system(size: 14))
                            .fontWeight(.regular)
                            .truncationMode(.tail)
                            .lineLimit(1)
                            .padding()
                        
                            .background(Capsule()
                                .frame(height: 25)
                                .glassEffect(.regular))
                        
                    case .openaiChatContent(let openAIChat):
                        Text(openAIChat.content)
                            .font(.system(size: 14))
                            .fontWeight(.regular)
                            .truncationMode(.tail)
                            .lineLimit(1)
                            .padding()
                        
                            .background(Capsule()
                                .frame(height: 25)
                                .glassEffect(.regular))
                        
                    case .repDesktopTranscription(let desktopTranscriptionNotes):
                        Text(desktopTranscriptionNotes.fullNotes)
                            .font(.system(size: 14))
                            .fontWeight(.regular)
                            .truncationMode(.tail)
                            .lineLimit(1)
                            .padding()
                        
                            .background(Capsule()
                                .frame(height: 25)
                                .glassEffect(.regular))
                        
                    case .repMobileTranscription(let mobileTranscriptionNotes):
                        Text(mobileTranscriptionNotes.fullNotes)
                            .font(.system(size: 14))
                            .fontWeight(.regular)
                            .truncationMode(.tail)
                            .lineLimit(1)
                            .padding()
                        
                            .background(Capsule()
                                .frame(height: 25)
                                .glassEffect(.regular))
                    }
                }
            }.frame(maxWidth: .infinity)
                .padding(.horizontal)
            
                .padding(.top)
            VStack(spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5){
                        Text("Frequency")
                            .fontWeight(.semibold)
                            .opacity(textOpacity)
                        
                        Text("Control how often you receive flashcard\nrepetition notifications containing your notes.")
                            .font(.system(size: 14)).lineSpacing(3)
                            .fontWeight(.medium)
                            .opacity(0.50)
                            .padding(.trailing, 15)
                        
                    }.padding(.trailing)
                }
                
                ZStack(alignment: .top) {
                    
                    if hyperToggleEnabled {
                        SliderView(sliderOptions: dynamicNotesCoordinator.hyperModeOptions, initialSelectedOption: storeSelectedHyperModeOption) { hyperOption in
                            switch hyperOption {
                            case 0:
                                print("off")
                            case 1:
                                print("10m")
                            case 2:
                                print("30m")
                            case 3:
                                print("45m")
                            default:
                                break
                            }
                            storeSelectedHyperModeOption = hyperOption
                        }
                        
                    } else {
                        SliderView(sliderOptions: dynamicNotesCoordinator.frequencyOptions, initialSelectedOption: storeSelectedOption) { newOptionIndex in
                            switch newOptionIndex {
                            case 0:
                                print("frequency is off")
                            case 1:
                                print("option is 1hr")
                            case 2:
                                print("option 2h 30m")
                            case 3:
                                print("option 3h 40m")
                            default:
                                break
                            }
                            storeSelectedOption = newOptionIndex
                        }
                    }
                }.id(hyperToggleEnabled)
                    .onChange(of: hyperToggleEnabled) { oldValue, newValue in
                        print("hyper mode toggled in controls view: \(newValue)")
                    }
                
                    .padding(.horizontal, 10)
                    .onChange(of: hyperToggleEnabled) { runSliderOperation() }
                    .onChange(of: storeSelectedOption) { runSliderOperation() }    ///defualt mode selected
                    .onChange(of: storeSelectedHyperModeOption) { runSliderOperation() }   ///hyper mode selected
                
                HStack {
                    ForEach(hyperToggleEnabled ? dynamicNotesCoordinator.hyperModeOptions : dynamicNotesCoordinator.frequencyOptions, id: \.label) { opt in
                        Text(opt.label)
                            .fontWeight(.medium)
                            .font(.system(size: 14))
                            .opacity(textOpacity)
                            .frame(maxWidth: .infinity)
                        
                    }
                }.padding(.horizontal, -8)
                
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30, style: .continuous).foregroundStyle(Color.gray).opacity(0.1)
                            .frame(maxWidth: .infinity, maxHeight: .infinity).padding(.bottom)
                            .padding(.horizontal)
                        
                        VStack(spacing: 10) {
                            HStack {
                                HyperToggleCard(isPresented: .constant(true), hyperToggleEnabled: $hyperToggleEnabled).padding(.horizontal)
                            }
                            Divider().padding(.horizontal).padding(.leading)
                            
                            RepeatToggleCard(isPresented: .constant(true), repeatEnabled: $repeatEnabled).padding(.horizontal)
                                .onChange(of: repeatEnabled) { _,newVal in
                                    Task {
                                        await dynamicNotesCoordinator.updateRepeatNotesStatus(repeatEnabled: newVal)
                                    }
                                }.onAppear {
                                    Task {
                                        await dynamicNotesCoordinator.updateRepeatNotesStatus(repeatEnabled: repeatEnabled)
                                    }
                                }
                            
                            Divider().padding(.horizontal).padding(.leading)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Notes Cluster")
                                    .fontWeight(.semibold)
                                    .opacity(textOpacity)
                                    .padding(.leading)
                                
                                Text("Control whether to recieve 1-3 lockscreen\nnotes at a time to display more content at once")
                                    .font(.system(size: 14)).lineSpacing(3)
                                    .fontWeight(.medium)
                                    .opacity(0.50)
                                    .padding(.leading)
                                
                                ClusterPickerView(clusterPicker: $picker)
                                    .onChange(of: picker) {
                                        Task {
                                            await dynamicNotesCoordinator.updateNotesCluster(batchSize: picker.batchSize)
                                        }
                                    }
                                    .padding(.horizontal)
                            }.padding(.horizontal)
                            
                            
                            
                            Spacer()
                            
                            HStack {
                                Menu {
                                    Button {
                                        notesOrder = .desc
                                        
                                    } label: { Label("Descending", systemImage: "arrow.turn.right.down").foregroundStyle(Color.mmDark) }
                                    Button {
                                        notesOrder = .asc
                                    } label: { Label("Ascending", systemImage: "arrow.turn.left.up").foregroundStyle(Color.mmDark) }
                                } label: {
                                    ZStack {
                                        Capsule().frame(width: 115, height: 35).fixedSize()
                                            .foregroundStyle(Color.clear).glassEffect(.regular)
                                        
                                        HStack(spacing: 15) {
                                            Text("Order").fontWeight(.semibold)
                                            Image(systemName: "arrow.up.arrow.down.circle.fill")
                                        }.foregroundStyle(Color.mmDark)
                                    }
                                }.onChange(of: notesOrder) { _,_ in
                                    Task {
                                        await dynamicNotesCoordinator.updateNotesOrdering(ordering: notesOrder)
                                    }
                                }
                                Spacer()
                            }.padding(.leading, 30)
                        
                            Spacer()
                        }.padding(.top)
                    }
                }.padding(.top)
                    .padding(.bottom)
                
            }.padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mmBackground)
        .navigationBarBackButtonHidden()
    }
}



#Preview {
    DynamicRepControlsView(pageID: "", dataSource: .notionContent(UserPageTitle(pageID: "", text: "")))
}
