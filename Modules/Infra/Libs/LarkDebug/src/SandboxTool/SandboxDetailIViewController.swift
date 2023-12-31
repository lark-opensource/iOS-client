//
//  SandboxDetailIViewController.swift
//  swit_test
//
//  Created by liluobin on 2021/7/11.
//

#if !LARK_NO_DEBUG

import Foundation
import UIKit
import QuickLook
final class SandboxDetailIViewController: UIViewController, QLPreviewControllerDelegate, QLPreviewControllerDataSource {

    let filePath: String
    init(filePath: String) {
        self.filePath = filePath
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        view.backgroundColor = .white
        title = "文件预览"
        super.viewDidLoad()
        let previewVC = QLPreviewController()
        previewVC.delegate = self
        previewVC.dataSource = self
        self.present(previewVC, animated: true, completion: nil)
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
       return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return NSURL(fileURLWithPath: filePath)
    }
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        self.navigationController?.popViewController(animated: false)
    }
}
#endif
