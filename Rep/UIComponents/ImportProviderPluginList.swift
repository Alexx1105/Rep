//
//  ImportProviderPluginList.swift
//  Rep
//
//  Created by alex haidar on 10/4/26.
//
import SwiftUI
import Foundation


struct PluginListCard: View {
    var body: some View {
        VStack {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 25) {
                        ForEach(0..<3, id: \.self) { index in
                            PluginListTab(index: index)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 110)
                    .padding(.bottom, 50)
                }

                VStack(spacing: 0) {
                    LinearGradient(
                        stops: [
                            .init(color: Color.mmBackground.opacity(1.00), location: 0.00),
                            .init(color: Color.mmBackground.opacity(0.90), location: 0.30),
                            .init(color: Color.mmBackground.opacity(0.80), location: 0.57),
                            .init(color: Color.clear, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 90)

                    Spacer()

                    LinearGradient(
                        stops: [
                            .init(color: Color.clear, location: 0.00),
                            .init(color: Color.mmBackground.opacity(0.25), location: 0.55),
                            .init(color: Color.mmBackground.opacity(0.70), location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                }
                .allowsHitTesting(false)

                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Import Your Notes")
                                .foregroundStyle(Color.mmDark)
                                .fontWeight(.semibold)
                                .font(.system(size: 16))

                            Text("Connect and add your favorite notes\napp to import notes into Rep.")
                                .font(.system(size: 14))
                                .lineSpacing(1)
                                .fontWeight(.medium)
                                .opacity(0.50)
                        }
                        .padding(.top)

                        Spacer()

                        NavigationLink(value: NavPathItem.pluginStore) {
                            ZStack {
                                Circle()
                                    .frame(width: 45, height: 45)
                                    .foregroundStyle(Color.gray)
                                    .opacity(0.2)

                                Image(systemName: "powerplug.portrait")
                                    .foregroundStyle(Color.mmDark)
                            }
                        }
                        .padding(.trailing)
                    }

                    Spacer()
                }
                .padding(.leading)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(0.9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .glassEffect(.regular, in: .rect(cornerRadius: 30))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.mmDark.opacity(0.16), lineWidth: 1)
            }
        }
        .padding(.horizontal)
    }
}


#Preview {
    PluginListCard()
}
