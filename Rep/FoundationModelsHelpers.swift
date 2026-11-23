//
//  FoundationModelsHelpers.swift
//  Rep
//
//  Created by alex haidar on 11/14/26.
/* helpers for the AFM model like file extraction */
import Foundation
import FoundationModels
import PDFKit
import Vision
import UIKit


public enum FileFormat: CaseIterable {
    case plaintext
    case pdfText
    case pdfImageOcr
    case photoImage
}

//TODO: handle large file batches in multiple smaller requests for smaller context budget

public func fileExtractor(fileUrl: URL, fileFormat: FileFormat) async throws -> String {
    switch fileFormat {
    case .plaintext:
        let hasAccess = fileUrl.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                fileUrl.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileData: Data = try Data(contentsOf: fileUrl)
        guard let fileString: String = String(data: fileData, encoding: .utf8) else { throw ErrorDesc.decodeError }
        return fileString
        
        
    case .pdfText:
        let hasAccess = fileUrl.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                fileUrl.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let doc: PDFDocument = PDFDocument(url: fileUrl) else { throw ErrorDesc.pdfExtractionError }
        guard !doc.isLocked else { throw ErrorDesc.pdfAccessError }
        guard let text: String = doc.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ErrorDesc.pdfExtractionError }
        return text
        
        
    case .pdfImageOcr:
        let hasAccess = fileUrl.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                fileUrl.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let doc = PDFDocument(url: fileUrl) else { throw ErrorDesc.pdfExtractionError }
        guard !doc.isLocked else { throw ErrorDesc.pdfAccessError }
        
        var pageTexts: [String] = []
        for i in 0..<doc.pageCount {
            try Task.checkCancellation()
            
            guard let pdfPage: PDFPage = doc.page(at: i) else { throw ErrorDesc.pdfExtractionError }
            let pageBounds: CGRect = pdfPage.bounds(for: .mediaBox)
            guard pageBounds.width > 0, pageBounds.height > 0 else { throw ErrorDesc.pdfExtractionError }
            
            let pageScale: CGFloat = 2000 / max(pageBounds.width, pageBounds.height)
            let pageSize: CGSize = CGSize(width: pageBounds.width * pageScale, height: pageBounds.height * pageScale)
            
            let img: UIImage = pdfPage.thumbnail(of: pageSize, for: .mediaBox)
            guard let uiImage = img.cgImage else { throw ErrorDesc.pdfExtractionError }
            
            let ocrTextRequest = VNRecognizeTextRequest()
            ocrTextRequest.recognitionLevel = .accurate
            ocrTextRequest.automaticallyDetectsLanguage = true
            ocrTextRequest.usesLanguageCorrection = true
            
            let requestHandler = VNImageRequestHandler(cgImage: uiImage, options: [:])
            try requestHandler.perform([ocrTextRequest])
            let extractedPageText: String = (ocrTextRequest.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            pageTexts.append(extractedPageText)
        }
        
        let text: String = pageTexts.joined(separator: "\n\n")
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ErrorDesc.pdfExtractionError }
        return text
        
        
    case .photoImage:
        let hasAccess = fileUrl.startAccessingSecurityScopedResource()
        defer {
            if hasAccess {
                fileUrl.stopAccessingSecurityScopedResource()
            }
        }
        
        let handler: VNImageRequestHandler = VNImageRequestHandler(url: fileUrl, options: [:])
        return try recognizePhotoText(using: handler)
    }
}

func photoTextExtractor(photoData: Data) async throws -> String {
    let extraction: Task = Task.detached(priority: .userInitiated) {
        let handler: VNImageRequestHandler = VNImageRequestHandler(data: photoData, options: [:])
        return try recognizePhotoText(using: handler)
    }
    return try await withTaskCancellationHandler {
        try await extraction.value
    } onCancel: {
        extraction.cancel()
    }
}

private func recognizePhotoText(using handler: VNImageRequestHandler) throws -> String {
    try Task.checkCancellation()
    let request = VNRecognizeTextRequest()
    
    request.recognitionLevel = .accurate
    request.automaticallyDetectsLanguage = true
    request.usesLanguageCorrection = true
    
    try handler.perform([request])
    try Task.checkCancellation()
    let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ErrorDesc.decodeError }
    return text
}


