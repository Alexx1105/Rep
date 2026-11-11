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
    private var canSendMessage: Bool {
        !isGenerating && !chatState.chat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    @StateObject private var chatState = Chat.shared
    
    @State var showFilePicker: Bool = false
    @State var showCameraPicker: Bool = false
    @State var selectedPhotos: [PhotosPickerItem] = []
    @State var showPhotoPicker: Bool = false
    @State private var imageCaptured: UIImage?
    @State var fileUrls: [URL] = []
    @State public var isNewChat: Bool = false
    @State var isGenerating: Bool = false
    @State private var chatError: String?
    @State private var keyboardHeight: CGFloat = 0
    @State private var isShimmerTextVisible: Bool = false
    @State private var isTextShimmering: Bool = false
    @State var showEmptyState: Bool = false
    @State var task: Task<Void, Never>?
    @State var isMoreCreditsNeeded: Bool = false
    
    @AppStorage("selectedAiProviderID") private var selectedAiProviderID: String = "local"
    private var selectedModel: AIModelProviders {
        AIModelProviders.all.first { $0.id == selectedAiProviderID }
        ?? AIModelProviders.all[0]
    }
    
    @FocusState private var isChatFocused: Bool
    
    
    struct AIModelProviders: Identifiable, Hashable {
        let id: String
        let name: String
        let image: String
        var isSystemImage: Bool = false
        
        static let all: [AIModelProviders] = [
            AIModelProviders(id: "mini", name: "GPT-6.1 luna", image: "openaiLogo", isSystemImage: false),
            AIModelProviders(id: "full", name: "GPT-6.1 sol", image: "openaiLogo", isSystemImage: false),
            AIModelProviders(id: "local", name: "Apple Intelligence (local)", image: "apple.intelligence", isSystemImage: true)
        ]
    }
    
    
    var body: some View {
        ZStack {
            Color.mmBackground.ignoresSafeArea()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        Spacer(minLength: 65)
                        
                        ForEach(Chat.shared.responseMessage, id: \.id) { response in
                            Text(response.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading)
                                .font(.system(size: 16)).lineSpacing(3).fontWeight(.medium)
                                .listRowBackground(Color.mmBackground)
                                .lineLimit(nil)
                                .textSelection(.enabled)
                                .tint(.white)
                                .transition(
                                    .opacity.combined(with: .move(edge: .bottom))
                                )
                        }
                        
                        if isShimmerTextVisible {
                            HStack(alignment: .top, spacing: 10) {
                                ShimmerText(text: "Generating notes ...")
                                    .fontDesign(.rounded)
                                    .fontWeight(.medium)
                                
                                Spacer()
                            }
                            .padding(.top)
                            .padding(.leading)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                    isTextShimmering.toggle()
                                }
                            }
                            .onDisappear {
                                isTextShimmering = false
                            }
                        }
                        
                        Spacer(minLength: keyboardHeight > 0 ? keyboardHeight + 150 : 135)
                        Color.clear.frame(height: 1).id("chat-bottom")
                        
                    }.frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    
                }.frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: Chat.shared.responseMessage.last?.text) { _, _ in
                        
                        guard task == nil else { return }
                        
                        task = Task { @MainActor in
                            guard !Task.isCancelled else { return }
                            
                            try? await Task.sleep(for: .milliseconds(50))
                            guard !Task.isCancelled else {
                                task = nil
                                return
                            }
                            withAnimation(.linear(duration: 0.3)) {
                                proxy.scrollTo("chat-bottom", anchor: .bottom)
                            }
                            task = nil
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
                                Picker("Model", selection: $selectedAiProviderID) {
                                    ForEach(AIModelProviders.all) { model in
                                        Group {
                                            if model.isSystemImage {
                                                Label(model.name, systemImage: model.image)
                                            } else {
                                                Label(model.name, image: model.image)
                                                    .font(.system(size: 5))
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                        .tag(model.id)
                                    }
                                }
                                .pickerStyle(.inline)
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
                
                
                if Chat.shared.responseMessage.isEmpty {
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
                            sendMessage()
                        }.onChange(of: Chat.shared.responseMessage.last?.text) { _, newValue in
                            if let presentText = newValue, !presentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                isShimmerTextVisible = false
                                isTextShimmering = false
                            }
                        }
                    
                    if !fileUrls.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(fileUrls, id: \.self) { file in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.secondary.opacity(0.15))
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Image(systemName: "doc.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(.secondary)
                                            Spacer(minLength: 0)
                                            Text(file.lastPathComponent).font(Font.system(size: 12))
                                                .truncationMode(.middle)
                                                .lineLimit(2)
                                                .fontWeight(.semibold)
                                                .fontDesign(.rounded)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(10)
                                    }
                                    .frame(width: 96, height: 96)
                                    .overlay(alignment: .topTrailing) {
                                        Button {
                                            fileUrls.removeAll(where: { $0 == file })
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .symbolRenderingMode(.palette)
                                                .foregroundStyle(.white, .black.opacity(0.65))
                                                .font(.system(size: 22))
                                                .padding(6)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel("Remove \(file.lastPathComponent)")
                                    }
                                }
                            }
                        }
                        .frame(height: 96)
                        .offset(y: -keyboardHeight)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    if !selectedPhotos.isEmpty {
                        PhotoPickerList(selectedPhotos: $selectedPhotos, keyboardHeight: keyboardHeight)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    HStack(alignment: .bottom) {
                        Menu {
                            Button {
                                showPhotoPicker = true
                            } label: {
                                Label("Upload Photo", systemImage: "photo")
                            }.onChange(of: selectedPhotos) {_, newValueItem in
                                
                                Task { @MainActor in
                                    do {
                                        for item in newValueItem {
                                            let transferPhoto: PhotoTransfer? = try await item.loadTransferable(type: PhotoTransfer.self)
                                            let rawImageData: Data? = transferPhoto?.photo
                                            let _ = UIImage(data: rawImageData ?? Data())
                                        }
                                    } catch {
                                        print("task error", error)
                                    }
                                }
                            }
                            
                            Button {
                                showFilePicker = true
                            } label: {
                                Label("Upload File(s)", systemImage: "folder.fill")
                            }
                        } label: {
                            Image(systemName: "plus").foregroundStyle(Color.mmDark)
                                .font(.system(size: 25))
                        }
                        
                        HStack(spacing: 5) {
                            Text(selectedModel.name)
                            if selectedModel.isSystemImage {
                                Image(systemName: selectedModel.image)
                            } else {
                                Image(selectedModel.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                            }
                        }
                        .font(.system(size: 14))
                        .fontDesign(.rounded).fontWeight(.regular)
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                        .foregroundStyle(Color.mmDark).opacity(0.5)
                        
                        
                        Spacer()
                        Button {
                            sendMessage()
                        } label: {
                            ZStack {
                                Circle().fill(canSendMessage ? Color.blue : Color.gray.opacity(0.4))
                                    .frame(maxWidth: 30, maxHeight: 30)
                                
                                Image(systemName: "arrow.up").foregroundStyle(.white)
                            }
                        }.padding(.trailing)
                            .disabled(!canSendMessage)
                            .animation(.easeInOut(duration: 0.1), value: canSendMessage)
                        
                    }.offset(y: -keyboardHeight)
                }.padding(.leading)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.clear).glassEffect(.clear, in: .rect(cornerRadius: 30)).opacity(0.8)
                        .offset(y: -keyboardHeight)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal))
                    .padding(.bottom)
                    .animation(.snappy(duration: 0.25), value: chatState.chat)
                    .animation(.snappy(duration: 0.25), value: fileUrls.count)
                    .animation(.snappy(duration: 0.25), value: selectedPhotos.count)
                
            }
            UpgradePlanAlertSheet(isPresented: $isMoreCreditsNeeded, onDismiss: { closeChatSheet() })
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
        .alert("Could not generate notes", isPresented: Binding(
            get: { chatError != nil },
            set: { if !$0 { chatError = nil } }
        )) {
            Button("OK") { chatError = nil }
        } message: {
            Text(chatError ?? "Please try again.")
        }
    }
    
    private func sendMessage() {
        guard !isGenerating, !chatState.chat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        showEmptyState = false
        chatError = nil
        isGenerating = true
        isShimmerTextVisible = true
        isTextShimmering = true
        let photos = selectedPhotos
        let file = fileUrls
        
        Task {
            defer {
                isGenerating = false
                isShimmerTextVisible = false
                isTextShimmering = false
                fileUrls.removeAll()
                selectedPhotos.removeAll()
            }
            do {
                let modelTier: Chat.ModelTier = Chat.ModelTier(rawValue: selectedAiProviderID) ?? .gptMini
                try await Chat.sendChatMessage(userFile: file, context: context, modelTier: modelTier, selectedPhotos: photos, onCreditsNeeded: { isMoreCreditsNeeded = true })
            } catch {
                chatError = error.localizedDescription
                print("chat error:", error)
            }
        }
    }
}



#Preview {
    ChatView()
}
