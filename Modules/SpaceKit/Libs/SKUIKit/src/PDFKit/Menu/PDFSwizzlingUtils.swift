//
//  PDFSwizzlingUtils.swift
//  SKUIKit
//
//  Created by huayufan on 2023/10/20.
//  


import UIKit
import SKFoundation

extension UIView {
    
    private struct PrivatePropertyKey {
        static var parentPdfViewKey: UInt8 = 0
    }
    
    var weakParentPDFView: WeakReference<SKPDFView>? {
         get {
             return objc_getAssociatedObject(self, &PrivatePropertyKey.parentPdfViewKey) as? WeakReference<SKPDFView>
         }
         set {
             objc_setAssociatedObject(self, &PrivatePropertyKey.parentPdfViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
         }
     }
    
    @objc func swizzledCanPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard let pdfView = self.weakParentPDFView?.ref else {
            // 非云文档场景调用原有方法
            return self.swizzledCanPerformAction(action, withSender: sender)
        }
        return pdfView.canPerformAction(action, withSender: sender)
    }
}

class PDFSwizzlingUtils {
    
    static let shared = PDFSwizzlingUtils()
    
    private var swizzled = false

    func swizzleDocumentView(pdfView: SKPDFView) -> Bool {
        guard !swizzled else { return true}
        guard let documentView = pdfView.documentView, let documentViewClass = object_getClass(documentView) else {
            return false
        }
        self.swizzled = self.swizzling(forClass: documentViewClass,
                       originalSelector: #selector(UIView.canPerformAction(_:withSender:)),
                       swizzledSelector: #selector(UIView.swizzledCanPerformAction(_:withSender:)))
        return self.swizzled
    }
    
    func swizzling(forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector) -> Bool {
        guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
            let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
                return false
        }
        if class_addMethod(
            forClass,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
            ) {
            class_replaceMethod(
                forClass,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
            return false
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
            return true
        }
    }
}
