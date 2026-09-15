//
//  SettingsView.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/23/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissSettingsTab
    @Environment(\.modelContext) var context
    
    @EnvironmentObject private var paymentStore: PaymentStore
    
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    
    @AppStorage("appearence.toggle") private var toggleEnabled = false
    @AppStorage("hypermodetoggle") private var hyperToggleEnabled: Bool = false
    @AppStorage("desktop.pollingEnabled") private var isPollingEnabled = false
    
    @ObservedObject var AutoSync = SyncController.shared
    
    @State private var isPresented: Bool = false
    @State private var isPopoverPresented: Bool = false
    @State private var billingPlanTab: PaymentPricingCoordinator.BillingInterval = .monthly
    
    
    var body: some View {
        
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        
                        HStack {
                            Text("Settings")
                                .fontWeight(.semibold)
                                .opacity(textOpacity)
                                .padding(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                            
                            Button("Upgrade Plan") {
                                self.isPresented = true
                            }
                            .fontWeight(.semibold)
                            .font(.system(size: 10))
                            .buttonStyle(.glass)
                            .padding(.trailing, 7)
                            
                            PaymentMenuCard(isPresented: $isPresented, billingPlanTab: $billingPlanTab)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 150)
                        .padding(.bottom)
                        
                        
                        VStack(alignment: .leading) {
                            Spacer(minLength: 20)
                            HStack(alignment: .top) {
                                Text("Terms Of Use")
                                    .fontWeight(.semibold)
                                    .opacity(textOpacity)
                                    .padding(.top, 3)
                                    .padding(.leading)
                                
                                Spacer()
                                
                                NavigationLink(destination: TOSPage()) {
                                    HStack(spacing: 5) {
                                        Text("Terms Of Use ")
                                        
                                        Image(systemName: "arrow.up.right.circle")
                                    }
                                    .font(.system(size: 10))
                                    .fontWeight(.medium)
                                    .foregroundStyle(.gray)
                                }
                                .buttonStyle(.glass)
                                .padding(.trailing)
                                
                            }.padding(.vertical, 10)
                            
                            Divider()
                            
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "circle.lefthalf.filled.inverse").offset(y: 7)
                                    .scaledToFit()
                                    .frame(width: 15, height: 15)
                                    .opacity(textOpacity)
                                
                                Toggle("Appearance", isOn: $toggleEnabled)
                                    .fontWeight(.semibold)
                                    .opacity(textOpacity)
                                    .tint(.blue)
                                
                            }.frame(maxWidth: .infinity)
                                .padding(.horizontal)
                            
                            
                            Text("Toggle appearence to have\ndark mode as the standard")
                                .font(.system(size: 14)).lineSpacing(3)
                                .fontWeight(.medium)
                                .opacity(0.50)
                                .padding(.leading)
                            
                            
                            Divider()
                            
                            HStack(alignment: .top ) {
                                HStack(spacing: 10) {
                                    
                                    Image("notionLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 15, height: 15)
                                        .opacity(textOpacity)
                                    
                                    Toggle("Auto Sync", isOn: $AutoSync.isAutoSync)
                                        .disabled(!paymentStore.hasPaidAccess)
                                        .fontWeight(.semibold)
                                        .opacity(textOpacity)
                                        .tint(.blue)
                                        .onChange(of: AutoSync.isAutoSync) { _, newValue in
                                            print("auto sync toggled in settings view: \(newValue)")
                                        }
                                    
                                }.frame(alignment: .leading)
                                
                            }.frame(maxWidth: .infinity)
                                .padding(.horizontal)
                            
                            Text("Toggle Auto Sync to enable on-demand\nsyncing between your Notion and your\nimported notes")
                                .font(.system(size: 14)).lineSpacing(3)
                                .fontWeight(.medium)
                                .opacity(0.50)
                                .padding(.leading)
                            
                            Divider().padding(.bottom, 7)
                            HStack(alignment: .top ) {
                                HStack(spacing: 10) {
                                    Image(systemName: "macbook.and.iphone").font(.system(size: 15))
                                        .opacity(textOpacity)
                                    
                                    Toggle("Rep Desktop", isOn: $isPollingEnabled)
                                        .fontWeight(.semibold)
                                        .opacity(textOpacity)
                                        .tint(.blue)
                                        .onChange(of: isPollingEnabled) { _, enabled in
                                            if enabled {
                                                RepDesktopPoller.shared.startPollingNotes(context: context)
                                            } else {
                                                RepDesktopPoller.shared.stopPollingNotes()
                                            }
                                        }
                                    
                                }.frame(alignment: .leading)
                                
                            }.frame(maxWidth: .infinity)
                                .padding(.horizontal)
                            
                            
                            Text("Toggle to receive transcripts and notes from\nmeetings recorded with Rep Desktop on your\nMac, directly on your iPhone.")
                                .font(.system(size: 14)).lineSpacing(3)
                                .fontWeight(.medium)
                                .opacity(0.50)
                                .padding(.leading)
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Spacer(minLength: 20)
                                Text("Danger Zone")
                                    .fontWeight(.semibold)
                                    .opacity(textOpacity)
                                    .padding(.top)
                                
                                HStack {
                                    Text("Log out of Rep account and\nreset in-app purchase tiers")
                                        .font(.system(size: 14)).lineSpacing(3)
                                        .fontWeight(.medium)
                                        .opacity(0.50)
                                    
                                    Spacer()
                                    
                                    Button {
                                        isPopoverPresented.toggle()
                                    } label: {
                                        ZStack {
                                            Capsule(style: .continuous).frame(width: 100, height: 30)
                                                .foregroundStyle(Color.red)
                                                .opacity(0.2)
                                            
                                            Text("Log Out")
                                                .fontWeight(.semibold)
                                                .font(.system(size: 10))
                                                .foregroundStyle(Color.red)
                                        }
                                    }.padding(.trailing)
                                        .alert("Confirm Logout", isPresented: $isPopoverPresented) {
                                            Button("Delete", role: .destructive) {
                                                paymentStore.resetForSignOut()
                                            }
                                            
                                            Button("Cancel", role: .cancel) {}
                                        }
                                }
                                
                            }.padding(.leading)
                            
                        }.padding(.top)
                    }.padding(.top)
                }
                
                LinearGradient(gradient: Gradient(stops: [.init(color: Color.mmBackground.opacity(0.95), location: 0.02),
                                                          .init(color: Color.mmBackground.opacity(0.80), location: 0.03),
                                                          .init(color: Color.mmBackground.opacity(0.50), location: 0.07),
                                                          .init(color: Color.clear, location: 0.10),]), startPoint: .top, endPoint: .bottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .ignoresSafeArea()
                
                
                
                LinearGradient(gradient: Gradient(stops: [.init(color: Color.mmBackground, location: 0.00),
                                                          .init(color: Color.mmBackground.opacity(1.00), location: 0.05),
                                                          .init(color: Color.mmBackground.opacity(0.30), location: 0.10),
                                                          .init(color: Color.mmBackground.opacity(0.05), location: 0.15),]), startPoint: .bottom, endPoint: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .ignoresSafeArea()
                
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.mmBackground)
        }
    }
}



#Preview {
    SettingsView()
        .environment(\.sizeCategory, .large)
        .environmentObject(PaymentStore())
}

