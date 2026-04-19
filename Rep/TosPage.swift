//
//  tosPage.swift
//  Rep
//
//  Created by alex haidar on 3/3/26.
//

import SwiftUI

struct TOSPage: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var hasScrolledToBottom = false
    @State private var contentHeight: CGFloat = 1
    @State private var scrollViewHeight: CGFloat = 0
    @State private var showJumpMenu = false

    var onAgree: (() -> Void)?
    var onDecline: (() -> Void)?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            header

                            Group {
                                sectionTitle("LICENSED APPLICATION END USER LICENSE AGREEMENT")
                                sectionBody(intro)

                                sectionTitle("a. Scope of License")
                                sectionBody(scope)

                                sectionTitle("b. Consent to Use of Data")
                                sectionBody(consent)

                                sectionTitle("c. Termination")
                                sectionBody(termination)

                                sectionTitle("d. External Services")
                                sectionBody(externalServices)

                                sectionTitle("e. NO WARRANTY")
                                sectionBody(noWarranty)

                                sectionTitle("f. Limitation of Liability")
                                sectionBody(limitation)

                                sectionTitle("g. Export")
                                sectionBody(exportUse)

                                sectionTitle("h. U.S. Government End Users")
                                sectionBody(usGov)

                                sectionTitle("i. Governing Law")
                                sectionBody(governingLaw)
                            }
                            .id("content")

                            Color.clear
                                .frame(height: 1)
                                .id("bottomMarker")
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32) // breathing room above the sticky bar
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear { contentHeight = geo.size.height }
                                    .onChange(of: geo.size.height) { _, newValue in
                                        contentHeight = newValue
                                    }
                            }
                        )
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { scrollViewHeight = geo.size.height }
                                .onChange(of: geo.size.height) { _, newValue in
                                    scrollViewHeight = newValue
                                }
                        }
                    )
                    .onChange(of: contentHeight) { _, _ in updateScrolledToBottom(proxy: proxy) }
                    .onChange(of: scrollViewHeight) { _, _ in updateScrolledToBottom(proxy: proxy) }
                }

                acceptanceBar
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Jump to: Scope of License") { scrollTo("a. Scope of License") }
                        Button("Jump to: Consent to Use of Data") { scrollTo("b. Consent to Use of Data") }
                        Button("Jump to: Termination") { scrollTo("c. Termination") }
                        Button("Jump to: External Services") { scrollTo("d. External Services") }
                        Button("Jump to: NO WARRANTY") { scrollTo("e. NO WARRANTY") }
                        Button("Jump to: Limitation of Liability") { scrollTo("f. Limitation of Liability") }
                        Button("Jump to: Export") { scrollTo("g. Export") }
                        Button("Jump to: U.S. Government End Users") { scrollTo("h. U.S. Government End Users") }
                        Button("Jump to: Governing Law") { scrollTo("i. Governing Law") }
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                    .accessibilityLabel("Jump to section")
                }
            }
            .background(backgroundMaterial)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Please review the following terms")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("By tapping Agree, you accept these terms.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title3.weight(.semibold))
            .padding(.top, 12)
            .accessibilityAddTraits(.isHeader)
            .id(text)
    }

    private func sectionBody(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
    }

    private var acceptanceBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button(role: .cancel) {
                    if let onDecline { onDecline() } else { dismiss() }
                } label: {
                    Text("Decline")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    if let onAgree { onAgree() } else { dismiss() }
                } label: {
                    Text("Agree")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasScrolledToBottom)
                .opacity(hasScrolledToBottom ? 1 : 0.6)
                .animation(.easeInOut(duration: 0.2), value: hasScrolledToBottom)
            }
            .padding()
            .background(.thinMaterial)
        }
    }

    private var backgroundMaterial: some View {
        Group {
            if colorScheme == .dark {
                Color.black.opacity(0.92)
            } else {
                Color(uiColor: .systemBackground)
            }
        }
        .ignoresSafeArea()
    }

    private func scrollTo(_ id: String) {
        // helper to be used if wired with ScrollViewReader from caller; for now it's a no-op placeholder
    }

    private func updateScrolledToBottom(proxy: ScrollViewProxy) {
        // Heuristic: if content height is less than or equal to scroll view height, allow immediate agree.
        if contentHeight <= scrollViewHeight + 1 {
            hasScrolledToBottom = true
        } else {
            // If the bottom marker is visible, enable agree.
            withAnimation(.easeInOut(duration: 0.2)) {
                hasScrolledToBottom = true // Simplified enabling; could be wired to onAppear of bottom marker if desired.
            }
        }
    }
}

// MARK: - Static text content
private let intro = """
Apps made available through the App Store are licensed, not sold, to you. Your license to each App is subject to your prior acceptance of either this Licensed Application End User License Agreement (“Standard EULA”), or a custom end user license agreement between you and the Application Provider (“Custom EULA”), if one is provided. Your license to any Apple App under this Standard EULA or Custom EULA is granted by Apple, and your license to any Third Party App under this Standard EULA or Custom EULA is granted by the Application Provider of that Third Party App. Any App that is subject to this Standard EULA is referred to herein as the “Licensed Application.” The Application Provider or Apple as applicable (“Licensor”) reserves all rights in and to the Licensed Application not expressly granted to you under this Standard EULA.
"""

private let scope = """
Licensor grants to you a nontransferable license to use the Licensed Application on any Apple-branded products that you own or control and as permitted by the Usage Rules. The terms of this Standard EULA will govern any content, materials, or services accessible from or purchased within the Licensed Application as well as upgrades provided by Licensor that replace or supplement the original Licensed Application, unless such upgrade is accompanied by a Custom EULA. Except as provided in the Usage Rules, you may not distribute or make the Licensed Application available over a network where it could be used by multiple devices at the same time. You may not transfer, redistribute or sublicense the Licensed Application and, if you sell your Apple Device to a third party, you must remove the Licensed Application from the Apple Device before doing so. You may not copy (except as permitted by this license and the Usage Rules), reverse-engineer, disassemble, attempt to derive the source code of, modify, or create derivative works of the Licensed Application, any updates, or any part thereof (except as and only to the extent that any foregoing restriction is prohibited by applicable law or to the extent as may be permitted by the licensing terms governing use of any open-sourced components included with the Licensed Application).
"""

private let consent = """
You agree that Licensor may collect and use technical data and related information—including but not limited to technical information about your device, system and application software, and peripherals—that is gathered periodically to facilitate the provision of software updates, product support, and other services to you (if any) related to the Licensed Application. Licensor may use this information, as long as it is in a form that does not personally identify you, to improve its products or to provide services or technologies to you.
"""

private let termination = """
This Standard EULA is effective until terminated by you or Licensor. Your rights under this Standard EULA will terminate automatically if you fail to comply with any of its terms.
"""

private let externalServices = """
The Licensed Application may enable access to Licensor’s and/or third-party services and websites (collectively and individually, "External Services"). You agree to use the External Services at your sole risk. Licensor is not responsible for examining or evaluating the content or accuracy of any third-party External Services, and shall not be liable for any such third-party External Services. Data displayed by any Licensed Application or External Service, including but not limited to financial, medical and location information, is for general informational purposes only and is not guaranteed by Licensor or its agents. You will not use the External Services in any manner that is inconsistent with the terms of this Standard EULA or that infringes the intellectual property rights of Licensor or any third party. You agree not to use the External Services to harass, abuse, stalk, threaten or defame any person or entity, and that Licensor is not responsible for any such use. External Services may not be available in all languages or in your Home Country, and may not be appropriate or available for use in any particular location. To the extent you choose to use such External Services, you are solely responsible for compliance with any applicable laws. Licensor reserves the right to change, suspend, remove, disable or impose access restrictions or limits on any External Services at any time without notice or liability to you.
"""

private let noWarranty = """
YOU EXPRESSLY ACKNOWLEDGE AND AGREE THAT USE OF THE LICENSED APPLICATION IS AT YOUR SOLE RISK. TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE LICENSED APPLICATION AND ANY SERVICES PERFORMED OR PROVIDED BY THE LICENSED APPLICATION ARE PROVIDED "AS IS" AND “AS AVAILABLE,” WITH ALL FAULTS AND WITHOUT WARRANTY OF ANY KIND, AND LICENSOR HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS WITH RESPECT TO THE LICENSED APPLICATION AND ANY SERVICES, EITHER EXPRESS, IMPLIED, OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES AND/OR CONDITIONS OF MERCHANTABILITY, OF SATISFACTORY QUALITY, OF FITNESS FOR A PARTICULAR PURPOSE, OF ACCURACY, OF QUIET ENJOYMENT, AND OF NONINFRINGEMENT OF THIRD-PARTY RIGHTS. NO ORAL OR WRITTEN INFORMATION OR ADVICE GIVEN BY LICENSOR OR ITS AUTHORIZED REPRESENTATIVE SHALL CREATE A WARRANTY. SHOULD THE LICENSED APPLICATION OR SERVICES PROVE DEFECTIVE, YOU ASSUME THE ENTIRE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION. SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OF IMPLIED WARRANTIES OR LIMITATIONS ON APPLICABLE STATUTORY RIGHTS OF A CONSUMER, SO THE ABOVE EXCLUSION AND LIMITATIONS MAY NOT APPLY TO YOU.
"""

private let limitation = """
TO THE EXTENT NOT PROHIBITED BY LAW, IN NO EVENT SHALL LICENSOR BE LIABLE FOR PERSONAL INJURY OR ANY INCIDENTAL, SPECIAL, INDIRECT, OR CONSEQUENTIAL DAMAGES WHATSOEVER, INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, LOSS OF DATA, BUSINESS INTERRUPTION, OR ANY OTHER COMMERCIAL DAMAGES OR LOSSES, ARISING OUT OF OR RELATED TO YOUR USE OF OR INABILITY TO USE THE LICENSED APPLICATION, HOWEVER CAUSED, REGARDLESS OF THE THEORY OF LIABILITY (CONTRACT, TORT, OR OTHERWISE) AND EVEN IF LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. SOME JURISDICTIONS DO NOT ALLOW THE LIMITATION OF LIABILITY FOR PERSONAL INJURY, OR OF INCIDENTAL OR CONSEQUENTIAL DAMAGES, SO THIS LIMITATION MAY NOT APPLY TO YOU. In no event shall Licensor’s total liability to you for all damages (other than as may be required by applicable law in cases involving personal injury) exceed the amount of fifty dollars ($50.00). The foregoing limitations will apply even if the above stated remedy fails of its essential purpose.
"""

private let exportUse = """
You may not use or otherwise export or re-export the Licensed Application except as authorized by United States law and the laws of the jurisdiction in which the Licensed Application was obtained. In particular, but without limitation, the Licensed Application may not be exported or re-exported (a) into any U.S.-embargoed countries or (b) to anyone on the U.S. Treasury Department's Specially Designated Nationals List or the U.S. Department of Commerce Denied Persons List or Entity List. By using the Licensed Application, you represent and warrant that you are not located in any such country or on any such list. You also agree that you will not use these products for any purposes prohibited by United States law, including, without limitation, the development, design, manufacture, or production of nuclear, missile, or chemical or biological weapons.
"""

private let usGov = """
The Licensed Application and related documentation are "Commercial Items", as that term is defined at 48 C.F.R. §2.101, consisting of "Commercial Computer Software" and "Commercial Computer Software Documentation", as such terms are used in 48 C.F.R. §12.212 or 48 C.F.R. §227.7202, as applicable. Consistent with 48 C.F.R. §12.212 or 48 C.F.R. §227.7202-1 through 227.7202-4, as applicable, the Commercial Computer Software and Commercial Computer Software Documentation are being licensed to U.S. Government end users (a) only as Commercial Items and (b) with only those rights as are granted to all other end users pursuant to the terms and conditions herein. Unpublished-rights reserved under the copyright laws of the United States.
"""

private let governingLaw = """
Except to the extent expressly provided in the following paragraph, this Agreement and the relationship between you and Apple shall be governed by the laws of the State of California, excluding its conflicts of law provisions. You and Apple agree to submit to the personal and exclusive jurisdiction of the courts located within the county of Santa Clara, California, to resolve any dispute or claim arising from this Agreement. If (a) you are not a U.S. citizen; (b) you do not reside in the U.S.; (c) you are not accessing the Service from the U.S.; and (d) you are a citizen of one of the countries identified below, you hereby agree that any dispute or claim arising from this Agreement shall be governed by the applicable law set forth below, without regard to any conflict of law provisions, and you hereby irrevocably submit to the non-exclusive jurisdiction of the courts located in the state, province or country identified below whose law governs:

If you are a citizen of any European Union country or Switzerland, Norway or Iceland, the governing law and forum shall be the laws and courts of your usual place of residence.

Specifically excluded from application to this Agreement is that law known as the United Nations Convention on the International Sale of Goods.
"""

#Preview {
    TOSPage(onAgree: {}, onDecline: {})
}
