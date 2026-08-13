import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import KimchiKit
import ActivityKit

struct ChatView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var closeChatSheet
    @Environment(\.modelContext) private var context
    
    private var textOpacity: Double { colorScheme == .dark ? 0.8 : 0.8 }
    private var messagePlaceholder: String = "Upload notes or Ask..."
    
    @StateObject private var chatState = Chat.shared
    @State var showFilePicker: Bool = false
    @State var showCameraPicker: Bool = false
    @State var selectedPhotos: [PhotosPickerItem] = []
    @State var showPhotoPicker: Bool = false
    @State private var imageCaptured: UIImage?
    @State var fileUrls: [URL] = []
    @State public var isNewChat: Bool = false
    @State var isGenerating: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isCircleVisible: Bool = false
    @State private var isCirclePulsing: Bool = false
    @State var showEmptyState: Bool = false

    @FocusState private var isChatFocused: Bool
    
    @AppStorage("hasSeenEmptyState") var isEmptyStateSeen: Bool = false


    var body: some View {
        ZStack {
            Color.mmBackground.ignoresSafeArea()
            ScrollViewReader { proxy in
                ScrollView {
                    VStack {
                        Spacer(minLength: 65)
                        
                        if isCircleVisible {
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .frame(width: 18, height: 18)
                                    .opacity(isCirclePulsing ? 1.0 : 0.25)
                                    .scaleEffect(isCirclePulsing ? 1.2 : 0.8)
                                
                                Text("Generating...")
                                    .opacity(isCirclePulsing ? 0.8 : 0.25)
                                    .fontDesign(.rounded)
                                    .fontWeight(.medium)
                                    
                                
                                Spacer()
                            }
                            .padding(.top)
                            .padding(.leading)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                    isCirclePulsing.toggle()
                                }
                            }
                            .onDisappear {
                                isCirclePulsing = false
                            }
                        }
                        
                        ForEach(Chat.shared.responseMessage, id: \.id) { response in
                            Text(response.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading)
                                .font(.system(size: 16)).lineSpacing(3).fontWeight(.medium)
                                .listRowBackground(Color.mmBackground)
                                .lineLimit(nil)
                                .transition(.opacity.combined(with: .blurReplace))
                                .textSelection(.enabled)
                        }.animation(.easeOut(duration: 0.3), value: Chat.shared.responseMessage.count)
                        
                        Spacer(minLength: keyboardHeight > 0 ? keyboardHeight + 150 : 135)
                        Color.clear.frame(height: 1).id("chat-bottom")
                        
                    }.frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    
                }.frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: Chat.shared.responseMessage.last?.text) { _, _ in
                        Task { @MainActor in
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("chat-bottom", anchor: .bottom)
                            }
                        }
                    }
                }
            
            LinearGradient(gradient: Gradient(stops: [.init(color: Color.mmBackground.opacity(0.95), location: 0.02),
                                                      .init(color: Color.mmBackground.opacity(0.80), location: 0.03),
                                                      .init(color: Color.mmBackground.opacity(0.50), location: 0.05),
                                                      .init(color: Color.mmBackground.opacity(0.30), location: 0.10),]), startPoint: .top, endPoint: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .ignoresSafeArea()
            
            LinearGradient(gradient: Gradient(stops: [.init(color: Color.mmBackground.opacity(1.00), location: 0.00),
                                                      .init(color: Color.mmBackground.opacity(1.00), location: 0.05),
                                                      .init(color: Color.mmBackground.opacity(0.30), location: 0.10),
                                                      .init(color: Color.mmBackground.opacity(0.05), location: 0.15),]), startPoint: .bottom, endPoint: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .ignoresSafeArea()
            
            VStack {
                HStack(alignment: .top) {
                    Button {
                        withAnimation { closeChatSheet() }
                    } label: {
                        ZStack {
                            Circle().fill(Color.clear).glassEffect(.regular)
                                .frame(width: 45, height: 45)
                            
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.mmDark)
                                .font(.system(size: 20))
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 25).fill(Color.clear).glassEffect( .regular, in: .rect(cornerRadius: 25))
                            .frame(width: 110, height: 45)
                        
                        HStack {
                            Menu {
                                Button {
                                    
                                } label: {
                                    Label("GPT-5.4 mini", image: "openaiLogo")  //TODO: explain that its faster
                                        .font(.system(size: 5))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                //                                Button {
                                //
                                //                                } label: {
                                //                                    Label("GPT-5.4", image: "")      //TODO: explain that its more detailed, will add support for this model later
                                //                                }
                                
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.mmDark)
                                    .padding()
                            }
                            Button {
                                isNewChat = true
                                Chat.shared.responseMessage.removeAll()
                                
                            } label: {
                                Image(systemName: "pencil.line")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.mmDark)
                                    .padding()
                            }
                        }
                    }
                    
                }.padding(.top)
                    .padding(.horizontal)
                
                
                if !isEmptyStateSeen && Chat.shared.responseMessage.isEmpty {
                    VStack(spacing: 20) {
                        VStack(spacing: 5) {
                            
                            Text("Turn notes, PDFs, and AI chats into spaced repetition flashcards.").font(.headline)
                                .font(.system(size: 20, weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineSpacing(1)
                                .foregroundStyle(Color.mmDark)
                                .padding(.horizontal, 32)
                            
                            Text("Rep adapts your content into passive Live Activity memory drills.").font(.subheadline)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 50)
                        }
                        
                        VStack(spacing: 8) {
                            
                            Text("- Turn this PDF into spaced repetition drills").font(.subheadline)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .opacity(showEmptyState ? 1 : 0)
                                .offset(y: showEmptyState ? 0 : 8)
                                .animation(.easeOut(duration: 0.45).delay(0.10), value: showEmptyState)
                            
                            Text("- Turn my study notes into quick review prompts").font(.subheadline)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .opacity(showEmptyState ? 1 : 0)
                                .offset(y: showEmptyState ? 0 : 8)
                                .animation(.easeOut(duration: 0.45).delay(0.20), value: showEmptyState)
                            
                            Text("- Review onboarding documents throughout the day").font(.subheadline)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .opacity(showEmptyState ? 1 : 0)
                                .offset(y: showEmptyState ? 0 : 8)
                                .animation(.easeOut(duration: 0.45).delay(0.30), value: showEmptyState)
                            
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                    .opacity(showEmptyState ? 1 : 0)
                    .offset(y: showEmptyState ? 0 : 12)
                    .animation(.easeOut(duration: 0.45), value: showEmptyState)
                    .onAppear {
                        guard !isEmptyStateSeen else { return }
                        
                        withAnimation(.easeOut(duration: 0.45)) {
                            showEmptyState = true
                        }
                    }
                }
                 
                
                Spacer(minLength: 60)
                VStack(alignment: .leading, spacing: 20) {
                    TextField(messagePlaceholder, text: $chatState.chat, axis: .vertical)
                        .focused($isChatFocused)
                        .offset(y: -keyboardHeight)
                        .animation(.easeOut(duration: 0.25), value: isChatFocused)
                        .lineLimit(1...10)
                        .autocorrectionDisabled(false)
                        .padding(.horizontal)
                        .fontWeight(.medium)
                        .onSubmit {
                            showEmptyState = false
                            let photos: [PhotosPickerItem] = selectedPhotos
                            Chat.sendChatMessage(userFile: fileUrls.first, context: context, selectedPhotos: photos)
                            isEmptyStateSeen = true
                            isCircleVisible = true
                            isCirclePulsing = true
                            fileUrls.removeAll()
                            selectedPhotos.removeAll()
                            
                        }.onChange(of: Chat.shared.responseMessage.last?.text) { _, newValue in
                            if let presentText = newValue, !presentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                isCircleVisible = false
                                isCirclePulsing = false
                            }
                        }
                    
                    ForEach(fileUrls, id: \.self) { file in
                        ZStack {
                            Capsule()
                                .frame(maxWidth: .infinity, maxHeight: 28)
                                .glassEffect(.regular)
                            
                            HStack(spacing: 5) {
                                Text(file.lastPathComponent).font(Font.system(size: 12))
                                    .truncationMode(.middle)
                                    .fontWeight(.semibold)
                                    .fontDesign(.rounded)
                                
                                Button {
                                    fileUrls.removeAll(where: { $0 == file })
                                } label: {
                                    Image(systemName: "x.circle.fill").fixedSize()
                                        .foregroundStyle(Color.mmDark)
                                }
                            }.padding(6)
                        }.fixedSize()
                    }.offset(y: -keyboardHeight)
                    
                    PhotoPickerList(selectedPhotos: $selectedPhotos, keyboardHeight: keyboardHeight)
                    
                    HStack(alignment: .bottom) {
                        Menu {
                            Button {
                                showPhotoPicker = true
                            } label: {
                                Label("Upload Photo", systemImage: "photo")
                            }.onChange(of: selectedPhotos) {_, newValueItem in
                                
                                Task { @MainActor in
                                    for item in newValueItem {
                                        let transferPhoto: PhotoTransfer? = try await item.loadTransferable(type: PhotoTransfer.self)
                                        let rawImageData: Data? = transferPhoto?.photo
                                        let _ = UIImage(data: rawImageData ?? Data())
                                    }
                                }
                            }
                            
                            Button {
                                showFilePicker = true
                            } label: {
                                Label("Upload File(s)", systemImage: "folder.fill")
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12).frame(maxWidth: 80, maxHeight: 30).opacity(0.2).foregroundStyle(Color.intervalBlue)
                                HStack(spacing: 2) {
                                    Image(systemName: "plus.app").foregroundStyle(Color.intervalBlue)
                                    Text("Upload")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.intervalBlue)
                                }
                            }
                        }
                        
                        Spacer()
                        Button {
                            isEmptyStateSeen = true
                            isCircleVisible = true
                            isCirclePulsing = true
                            
                            let photos: [PhotosPickerItem] = selectedPhotos
                            Chat.sendChatMessage(userFile: fileUrls.first, context: context, selectedPhotos: photos)
                            fileUrls.removeAll()
                            selectedPhotos.removeAll()
                        } label: {
                            ZStack {
                                Circle().fill(Color.mmDark)
                                    .frame(maxWidth: 30, maxHeight: 30)
                                
                                Image(systemName: "arrow.up").foregroundStyle(Color.checkmark)
                                
                            }
                        }.padding(.trailing)
                        
                    }.offset(y: -keyboardHeight)
                }.padding(.leading)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.clear).glassEffect(.regular, in: .rect(cornerRadius: 30))
                        .offset(y: -keyboardHeight)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal))
                    .padding(.bottom)
                
            }
        }.sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedPhotos: $selectedPhotos)
            
        }
        .sheet(isPresented: $showFilePicker) {
            DocPicker(contentType: [.item, .folder], allowMultipleFileSelect: true) { url in
                fileUrls = url
                
            }
        }.onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
            
            if let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = frame.height + 5
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }
}

#Preview {
    ChatView()
}
