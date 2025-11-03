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

final class Query: ObservableObject {
    @Published var queryID: [String] = []
    static let accessQuery = Query()
}


struct DynamicRepControlsView: View {
    
    @ObservedObject public var childQuery = Query.accessQuery
    @Environment(\.dismiss) var dismissControlsTab
    @Environment(\.colorScheme) var colorScheme
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    @Environment(\.modelContext) var modelContextPage
    
    @Query var pageContent: [UserPageContent]
    @Query var pageTitle: [UserPageTitle]
    
    @State var storeSelectedOption: Int = 0
    @State var storeDisableOption: Int = 0
    
    var body: some View {
        VStack(spacing: 70) {
            
            HStack(alignment: .top, spacing: 68) {
                
                Button {
                    dismissControlsTab()
                } label: {
                    Image(systemName: "arrow.backward").foregroundStyle(Color.mmDark).padding(13)
                }.glassEffect()
                
                VStack(alignment: .trailing ,spacing: 5) {
                    Text("DynamicRep flashcard controls")
                        .fontWeight(.semibold)
                        .opacity(textOpacity)
                    
                    if let title = pageTitle.first?.plain_text {
                        Text("\(title)")
                            .font(.system(size: 16)).lineSpacing(3)
                            .fontWeight(.medium)
                            .opacity(0.25)
                    }
                }
            }.padding(.top, 5)
            
            
            VStack(spacing: 5) {
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5){
                        Text("Frequency")
                            .fontWeight(.semibold)
                            .opacity(textOpacity)
                        
                        Text("Control how often you receive flashcard\nrepetition notifications containing your notes.")
                            .font(.system(size: 16)).lineSpacing(3)
                            .fontWeight(.medium)
                            .opacity(0.25)
                            .padding(.trailing, 15)
                        
                    }
                }
                
                let frequencyOptions: [SliderView.SliderOption] = [
                    .init(label: "Off",     symbolName: "multiply.circle", interval: DateComponents(minute: 1)),
                    .init(label: "1hr",     symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(minute: 60)),
                    .init(label: "2h 30m",  symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(hour: 2, minute: 30)),
                    .init(label: "3h 40m",  symbolName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90", interval: DateComponents(hour: 3, minute: 40))
                ]
                             
                ZStack(alignment: .top) {
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
                    .padding(.horizontal, 10)
                    .onChange(of: storeSelectedOption) {
                        guard storeSelectedOption < frequencyOptions.count else { return }
                        let opt = frequencyOptions[storeSelectedOption]
                        let intervalTitle = pageTitle.first?.plain_text ?? "--"
                        
                        Task {
                            try await Task.sleep(nanoseconds: 500_000_000)
                            startIntervalActivity(label: opt.label, title: intervalTitle)
                            await updateIntervalActivity(label: opt.label, title: intervalTitle)
                        }
                        
                        Task {
                            do {
                                let selectQuery: PostgrestResponse<[QueryIDs]> = try await supabaseDBClient.from("push_tokens").select("id").execute()
                                let result = selectQuery.value
                                let queryID = result.map{String($0.id)}
                                print("ID HERE: \(queryID)")
                                
                                await MainActor.run {
                                    Query.accessQuery.queryID = queryID
                                }
                                
                                let selectedOption = frequencyOptions[storeSelectedOption]
                                let now = Date()
                                let computedOffset: Date? = selectedOption.label == "Off" ? nil : Calendar.current.date(byAdding: selectedOption.interval, to: now)
                                
                                if selectedOption.label == "Off" {
                                    do {
                                        let disable = try await supabaseDBClient.from("push_tokens").update(["offset_date" : "1970-01-01T00:00:00Z"]).in("id", values: queryID).execute()
                                        print("slider off: \(disable)")
                                    } catch {
                                        print("failed to disable: \(error)")
                                    }
                                }
                                
                                do {
                                    let send = try await supabaseDBClient.from("push_tokens").update(["offset_date" : computedOffset]).in("id", values: queryID).execute()
                                    print("OFFSET DATE SENT TO SUPABASE: \(send)")
                                } catch {
                                    print("failed to send offset date to supabase ❗️: \(error)")
                                }
                            } catch {
                                print("failed to query id's from supabase ❌: \(error)")
                            }
                        }
                    }
                }
                
                
                
                HStack {
                    ForEach(frequencyOptions, id: \.label) { opt in
                        Text(opt.label)
                            .fontWeight(.medium)
                            .font(.system(size: 16))
                            .opacity(textOpacity)
                            .frame(maxWidth: .infinity)
                    }
                }.padding(.horizontal, -12)
            }
            
            ZStack {
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Auto disable after ")
                            .fontWeight(.semibold)
                            .opacity(textOpacity)
                        
                        
                        Text("Rep will reset after a full iteration over this\nnotion page and repeat again unless one of\nthese settings are enabled.")
                            .font(.system(size: 16)).lineSpacing(3)
                            .fontWeight(.medium)
                            .opacity(0.25)
                        
                    }.padding(.top, 7)
                        .frame(maxWidth: .infinity)
                        .padding(.trailing, 20)
                    
                    let autoDisableOptions: [SliderView.SliderOption] = [.init(label: "Off", symbolName: "multiply.circle", interval: DateComponents()),
                                                                         .init(label: "24hrs", symbolName: "timer", interval: DateComponents()),
                                                                         .init(label: "48hrs", symbolName: "timer", interval: DateComponents())]    ///add functionality later
                    SliderView(sliderOptions: autoDisableOptions, initialSelectedOption: storeDisableOption) { disable in
                        switch disable {
                        case 0:
                            storeDisableOption = 0
                        case 1:
                            storeDisableOption = 1
                        case 2:
                            storeDisableOption = 2
                        default:
                            break
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 130) {
                                               Text("Off")
                                                   .fontWeight(.medium)
                                                   .font(.system(size: 16))
                                                   .opacity(textOpacity)
                                               
                                               Text("24hrs")
                                                   .fontWeight(.medium)
                                                   .font(.system(size: 16))
                                                   .opacity(textOpacity)
                                               
                                               Text("48hrs")
                                                   .fontWeight(.medium)
                                                   .font(.system(size: 16))
                                                   .opacity(textOpacity)
                                               
                    }.padding(.leading, 15)
                    
                    
                    Spacer()
                    HStack(alignment: .bottom) {
                        
                        Menu {
                            
                            Button(action: {}) { Label("Bottom to top", systemImage: "arrow.uturn.up")}
                            Button(action: {}) { Label("Top to bottom", systemImage: "arrow.uturn.down")}
                            Text("Iterate page from:")
                            
                        } label: {
                            RoundedRectangle(cornerRadius: 50)
                                .frame(width: 122, height: 35)
                                .opacity(0.06)
                            
                                .overlay {
                                    HStack(spacing: 20) {
                                        
                                        Text("Order by")
                                            .fontWeight(.medium)
                                            .opacity(textOpacity)
                                        
                                        Image(systemName: "chevron.up.chevron.down")
                                            .opacity(textOpacity)
                                        
                                    }.padding(.leading, 2)
                                    
                                }.glassEffect()
                                .frame(maxWidth: 170)
                            
                            Spacer()
                            
                        }.buttonStyle(PlainButtonStyle())
                        
                    }.frame(maxHeight: .infinity)
                        .padding(.top, 5)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mmBackground)
        .navigationBarBackButtonHidden()
    }
    
}




#Preview {
    DynamicRepControlsView()
}

