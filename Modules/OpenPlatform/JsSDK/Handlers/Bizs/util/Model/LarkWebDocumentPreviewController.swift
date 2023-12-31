//
//  Resources.swift
//  Module
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import LarkUIKit
import LarkActionSheet
import CryptoSwift
import WebKit
import ECOInfra
import LarkStorage
import LKCommonsLogging
import OPFoundation

class LarkWebDocumentPreviewController: BaseUIViewController {
    static let logger = Logger.log(LarkWebDocumentPreviewController.self, category: "LarkWebDocumentPreviewController")

    private lazy var webView = WKWebView()

    private let filePath: String
    private let fileName: String
    private var fileType: String?

    private var tmpFileURL: URL?
    private var tmpFileIsoPath: IsoPath?
    private let documentIteractionController = UIDocumentInteractionController()

    override public var shouldAutorotate: Bool {
        return false
    }

    public init(filePath: String, fileName: String, fileType: String?) {
        self.filePath = filePath
        self.fileName = fileName
        self.fileType = fileType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if LSFileSystem.isoPathEnable {
            try? self.tmpFileIsoPath?.removeItem()
        }else {
            if let url = tmpFileURL {
                // lint:disable:next lark_storage_migrate_check
                try? FileManager().removeItem(at: url)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if !LSFileSystem.fileExists(filePath: filePath) {
            return
        }

        webView.frame = view.bounds
        view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        webView.isUserInteractionEnabled = true
        webView.backgroundColor = .clear
        webView.isOpaque = false

        view.backgroundColor = UIColor.ud.commonBackgroundColor

        /// 尝试添加导航栏右侧按钮
        addRightNavItemIfNeeded()

        title = fileName

        // 对于没有后缀的文件，WebView无法识别其类型，这里需要进行一些处理
        let url = URL(fileURLWithPath: filePath)
        let pathExtension = url.pathExtension
        if !pathExtension.isEmpty && self.fileType == nil {
            // 有后缀没有指定类型，直接打开
        } else if !pathExtension.isEmpty && self.fileType == pathExtension {
            // 有后缀并且与指定类型相同，直接打开
        } else if let fileType = self.fileType, !fileType.isEmpty {
            let md5 = filePath.md5()
            // 有明确指定类型但文件后缀不匹配的
            let tmpFileName = "ema_tmp_\(md5)_\(Int(NSDate().timeIntervalSince1970 * 1000))_\(arc4random()).\(fileType)"
            if LSFileSystem.isoPathEnable {
                let isoPath = IsoPath.notStrictly.temporary().appendingRelativePath(tmpFileName)
                tmpFileIsoPath = isoPath
                tmpFileURL = URL(fileURLWithPath: isoPath.absoluteString)
                if let tmpURL = tmpFileURL {
                    do {
                        try isoPath.copyItem(from: AbsPath(url.path))
                        webView.loadFileURL(tmpURL, allowingReadAccessTo: tmpURL)
                        return
                    } catch {
                        Self.logger.error("LarkWebDocumentPreviewController isoPath copyItem fail", error: error)
                    }
                }
            }else {
                // lint:disable:next lark_storage_migrate_check
                tmpFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tmpFileName)
                if let tmpURL = tmpFileURL {
                    do {
                        // lint:disable:next lark_storage_migrate_check
                        try FileManager().copyItem(at: url, to: tmpURL)
                        webView.loadFileURL(tmpURL, allowingReadAccessTo: tmpURL)
                        return
                    } catch {
                        Self.logger.error("LarkWebDocumentPreviewController FileManager copyItem fail", error: error)
                    }
                }
            }
            
        }

        let fileURL = URL(fileURLWithPath: filePath)
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
    }

    /// 添加导航栏右侧按钮
    private func addRightNavItemIfNeeded() {
        if LSFileSystem.fileExists(filePath: filePath) {
            /// 添加右侧按钮
            let rightBarButtonItem = LKBarButtonItem(image: UIImage.bdp_imageNamed("moreOption"))
            navigationItem.rightBarButtonItems = [rightBarButtonItem]
            rightBarButtonItem.button.addTarget(self, action: #selector(rightBarButtonItemClicked), for: .touchUpInside)
        } else {
            navigationItem.rightBarButtonItems = []
        }
    }

    /// 点击右侧按钮的action
    @objc
    private func rightBarButtonItemClicked() {
        let actionSheet = ActionSheet(title: "")
        actionSheet.addItem(title: BundleI18n.JsSDK.OpenPlatform_AppCenter_OpenWithAnotherApp) {
            self.openWithOtherApp()
        }
        actionSheet.addCancelItem(title: BundleI18n.JsSDK.Lark_Legacy_Cancel)
        present(actionSheet, animated: true)
    }

    /// 用其他应用打开
    private func openWithOtherApp() {
        documentIteractionController.url = URL(fileURLWithPath: self.filePath)
        documentIteractionController.presentOptionsMenu(from: view.bounds, in: view, animated: true)
    }
}
