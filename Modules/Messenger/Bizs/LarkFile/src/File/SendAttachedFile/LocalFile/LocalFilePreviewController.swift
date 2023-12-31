//
//  LocalFilePreviewController.swift
//  LarkFile
//
//  Created by tangyunfei on 2019/1/18.
//

import Foundation
import UIKit
import Photos
import AVKit
import LarkUIKit
import RxSwift
import LarkModel
import LKCommonsLogging
import LarkExtensions
import UniverseDesignToast
import LarkMessengerInterface
import SuiteAppConfig
import WebBrowser
import EENavigator
import LarkContainer
import LarkSDKInterface
import LarkEMM
import LarkSensitivityControl

final class LocalFilePreviewController: LocalWebBrowserController, UserResolverWrapper {

    private var file: AttachedFile

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let userResolver: UserResolver
    init(_ file: AttachedFile, appConfigService: AppConfigService, userResolver: UserResolver) {
        self.file = file
        self.userResolver = userResolver
        super.init(appConfigService: appConfigService)
    }

    @ScopedInjectedLazy private var dependency: MDFileDependency?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = self.file.name
        self.previewAttachFile()
    }

    private func previewAttachFile() {

        switch self.file.type {
        case .albumVideo:
            guard let albumFile = self.file as? AlbumFile else { return }
            var hud: UDToast?
            if let window = self.view.window {
                hud = UDToast.showDefaultLoading(on: window, disableUserInteraction: true)
            }
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            try? AlbumEntry.requestPlayerItem(forToken: FileToken.requestPlayerItem.token,
                                              manager: PHImageManager.default(),
                                              forVideoAsset: albumFile.asset, options: options) { [weak self] (item, _) in
                DispatchQueue.main.async {
                    hud?.remove()
                    let videoVC = AVPlayerViewController()
                    videoVC.player = AVPlayer(playerItem: item)
                    videoVC.player?.play()

                    self?.addChild(videoVC)
                    self?.view.addSubview(videoVC.view)

                    if let bounds = self?.view.bounds {
                        videoVC.view.frame = bounds
                    }

                }
            }
        case .localVideo:
            guard let localFile = self.file as? LocalFile else { return }
            let videoVC = AVPlayerViewController()
            videoVC.player = AVPlayer(url: URL(fileURLWithPath: localFile.filePath))
            videoVC.player?.play()
            self.addChild(videoVC)
            self.view.addSubview(videoVC.view)

        case .TXT, .JSON:
            guard let localFile = self.file as? LocalFile else { return }
//            self.webView.lkLoadRequest(URLRequest(url: URL(fileURLWithPath: localFile.filePath)), prevUrl: nil)
            self.webView.lwvc_loadRequest(URLRequest(url: URL(fileURLWithPath: localFile.filePath)))
            let textTemplate = """
            <html>
                <head> <meta name="viewport" content="width=device-width, initial-scale=1"> </head>
                <body> <pre style="word-wrap: break-word; white-space: pre-wrap;">%@</pre> </body>
            </html>
            """

            if let stringContent = stringContentForURL(URL(fileURLWithPath: localFile.filePath)) {
                self.webView.loadHTMLString(String(format: textTemplate, stringContent), baseURL: nil)
            }

        case .HTML:
            guard let localFile = self.file as? LocalFile else { return }
//            self.webView.lkLoadRequest(URLRequest(url: URL(fileURLWithPath: localFile.filePath)), prevUrl: nil)
            self.webView.lwvc_loadRequest(URLRequest(url: URL(fileURLWithPath: localFile.filePath)))
            if let stringContent = stringContentForURL(URL(fileURLWithPath: localFile.filePath)) {
                self.webView.loadHTMLString(stringContent, baseURL: nil)
            }

        case .MD:
            guard let localFile = self.file as? LocalFile else { return }
            if stringContentForURL(URL(fileURLWithPath: localFile.filePath)) != nil {
                dependency?.jumpToSpace(fileURL: URL(fileURLWithPath: localFile.filePath), name: localFile.name, fileType: "md", from: self)
            }
        default:
            guard let localFile = self.file as? LocalFile else { return }
            let fileURL = URL(fileURLWithPath: localFile.filePath)
//            self.webView.lkLoadRequest(URLRequest(url: fileURL), prevUrl: fileURL)
            self.webView.lwvc_loadRequest(URLRequest(url: fileURL), prevUrl: fileURL)
        }

    }

    private func stringContentForURL(_ url: URL) -> String? {
        let encodings = [
            .utf8,
            String.Encoding(rawValue: 0x80000631), //GBK18030
            String.Encoding(rawValue: 0x80000632), //GBK
            String.Encoding(rawValue: 0x80000503), //greek
            String.Encoding(rawValue: 0x80000504)  //turkish
        ]

        let resultData = (try? Data.read_(from: url))
        if let resultData = resultData {
            for encoding in encodings {
                if let resultString = String(data: resultData, encoding: encoding) {
                    return resultString
                }
            }
        }

        return nil
    }

}
