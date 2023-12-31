//
//  DocsDocumentPickerViewController.swift
//  SKBrowser
//
//  Created by chenhuaguan on 2020/12/4.
//

import Foundation
import SKCommon
import SKResource
import SKFoundation

public protocol DocsDocumentPickerDelegate: AnyObject {
    func pickDocumentFinishSelect(urls: [URL])
    func pickDocumentDidCancel()
}

extension DocsDocumentPickerDelegate {
    func pickDocumentDidCancel() {}
}

/// 参考文档：https://docs.bytedance.net/doc/doccnqBxBdV5FJdImdxWoP
private let documentTypes = [
    "public.item"    //范围太广
]

public final class DocsDocumentPickerViewController: UIDocumentPickerViewController, UIDocumentPickerDelegate {
    weak var selectDelegate: DocsDocumentPickerDelegate?

    public  init(deletage: DocsDocumentPickerDelegate) {
        self.selectDelegate = deletage
        super.init(documentTypes: documentTypes, in: .import)
        delegate = self
        modalPresentationStyle = .fullScreen
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.selectDelegate?.pickDocumentFinishSelect(urls: urls)
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        self.selectDelegate?.pickDocumentFinishSelect(urls: [url])
    }
 
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        self.selectDelegate?.pickDocumentDidCancel()
    }
}
