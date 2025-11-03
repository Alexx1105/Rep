//
//  NotionImportPageView.swift
//  MuscleMemory
//
//  Created by alex haidar on 10/26/24.
//

import SwiftUI

struct NotionImportPageView: View {
 
    @State private var maskHeight: CGFloat = 0
    @State private var borderOpacity: Double = 1.0
    @Environment(\.openURL) private var openURLRedirect
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissImporTab
    private var elementOpacityDark: Double { colorScheme == .dark ? 0.1 : 0.5 }
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    @State private var closeView = false
    
    var body: some View {
        
        VStack {
            HStack {
                
                Spacer()
                
            }
            .frame(maxWidth: 370)
         
            
            
            Spacer()
            ZStack(alignment: .center) {
                
                RoundedRectangle(cornerRadius: 30)
               
                    .frame(width: 370, height: 200)
                    .foregroundStyle(Color.white)
                    .opacity(elementOpacityDark)
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.mmDark, lineWidth: 0.2))
                
                HStack(alignment: .top) {
                    VStack(spacing: 10 ) {
                        Text("Import notes from your notion")
                            .font(.system(size: 18))
                            .fontWeight(.medium)
                            .opacity(textOpacity)
                        
                        Text("Grant Notion access to your\naccount to import your notes")
                            .font(.system(size: 16))
                            .fontWeight(.regular)
                            .opacity(textOpacity).opacity(0.8)
                            .padding(.horizontal)
                            Spacer()
                    }.frame(maxHeight: 175)
                       
                        
                }
            
                .padding(.top)
                VStack {
                    Spacer()
                    ZStack {
                        Button {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                if let redirect = URL(string: "https://api.notion.com/v1/oauth/authorize?client_id=138d872b-594c-8050-b985-0037723b58e0&response_type=code&owner=user&redirect_uri=https%3A%2F%2Fnotionauthbridge-rhuwa73w2a-uc.a.run.app%2Fcallback%3Fcode%3DAUTHORIZATION_CODE") {
                                    openURLRedirect(redirect)
                                }
                                
                                
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.gray).opacity(elementOpacityDark)
                                .frame(width: 297, height: 48)
                              
                        }
                        
                        Text("Import page")
                            .opacity(textOpacity)
                            .fontWeight(.medium)
                            .font(.system(size: 18))
                    
                    }
                }.frame(maxHeight: 165)
                 .padding()
            }
            
            Spacer()
           
           
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.mmBackground)
        .navigationBarBackButtonHidden()
        
    }
}

#Preview {
    NotionImportPageView()
}

