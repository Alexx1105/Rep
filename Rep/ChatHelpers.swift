//
//  AIHelpers.swift
//  Rep
//
//  Created by alex haidar on 4/20/26.
//
/* helper functions, methods, and classes for the AI Chat view
 and voice transcription and accessing system level APIs/view
 controllers for the front-end here */

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import UIKit
import SwiftData
import ImageIO


final class CoordinatorBridge: NSObject, UIDocumentPickerDelegate {
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
    var chatID: UUID = UUID()
    @Published var chat: String = ""
    @Published var responseMessage: [messageModel] = []
    @Published private(set) var isSyncingChat: Bool = false
    private var pendingChatSaves = 0
    
    public struct messageModel: Identifiable {
        public let id: String
        public var text: String
    }
    
    
    public enum ModelTier: String, Codable {
        case gptMini = "mini"
        case gptFull = "full"
        case appleFoundationModel = "local"
    }
    
    
    @MainActor
    public static func sendChatMessage(userFile: [URL]?, context: ModelContext, modelTier: Chat.ModelTier, selectedPhotos: [PhotosPickerItem], onCreditsNeeded: @escaping () -> Void, onResponseComplete: () -> Void = {}) async throws {
        let idempotentKey: UUID = UUID()
        let trimUserInput = Chat.shared.chat.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimUserInput.isEmpty else { return }
        
        Chat.shared.chat = ""
        let localId: String = UUID().uuidString
        
        
        await MainActor.run {
            shared.responseMessage.append(messageModel(id: localId, text: ""))
        }
        
        if let userFile { print("sending selected file: \(userFile)") }
        
        var userPhotoData: [Data] = []
        for photoData in selectedPhotos {
            if let transferPhoto: PhotoTransfer = try await photoData.loadTransferable(type: PhotoTransfer.self) {
                userPhotoData.append(transferPhoto.photo)
            }
        }
        
        var metadataText: String = ""
        var pendingUIText: String = ""
        let requestBuffer = chatBuffer()
        
        if modelTier == .appleFoundationModel {
            let answer = try await FoundationModelsManager.callFoundationModel(userMessage: trimUserInput, ontextSnapshot: { snapshot in
                guard let firstIndex = shared.responseMessage.firstIndex(where: { $0.id == localId }) else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    shared.responseMessage[firstIndex].text = snapshot
                }
            }, chatID: shared.chatID)
            await requestBuffer.append(answer)
            
        } else {
            do {
                try await AIRequestManager.shared.openAIRequest(userMessage: trimUserInput, userFileUrl: userFile, userPhotoData: userPhotoData, gptModel: modelTier.rawValue, context: context, idempotentKey: idempotentKey) { chunk in
                    
                    await requestBuffer.append(chunk)
                    pendingUIText += chunk
                    
                    guard pendingUIText.count >= 5 else { return }
                    
                    let format = pendingUIText
                    pendingUIText.removeAll(keepingCapacity: true)
                    
                    await MainActor.run {
                        if let addLastRawChunk = shared.responseMessage.indices.last {
                            shared.responseMessage[addLastRawChunk].text.append(format)
                        }
                    }
                }
                
                onMeta: { meta in
                    metadataText = meta
                    print("metadata:", metadataText)
                }
                
            } catch PaymentStoreError.insufficientTokens {
                shared.responseMessage.removeAll(where: { $0.id == localId })
                onCreditsNeeded()
                return
            } catch {
                shared.responseMessage.removeAll(where: { $0.id == localId })
                print("billing or function call failure", ErrorDesc.callsiteError, error)
                throw error
            }
        }
        
        
        let fullSnapahot: String = await requestBuffer.chunkSnapshot().trimmingCharacters(in: .whitespacesAndNewlines)
        await MainActor.run {
            if let messageIndex = shared.responseMessage.firstIndex(where: { $0.id == localId }) {
                shared.responseMessage[messageIndex].text = fullSnapahot
            }
        }
        
        guard !fullSnapahot.isEmpty else { throw ErrorDesc.ssetextStreamEventError }

        shared.pendingChatSaves += 1
        shared.isSyncingChat = true
        defer {
            shared.pendingChatSaves -= 1
            shared.isSyncingChat = shared.pendingChatSaves > 0
        }
        onResponseComplete()
        
        do {
            let cacheChat: OpenAIChat = OpenAIChat(content: fullSnapahot, openaiId: localId)
            context.insert(cacheChat)
            try context.save()
            
            let title: String = String(fullSnapahot.trimmingCharacters(in: .whitespacesAndNewlines).prefix(20))
            let trimmedText: String = fullSnapahot.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !title.isEmpty && !trimmedText.isEmpty else { throw ErrorDesc.nilValue }
            try await AIRequestManager.shared.upsertChatContent(fullSnapshot: trimmedText, openaiID: localId, title: title)
            
        } catch {
            print("failed to persist chat session:", ErrorDesc.persistenceError, error)
        }
    }
}


struct DocPicker: UIViewControllerRepresentable {
    var contentType: [UTType] = [.pdf, .png, .jpeg, .plainText, .commaSeparatedText, .image]
    var allowMultipleFileSelect: Bool = true
    var asCopy: Bool = true
    var onSelect: ([URL]) -> Void
    
    func makeCoordinator() -> CoordinatorBridge {
        CoordinatorBridge(onSelect: onSelect)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let newController = UIDocumentPickerViewController(forOpeningContentTypes: contentType, asCopy: asCopy)
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
        if !selectedPhotos.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(selectedPhotos, id: \.self) { item in
                        PhotoAttachmentTile(item: item) {
                            selectedPhotos.removeAll { $0 == item }
                        }
                    }
                }
            }
            .frame(height: 96)
            .offset(y: -keyboardHeight)
        }
    }
}

private struct PhotoAttachmentTile: View {
    let item: PhotosPickerItem
    let onRemove: () -> Void
    @State private var thumbnail: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.15))
            
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                ProgressView()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Photo preview unavailable")
            }
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .topTrailing) {
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.65))
                    .font(.system(size: 22))
                    .padding(6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove photo")
        }
        .task(id: item) {
            thumbnail = nil
            isLoading = true
            defer { isLoading = false }
            
            // Decode a small preview instead of retaining the full-resolution image.
            guard let data = try? await item.loadTransferable(type: Data.self),
                  !Task.isCancelled,
                  let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 288
                  ] as CFDictionary) else { return }
            
            thumbnail = UIImage(cgImage: image)
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


func allowAudioInputAV() async throws {
    let granted = await AVAudioApplication.requestRecordPermission()
    guard granted else { throw ErrorDesc.permissionDenied }
}
