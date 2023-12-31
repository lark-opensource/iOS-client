//
//  DriveQLPreviewController.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/17.
//

import UIKit
import QuickLook

class DriveQLPreviewController: QLPreviewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    private var isLoaded = false
    private(set) var fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        dataSource = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isLoaded { return }
        isLoaded = true
        view.accessibilityIdentifier = "drive.ql.view"
    }

    class func canPreview(_ item: URL) -> Bool {
        return canPreview(item as QLPreviewItem)
    }

}

// MARK: - QLPreviewControllerDataSource
extension DriveQLPreviewController: QLPreviewControllerDataSource {

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileURL as QLPreviewItem
    }
}
