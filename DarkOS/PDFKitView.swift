// DarkOS/PDFKitView.swift

import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Only load the document if the URL changes to prevent reload stuttering
        if let currentDoc = uiView.document, currentDoc.documentURL == url {
            return
        }
        uiView.document = PDFDocument(url: url)
    }
}
