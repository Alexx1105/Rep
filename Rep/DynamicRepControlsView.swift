//
//  DynamicRepControlsView.swift

import SwiftData
import Supabase
import OSLog
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


var lastSelected: SliderSelection?

final class Query: ObservableObject {
    @Published var queryID: [String] = []
    static let accessQuery = Query()
}


func staggerDateComponents(components: DateComponents, add: Int = 1, multiplier: Int) -> DateComponents {
    var new = DateComponents()
    
    new.hour = (components.hour ?? 0) * multiplier
    new.minute = (components.minute ?? 0) * multiplier
    return new
}



struct DynamicRepControlsView: View {
    
    let frequencyOptions: [SliderView.SliderOption] = [
        .init(label: "Off",     symbolName: "multiply.circle", interval: DateComponents(minute: 1)),
        .init(label: "1hr",     symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(minute: 60)),
        .init(label: "2h 30m",  symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(hour: 2, minute: 30)),
        .init(label: "3h 40m",  symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(hour: 3, minute: 40))
    ]
    
    let hyperModeOptions: [SliderView.SliderOption] = [
        .init(label: "Off",     symbolName: "multiply.circle", interval: DateComponents(minute: 1)),
        .init(label: "10m",     symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(minute: 10)),
        .init(label: "30m",  symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(minute: 30)),
        .init(label: "45m",  symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(minute: 45))
    ]
    
    @AppStorage("hypermodetoggle") private var hyperToggleEnabled = false
    
    @MainActor
    func runSliderOperation() {
        let mode = hyperToggleEnabled ? hyperModeOptions : frequencyOptions
        let selectedIndex = hyperToggleEnabled ? storeSelectedHyperModeOption : storeSelectedOption
        guard selectedIndex < mode.count else { return }
        let opt = mode[selectedIndex]
        let intervalTitle = filterTitle
        
        Task {
            try await Task.sleep(nanoseconds: 500_000_000)
            startIntervalActivity(label: opt.label, title: intervalTitle)
            await updateIntervalActivity(label: opt.label, title: intervalTitle)
        }
        
        @MainActor
        func sliderChangeTask() {           ///fixes prev slider state being retained on slider change
            currentTask?.cancel()
            
            localPage[filterPageID] = Date()
            
            let basePerPage = localPage[filterPageID]!
            let selectedOption = mode[selectedIndex]
            let pageID = filterPageID
            let pageContentID = pageContent.first?.userPageId ?? ""
            
            currentTask = Task {
                await scheduleTask(selectedOption: selectedOption, pageID: pageID, pageContentID: pageContentID, basePerPage: basePerPage)
            }
        }
        
        func scheduleTask(selectedOption: SliderView.SliderOption, pageID: String, pageContentID: String, basePerPage: Date) async {
            
            do {
                let selectQuery: PostgrestResponse<[QueryIDs]> = try await supabaseDBClient.from("push_tokens").select("id").eq("page_id", value: pageID).execute()
                let result = selectQuery.value
                let queryID = result.map{String($0.id)}
                print("ID HERE: \(queryID)")
                
                await MainActor.run {
                    Query.accessQuery.queryID = queryID
                }
                
                let rows: Int = 5
                let base = basePerPage
                
                for i in stride(from: 0, to: queryID.count, by: rows) {
                    
                    if Task.isCancelled { return }
                    print("prev task cancelled")
                    
                    let stagger = (i / rows) + 1
                    let scaledOffsets = staggerDateComponents(components: selectedOption.interval, multiplier: stagger)
                    
                    let computedOffset: Date? = selectedOption.label == "Off" ? nil : Calendar.current.date(byAdding: scaledOffsets, to: base)
                    
                    let batch = min(i + rows, queryID.count)
                    let idsPerBatch = Array(queryID[i..<batch])
                    
                    do {
                        let send = try await supabaseDBClient.from("push_tokens").update(["offset_date" : computedOffset]).in("id", values: idsPerBatch).in("page_id", values: [pageID]).execute()
                        print("OFFSET DATE SENT TO SUPABASE: \(send)")
                        print("page ids here: \(pageID)")
                    } catch {
                        print("failed to send offset timestamps to supabase ❗️: \(error.localizedDescription)")
                    }
                }
            } catch {
                print("failed to query id's from supabase ❌: \(error.localizedDescription)")
            }
        }
        sliderChangeTask()
    }
    
    @ObservedObject public var childQuery = Query.accessQuery
    @Environment(\.dismiss) var dismissControlsTab
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var modelContextPage
    
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    @Query var pageContent: [UserPageContent]
    @Query var pageTitle: [UserPageTitle]
    
    @AppStorage var storeSelectedOption: Int
    @AppStorage var storeSelectedHyperModeOption: Int
    
    init(pageID: String) {
        self.pageID = pageID
        self._storeSelectedOption = AppStorage(wrappedValue: 0, "intervalOption_\(pageID)")
        self._storeSelectedHyperModeOption = AppStorage(wrappedValue: 0, "intervalHyperOption_\(pageID)")
    }
    
    @AppStorage("disableOption") var storeDisableOption: Int = 0
    
    @State var localPage: [String: Date] = [:]          ///acts as local per-page base compute
    @State private var currentTask: Task<Void, Never>?
    
    
    var pageID: String
    var filterTitle: String {
        return pageTitle.first(where: { $0.titleID == pageID})?.plain_text ?? ""
    }
    
    var filterPageID: String {
        return pageTitle.first(where: { $0.titleID == pageID})?.titleID ?? ""
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
                    Text("DynamicRep flashcard controls")
                        .fontWeight(.semibold)
                        .opacity(textOpacity)
                    
                    
                    Text(filterTitle)
                        .font(.system(size: 14))
                        .fontWeight(.regular)
                        .truncationMode(.tail)
                        .lineLimit(1)
                        .padding()
                    
                        .background(Capsule()
                            .frame(height: 25)
                            .glassEffect(.regular))
                     
                    
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
                        
                        SliderView(sliderOptions: hyperModeOptions, initialSelectedOption: storeSelectedHyperModeOption) { hyperOption in
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
                        SliderView(sliderOptions: frequencyOptions, initialSelectedOption: storeSelectedOption) { newOptionIndex in
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
                    ForEach(hyperToggleEnabled ? hyperModeOptions : frequencyOptions, id: \.label) { opt in
                        Text(opt.label)
                            .fontWeight(.medium)
                            .font(.system(size: 14))
                            .opacity(textOpacity)
                            .frame(maxWidth: .infinity)
                           
                    }
                }.padding(.horizontal, -8)
                
                HyperToggleCard(isPresented: .constant(true))
                    .padding(.top)
                
            }.frame(alignment: .center)
             .padding(.top)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mmBackground)
        .navigationBarBackButtonHidden()
    }
}



#Preview {
    DynamicRepControlsView(pageID: "")
}

