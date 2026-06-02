//
//  AIHelpers.swift
//  Rep
//
//  Created by alex haidar on 4/20/26.
//
/* helper functions, methods, and classes for the AI Chat view
 and voice transcription and accessing system level APIs/view controllers for the front-end here */

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import UIKit
import SwiftData


final class CoordinatorBridge: NSObject, UIDocumentPickerDelegate {     ///FYI: acts a a bridge between SwiftUI & UIKit
    let onSelect: ([URL]) -> Void
    init(onSelect: @escaping ([URL]) -> Void) {
        self.onSelect = onSelect
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onSelect(urls)
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
}


actor chatBuffer {
    private var textStorage: String = ""
    
    func append(_ text: String) {
        textStorage += text
    }
    func chunkSnapshot() -> String {
        textStorage
    }
}

let chatBufferInstance = chatBuffer()


struct PhotoTransfer: Transferable {         ///shared wrapper to allow images types to play well with .loadTransferable(_)
    let photo: Data
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .jpeg) { data in
            PhotoTransfer(photo: data)
        }
        
        DataRepresentation(importedContentType: .png) { data in
            PhotoTransfer(photo: data)
        }
        
        DataRepresentation(importedContentType: .heic) { data in
            PhotoTransfer(photo: data)
        }
        DataRepresentation(importedContentType: .image) { data in
            PhotoTransfer(photo: data)
        }
    }
}

public class Chat: ObservableObject {
    private init() {}
    
    static let shared = Chat()
    @Published var chat: String = ""
    @Published var responseMessage: [messageModel] = []
    
    public struct messageModel: Identifiable {
        public let id: String
        public var text: String
    }
    
    
    @MainActor
    public static func sendChatMessage(userFile: URL?, context: ModelContext, selectedPhotos: [PhotosPickerItem]) {
        let trimUserInput = Chat.shared.chat.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimUserInput.isEmpty else { return }
        print("sending chat: \(trimUserInput)")
        
        Chat.shared.chat = ""
        let localId: String = UUID().uuidString
        
        Task {
            await MainActor.run {
                shared.responseMessage.append(messageModel(id: localId, text: ""))
            }
            
            if let userFile { print("sending selected file: \(userFile)") }
            
            let userPhotoData: Data?
            if let userPhoto = selectedPhotos.compactMap({ $0 }).first {
                print("user photo: \(userPhoto.supportedContentTypes)")
                if let transferPhoto = try await userPhoto.loadTransferable(type: PhotoTransfer.self) {
                    userPhotoData = transferPhoto.photo
                    
                    print("photo passed down: \(userPhotoData?.count ?? 0)")
                } else {
                    userPhotoData = nil
                }
            } else {
                userPhotoData = nil
            }
            
            var metadataText: String = ""
            try await AIRequestManager.shared.openAIRequest(userMessage: trimUserInput, userFileUrl: userFile, userPhotoData: userPhotoData, gptModel: "mini", context: context) { chunk in
                
                Task {
                    await chatBufferInstance.append(chunk)
                    let snapshot: String = await chatBufferInstance.chunkSnapshot()
                    print("SNAPSHOT IN BUFFER: \(snapshot)")
                    
                    var formattedChunk: String
                    do {
                        let format = try AIRequestManager.shared.extractChatContent(extractedContent: snapshot)  //TODO: improve response speed
                        formattedChunk = format
                    } catch {
                        print("formatting chunk from buffer failed - using raw JSON chunk as fallback")
                        formattedChunk = snapshot
                    }
                    
                    Task { @MainActor in
                        if let addLastRawChunk = shared.responseMessage.indices.last {
                            shared.responseMessage[addLastRawChunk].text = formattedChunk
                        }
                    }
                }
            }
            onMeta: { meta in
                metadataText = meta
                print("metadata:", metadataText)
            }
            
            
            let fullSnapahot: String = await chatBufferInstance.chunkSnapshot().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !fullSnapahot.isEmpty else { throw ErrorDesc.ssetextStreamEventError }
            
            do {
                let cacheChat: OpenAIChat = OpenAIChat(content: fullSnapahot, openaiId: localId)
                context.insert(cacheChat)
                try context.save()
                
                let title: String = String(fullSnapahot.trimmingCharacters(in: .whitespacesAndNewlines).prefix(20))
                let trimmedText: String = fullSnapahot.trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard !title.isEmpty && !trimmedText.isEmpty else { throw ErrorDesc.nilValue }
                try await AIRequestManager.shared.upsertChatContent(fullSnapshot: trimmedText, openaiID: localId, title: title)
                
                print("chat session saved...")
            } catch {
                print("failed to persist chat session ❗️", ErrorDesc.persistenceError, error)
            }
        }
    }
}


struct DocPicker: UIViewControllerRepresentable {
    var contentType: [UTType] = [.pdf, .png, .jpeg, .plainText, .commaSeparatedText, .image]
    var allowMultipleFileSelect: Bool = true
    var onSelect: ([URL]) -> Void
    
    func makeCoordinator() -> CoordinatorBridge {
        CoordinatorBridge(onSelect: onSelect)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let newController = UIDocumentPickerViewController(forOpeningContentTypes: contentType, asCopy: true)
        newController.allowsMultipleSelection = allowMultipleFileSelect
        newController.delegate = context.coordinator
        return newController
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController,context: Context) {
        uiViewController.allowsMultipleSelection = allowMultipleFileSelect
    }
}


//struct CameraPicker: UIViewControllerRepresentable {
//    var onImagePicked: (UIImage?) -> Void
//    var onCancel: (() -> Void)? = nil
//
//    func makeCoordinator() -> Coordinator { Coordinator(pickerParent: self) }
//
//    func makeUIViewController(context: Context) -> UIImagePickerController {
//        let picker = UIImagePickerController()
//        picker.sourceType = .camera
//        picker.cameraCaptureMode = .photo
//        picker.delegate = context.coordinator
//        return picker
//    }
//
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
//
//    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//        let pickerParent: CameraPicker
//        init(pickerParent: CameraPicker) { self.pickerParent = pickerParent }
//
//        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
//            pickerParent.onImagePicked(info[.originalImage] as? UIImage)
//            picker.presentingViewController?.dismiss(animated: true)
//        }
//
//        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//            pickerParent.onCancel?()
//            picker.presentingViewController?.dismiss(animated: true)
//        }
//    }
//}


struct PhotoPickerList: View {
    @Binding var selectedPhotos: [PhotosPickerItem]
    let keyboardHeight: CGFloat 
    
    var body: some View {
        ForEach(Array(selectedPhotos.indices), id: \.self) { index in
            ZStack {
                Capsule()
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .glassEffect(.regular)
               
                
                HStack(spacing: 3) {
                    Text(String("Image \(index + 1)")).font(Font.system(size: 12))
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                    
                    Button {
                        selectedPhotos.remove(at: index)
                    } label: {
                        Image(systemName: "x.circle.fill").fixedSize()
                            .foregroundStyle(Color.mmDark)
                    }
                }.padding(6)
            }.fixedSize()
        }.offset(y: -keyboardHeight)
      
        .onAppear {
            print("SELECED: \(selectedPhotos.count)")
        }
    }
}


struct PhotoPicker: View {
    @Binding var selectedPhotos: [PhotosPickerItem]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .center) {
            PhotosPicker(selection: $selectedPhotos, matching: .images, photoLibrary: .shared()) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.clear)
                        .glassEffect(.regular, in: .rect(cornerRadius: 30))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(.all)
                        .overlay {
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.mmDark.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, lineCap: .round, dash: [8, 6]))
                        }.padding()
                    
                    
                    VStack(spacing: 5) {
                        Label("Upload Photo", systemImage: "photo").font(.headline)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.mmDark)
                        
                        Text("Upload an image with text and\nRep will turn them into notes").font(.subheadline)
                            .foregroundStyle(Color.mmDark).opacity(0.5)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        HStack(alignment: .bottom , spacing: 5) {
                            ForEach(0..<5) { square in
                                RoundedRectangle(cornerRadius: 12).frame(maxWidth: 55, maxHeight: 55)
                                .foregroundStyle(Color.mmDark).opacity(0.1)
                                
                            }
                        }.padding(.top, 2)
                    }
                }
            }.presentationDetents([.fraction(0.3)])
        }.onChange(of: selectedPhotos) { _, newValue in
            if !newValue.isEmpty {
                dismiss()
            }
        }
    }
    
    
    @MainActor
    private static func loadPhoto() async {}
}

func generateFilename(from item: PhotosPickerItem) -> String {
    return "upload-\(UUID().uuidString).jpg"
}

func guessMimeType(for data: Data) -> String {
    if data.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
    if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "image/png" }
    if data.starts(with: [0x47, 0x49, 0x46]) { return "image/gif" }
    return "application/octet-stream"
}

