//
//  AIHelpers.swift
//  Rep
//
//  Created by alex haidar on 4/20/26.
//helper functions, methods, and classes for the AI Chat view and voice transcription here,

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import UIKit


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


public class Chat: ObservableObject {
    private init() {}
    
    static let shared = Chat()
    @Published var chat: String = ""
    
    public static func sendChatMessage() {
        let trimInput = Chat.shared.chat.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimInput.isEmpty else { return }
        print("sending chat \(trimInput)")
        
        Chat.shared.chat = ""
    }
}


struct DocPicker: UIViewControllerRepresentable {
    var contentType: [UTType] = [.item, .image, .folder, .fileURL]
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

struct CameraPicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage?) -> Void
    var onCancel: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(pickerParent: self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let pickerParent: CameraPicker
        init(pickerParent: CameraPicker) { self.pickerParent = pickerParent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            pickerParent.onImagePicked(info[.originalImage] as? UIImage)
            picker.presentingViewController?.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            pickerParent.onCancel?()
            picker.presentingViewController?.dismiss(animated: true)
        }
    }
}


struct PhotoPicker: View {       //WIP
    var body: some View {
        @State var selectedPhotoItem: PhotosPickerItem? = nil
        @State var selectedImage: Image? = nil
        @State var importedPhotoData: Data? = nil
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

