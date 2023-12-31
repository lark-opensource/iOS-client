//
//  FileDocumentPickerViewController.swift
//  LarkFile
//
//  Created by 王元洵 on 2020/11/4.
//

import UIKit
import Foundation
import LarkModel
import LKCommonsTracker
import Homeric
import LarkFoundation
import LarkMessengerInterface
import LKCommonsLogging
import LarkFeatureGating
import LarkContainer
import LarkSetting
import LarkStorage
import LarkSDKInterface

private typealias Path = LarkSDKInterface.PathWrapper

final class FileDocumentPickerViewController: UIDocumentPickerViewController, UserResolverWrapper {
    private static var logger = Logger.log(FileDocumentPickerViewController.self, category: "LarkFile.SendAttachedFile")
    /// 发送文件block
    var sendFileBlock: (([LocalAttachFile]) -> Void)?

    let userResolver: UserResolver

    @ScopedInjectedLazy private var fgService: FeatureGatingService?

    init(documentTypes allowedUTIs: [String], in mode: UIDocumentPickerMode, userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(documentTypes: allowedUTIs, in: mode)
        self.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FileDocumentPickerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        Tracker.post(TeaEvent(Homeric.CLICK_ATTACH_ICON_PHONESTORAGE))

        let attachFiles = urls
            .compactMap { (url) -> LocalAttachFile? in
                guard let fileInfo = Utils.getFileInfo(url.path) else { return nil }
                var resultURL: URL
                if fgService?.dynamicFeatureGatingValue(with: "messenger.file.ios_upload_sandbox_copypath") ?? false {
                    do {
                        if Path.useLarkStorage {
                            var tempPath = IsoPath.temporary() + Date().timeIntervalSince1970.description
                            try tempPath.createDirectoryIfNeeded()
                            tempPath += url.lastPathComponent
                            try tempPath.notStrictly.moveItem(from: url.asAbsPath())
                            resultURL = tempPath.url
                        } else {
                            var tempPath = Path.Old.userTemporary
                            tempPath = tempPath.appendingRelativePath(Date().timeIntervalSince1970.description)
                            try tempPath.createDirectoryIfNeeded()
                            tempPath = tempPath.appendingRelativePath(url.lastPathComponent)
                            let originPath = Path.Old(url.path)
                            try originPath.moveFile(to: tempPath)
                            resultURL = tempPath.url
                        }
                        Self.logger.info("copy file to tempURL success")
                    } catch {
                        Self.logger.error("copy file to tempURL failed", error: error)
                        resultURL = url
                    }
                } else {
                    resultURL = url
                }

                return LocalAttachFile(name: fileInfo.fileName,
                                       fileURL: resultURL,
                                       size: UInt(fileInfo.fileSize))
            }
            .filter { !$0.name.isEmpty }

        self.sendFileBlock?(attachFiles)

        controller.dismiss(animated: true)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        Tracker.post(TeaEvent(Homeric.CLICK_ATTACH_ICON_PHONESTORAGE_CANCEL))

        controller.dismiss(animated: true)
    }
}
