//
//  CTHTML2PDFRenderer.swift
//  Pods
//
//  Created by xurunkang on 2018/9/26.
//

import UIKit
import WebKit

/*
public final class CTHTML2PDFRenderer {

    public typealias ImageHandler = (UIImage?) -> Void
    public typealias PDFHandler = (Data) -> Void

    public class func render(webView: WKWebView, paperSize: CGSize, paperMargin: UIEdgeInsets = .zero, page: Int = 1, toPdf: PDFHandler) {
        let pdfData = exportPDFData(webView: webView, paperSize: paperSize, paperMargin: paperMargin)
        toPdf(pdfData)
    }

    public class func render(webView: WKWebView, paperSize: CGSize, paperMargin: UIEdgeInsets = .zero, toImage: ImageHandler) {
        let pdfCFData = exportPDFData(webView: webView, paperSize: paperSize, paperMargin: paperMargin) as CFData
        guard let provider = CGDataProvider(data: pdfCFData),
            let pdfDocument = CGPDFDocument(provider),
            let pdfPage = pdfDocument.page(at: 1)
        else {
            toImage(nil)
            return
        }

        let image = exportPDFDataToImage(pdfPage: pdfPage)
        toImage(image)
    }
}

extension UIPrintPageRenderer {
    public func exportPDFData(numberOfPages: Int = 1) -> Data {
        let data = NSMutableData()

        UIGraphicsBeginPDFContextToData(data, paperRect, nil)
        prepare(forDrawingPages: NSRange(location: 0, length: numberOfPages))
        for i in 0 ..< numberOfPages {
            UIGraphicsBeginPDFPage()
            drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
        }
        UIGraphicsEndPDFContext()

        return data as Data
    }
}

extension CTHTML2PDFRenderer {
    private class func exportPDFData(webView: WKWebView, paperSize: CGSize, paperMargin: UIEdgeInsets = .zero, page: Int = 1) -> Data {
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(webView.viewPrintFormatter(), startingAtPageAt: 0)

        let paperRect = CGRect(origin: CGPoint(x: 0, y: 0), size: paperSize)
        renderer.setValue(paperRect, forKey: "paperRect")
        let printableRect = _printableRect(paperRect: paperRect, paperMargins: paperMargin)
        renderer.setValue(printableRect, forKey: "printableRect")

        return renderer.exportPDFData()
    }

    private class func _printableRect(paperRect: CGRect, paperMargins: UIEdgeInsets) -> CGRect {
        var printableRect = paperRect
        printableRect.origin.x += paperMargins.left
        printableRect.origin.y += paperMargins.top
        printableRect.size.width -= (paperMargins.left + paperMargins.right)
        printableRect.size.height -= (paperMargins.top + paperMargins.bottom)
        return printableRect
    }

    private class func exportPDFDataToImage(pdfPage: CGPDFPage) -> UIImage? {
        let pageRect = pdfPage.getBoxRect(.trimBox)
        let contentSize = CGSize(width: floor(pageRect.size.width), height: floor(pageRect.size.height))

        UIGraphicsBeginImageContextWithOptions(contentSize, true, 5.0)

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        context.setFillColor(UIColor.ud.N00.cgColor)
        context.setStrokeColor(UIColor.ud.N00.cgColor)
        context.fill(pageRect)

        context.saveGState()
        context.translateBy(x: 0, y: contentSize.height)
        context.scaleBy(x: 1.0, y: -1.0)

        context.interpolationQuality = .high
//        context.setRenderingIntent(.defaultIntent)
        context.drawPDFPage(pdfPage)
        context.restoreGState()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
*/
