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
    
    @AppStorage("frequencyStopIndex") private var frequencyStopIndex: Int = 0
    @ObservedObject public var childQuery = Query.accessQuery
    @Environment(\.dismiss) var dismissControlsTab
    @Environment(\.colorScheme) var colorScheme
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    @Environment(\.modelContext) var modelContextPage
    
    @Query var pageContent: [UserPageContent]
    @Query var pageTitle: [UserPageTitle]
  
    @State var drag: CGFloat = -160
    @State var fullDrag: CGFloat = 0
    @GestureState var fingerTracking: CGFloat = 0
    
    let frequencyStopsPositions: [CGFloat] = [-160, -70, 28, 151]
    let autoDisableStopsPositions: [CGFloat] = [-160, -13, 146]
    fileprivate let frequencyOptions: [FrequencyOption] = [.init(label: "Off", interval: DateComponents(minute: 1)),
                                                           .init(label: "1hr", interval: DateComponents(minute: 60)),
                                                           .init(label: "2.5hrs", interval: DateComponents(hour: 2, minute: 30)),
                                                           .init(label: "3.4hrs", interval: DateComponents(hour: 3, minute: 40))]
   
    
    @State var dragOne: CGFloat = -160
    @State var fullDragOne: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 70) {
            
            HStack(alignment: .top, spacing: 100) {
                
                Button {
                    dismissControlsTab()
                } label: {
                    Image(systemName: "arrow.backward").foregroundStyle(Color.mmDark).padding(8)
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
                    Text("Frequency")
                        .fontWeight(.semibold)
                        .opacity(textOpacity)
                    Spacer()
                }
                .padding(.leading, 15)
                
                HStack(alignment: .top) {
                    Text("Control how often you receive flashcard repetition\nnotifications containing your notes.")
                        .font(.system(size: 16)).lineSpacing(3)
                        .fontWeight(.medium)
                        .opacity(0.25)
                        .padding(.leading, 1)
                }
                
                ZStack(alignment: .top) {
                    
                    Circle().glassEffect()
                        .foregroundStyle(Color.blue)
                        .frame(width: 42, height: 42)
                        .offset(x: fullDrag + drag, y: 9)
                      
                        .gesture(
                            DragGesture()
                            
                                .onChanged { value in
                                    
                                    let proposed = fullDrag + value.translation.width
                                    let clamped = min(max(proposed, frequencyStopsPositions.first!), frequencyStopsPositions.last!)
                                    drag = clamped - fullDrag
                                }
                                .onEnded { _ in
                                    
                                    let endPosition = fullDrag + drag
                                    let nearest = frequencyStopsPositions.min { abs($0 - endPosition) < abs($1 - endPosition) }!

                                    withAnimation(.spring(response: 0.3, dampingFraction: 1)) {
                                        fullDrag = nearest
                                        drag = 0
                                    }
                                    
                                    if let index = frequencyStopsPositions.firstIndex(of: nearest) {
                                       let opt = frequencyOptions[index]
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
                                            
                                                let selectedOption = frequencyOptions[index]
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
                                }).animation(nil, value: fingerTracking)
                    
                    RoundedRectangle(cornerRadius: 50)
                        .frame(width: 370, height: 50)
                        .opacity(0.06)
                        .padding(.top, 5)
                        
                }
                
                .overlay {
                    HStack(spacing: 80) {
                        Image(systemName: "multiply.circle").foregroundStyle(Color.mmDark).offset(x: -10)
                        Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90").foregroundStyle(Color.mmDark).offset(x: -20)
                        Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90").foregroundStyle(Color.mmDark).offset(x: -23)
                        Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90").foregroundStyle(Color.mmDark)
                    }.offset(y: 3)
                }
                
                HStack(alignment: .top, spacing: 65) {
                    ForEach(frequencyOptions) { frequencyOption in
                        Text(frequencyOption.label)
                            .fontWeight(.semibold)
                            .opacity(textOpacity)
                    }
                }
            }
            
            Spacer()
            VStack(spacing: 5) {
                
                HStack(alignment: .top) {
                    Text("Auto disable after ")
                        .fontWeight(.semibold)
                        .opacity(textOpacity)
                    
                    Spacer()
                }
                .padding(.leading, 15)
                
                HStack(alignment: .top) {
                    Text(" MuscleMemory will reset after a full iteration over\n this notion page and repeat again unless one these\n settings are enabled.")
                        .font(.system(size: 16)).lineSpacing(3)
                        .fontWeight(.medium)
                        .opacity(0.25)
                        .padding(.leading, 1)
                }
                
                ZStack {
                    VStack {
                        ZStack {
                            
                            Circle().glassEffect()
                                .foregroundStyle(Color.blue)
                                .frame(width: 42, height: 42)
                                .offset(x: fullDragOne + dragOne, y: 0)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            
                                            let proposed = fullDragOne + value.translation.width
                                            let clamped = min(max(proposed, autoDisableStopsPositions.first!), autoDisableStopsPositions.last!)
                                            dragOne = clamped - fullDragOne
                                        }
                                        .onEnded { _ in
                                            
                                            let endPosition = fullDragOne + dragOne
                                            let nearest = autoDisableStopsPositions.min { abs($0 - endPosition) < abs($1 - endPosition) }!
                                            
                                            
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                                fullDragOne = nearest
                                                dragOne = 0
                                            }
                                            
                                            
                                            //TO-DO: add functionality when we can confirm server iterates element collections repeatibly
                                            
                                            
                                        })
                            
                            
                            RoundedRectangle(cornerRadius: 50)
                                .frame(width: 370, height: 50)
                                .opacity(0.06)
                        }
                        HStack(alignment: .top, spacing: 110) {
                            Text("Off")
                                .fontWeight(.semibold)
                                .opacity(textOpacity)
                            
                            Text("24hrs")
                                .fontWeight(.semibold)
                                .opacity(textOpacity)
                            
                            Text("48hrs")
                                .fontWeight(.semibold)
                                .opacity(textOpacity)
                            
                        }
                        
                        .overlay {
                            
                            HStack(spacing: 140) {
                                Image(systemName: "multiply.circle").foregroundStyle(Color.mmDark).offset(x: -10)
                                Image(systemName: "timer").foregroundStyle(Color.mmDark).offset(x: -23)
                                Image(systemName: "timer").foregroundStyle(Color.mmDark).offset(x: -23)
                                
                            }.offset(x: 9, y: -41)
                        }
                        
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.mmBackground)
        .navigationBarBackButtonHidden()
    }
}


#Preview {
    DynamicRepControlsView()
}


