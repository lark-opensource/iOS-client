//
//  ContainerPreviewController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/14.
//

#if !LARK_NO_DEBUG
import Foundation
import QuickLook

final class ContainerPreviewController: QLPreviewController, QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    let filePath: String

    init(path: String) {
        filePath = path
        super.init(nibName: nil, bundle: nil)
        delegate = self
        dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let _ = FileManager.default.fileExists(atPath: filePath)
        return NSURL(fileURLWithPath: filePath)
    }
}
#endif
