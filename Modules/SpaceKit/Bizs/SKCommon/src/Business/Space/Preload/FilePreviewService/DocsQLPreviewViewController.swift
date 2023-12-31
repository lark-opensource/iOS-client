//
//  DocsQLPreviewViewController.swift
//  SpaceKit
//
//  Created by bytedance on 2018/10/8.
//

import UIKit
import QuickLook
import SKFoundation

class DocsQLPreviewViewController: QLPreviewController {
    let fileItem: QLPreviewItem

    init(fileItem: QLPreviewItem) {
        self.fileItem = fileItem
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
    }

    deinit {
        DocsLogger.debug("deinit")
    }
}

extension DocsQLPreviewViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileItem
    }
}
