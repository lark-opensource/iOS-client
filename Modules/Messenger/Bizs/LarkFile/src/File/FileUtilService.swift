//
//  FileUtilService.swift
//  LarkFile
//
//  Created by bytedance on 2021/11/18.
//

import UIKit
import Foundation
import LarkMessengerInterface
import LarkSDKInterface
import LarkContainer
import LarkFeatureGating
import LarkModel
import RustPB
import UniverseDesignToast
import ThreadSafeDataStructure
import RxCocoa
import RxSwift
import LKCommonsLogging
import Swinject
import LarkSetting

private typealias Path = LarkSDKInterface.PathWrapper

final class FileUtilServiceImp: FileUtilService, UserResolverWrapper {

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    let userResolver: UserResolver
    private let logger = Logger.log(FileUtilServiceImp.self, category: "LarkFile.FileUtilService")
    @ScopedInjectedLazy private var fileAPI: SecurityFileAPI?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var settingService: FeatureGatingService?
    private let disposeBag = DisposeBag()
    private lazy var messengerFileConfig: MessengerFileConfig? = {
        return userGeneralSettings?.messengerFileConfig
    }()
    func fileIsPreviewableZip(fileName: String, fileSize: Int64) -> Bool {
        guard let messengerFileConfig = messengerFileConfig else { return false }

        if fileSize > messengerFileConfig.sizeUpperLimit {
            return false
        }
        if messengerFileConfig.format.contains((fileName as NSString).pathExtension.lowercased()) {
            return true
        }
        //判断含有2个点的拓展名
        let splitedList = fileName.split(separator: ".")
        if splitedList.count > 2 {
            let extendedNameWithTwoDots = "\(splitedList[splitedList.count - 2]).\(splitedList.last ?? "")"
            return messengerFileConfig.format.contains(extendedNameWithTwoDots.lowercased())
        }
        return false
    }

    private func fileSource(message: Message) -> RustPB.Basic_V1_File.Source {
        switch message.type {
        case .file:
            return (message.content as? FileContent)?.fileSource ?? .unknown
        case .folder:
            return (message.content as? FolderContent)?.fileSource ?? .unknown
        @unknown default:
            assertionFailure("unknown fileSource")
            return .unknown
        }
    }

    func onFileMessageClicked(message: Message, chat: Chat, window: UIWindow, downloadFileScene: RustPB.Media_V1_DownloadFileScene?, openFileBlock: @escaping (() -> Void)) {
        self.onFileOrFolderMessageClicked(message: message, chat: chat, window: window, downloadFileScene: downloadFileScene, openBlock: { [weak self] in
            guard let self = self else { return }
            if self.settingService?.staticFeatureGatingValue(with: "im.file.delete.by.script.toast") ?? false {
                openFileBlock()
                return
            }

            // 如果文件存在需要获取远端状态
            if self.isFileExist(message) {
                self.getFileStateAndJudgeOpenFile(message: message, window: window, downloadFileScene: downloadFileScene, openBlock: openFileBlock)
            } else {
                openFileBlock()
            }
        })
    }

    func onFolderMessageClicked(message: Message, chat: Chat, window: UIWindow, downloadFileScene: RustPB.Media_V1_DownloadFileScene?, openFolderBlock: @escaping (() -> Void)) {
        self.onFileOrFolderMessageClicked(message: message, chat: chat, window: window, downloadFileScene: downloadFileScene, openBlock: openFolderBlock)
    }

    private func onFileOrFolderMessageClicked(message: Message,
                                              chat: Chat,
                                              window: UIWindow,
                                              downloadFileScene: RustPB.Media_V1_DownloadFileScene?,
                                              openBlock: @escaping (() -> Void)) {
        // 局域网文件/文件夹不能交互
        if self.fileSource(message: message) == .lanTrans {
            return
        }
        switch message.fileDeletedStatus {
        case .normal:
            break
        case .recoverable:
            var authToken: String?
            if message.type == .file {
                authToken = (message.content as? FileContent)?.authToken
            } else if message.type == .folder {
                authToken = (message.content as? FolderContent)?.authToken
            }
            // 被管理员临时删除后可能会恢复，需要调用getFileState主动获取push，保证下次的状态是最新的
            self.fileAPI?.getFileStateRequest(messageId: message.id,
                                              sourceType: message.sourceType,
                                              sourceID: message.sourceID,
                                              authToken: authToken,
                                              downloadFileScene: downloadFileScene)
                .subscribe().disposed(by: self.disposeBag)
            UDToast.showTips(with: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days, on: window)
            return
        case .unrecoverable:
            UDToast.showTips(with: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days, on: window)
            return
        case .recalled:
            UDToast.showTips(with: BundleI18n.LarkFile.Lark_Legacy_FileWithdrawTip, on: window)
            return
        case .freedUp:
            UDToast.showTips(with: BundleI18n.LarkFile.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, on: window)
            return
        @unknown default:
            fatalError("unknown enum")
        }

        if message.localStatus != .success {
            return
        }
        openBlock()
    }

    private func isFileExist(_ message: Message) -> Bool {
        guard let fileContent = (message.content as? FileContent) else { return false }
        let key = fileContent.key
        let name = fileContent.name
        let fileRelativePath = key.kf.md5.appending("/" + name)
        let fileLocalPath = message.isCryptoMessage ?
            fileContent.cacheFilePath : fileDownloadCache(userResolver.userID).filePath(forKey: fileRelativePath)
        return Path(fileLocalPath).exists
    }

    private var requestingSet: SafeSet<String> = SafeSet<String>([], synchronization: .semaphore)

    private func getFileStateAndJudgeOpenFile(message: Message, window: UIWindow, downloadFileScene: RustPB.Media_V1_DownloadFileScene?, openBlock: @escaping (() -> Void)) {
        guard !requestingSet.contains(message.id) else {
            return
        }
        self.requestingSet.insert(message.id)
        self.tryToShowLoading(message, on: window)
        var authToken: String?
        if message.type == .file {
            authToken = (message.content as? FileContent)?.authToken
        } else if message.type == .folder {
            authToken = (message.content as? FolderContent)?.authToken
        }
        // 有缓存,此时需要调用获取文件状态，若文件可用则直接使用否则报错
        self.fileAPI?.getFileStateRequest(messageId: message.id,
                                          sourceType: message.sourceType,
                                          sourceID: message.sourceID,
                                          authToken: authToken,
                                          downloadFileScene: downloadFileScene)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (state) in
                guard let `self` = self else { return }
                self.removeLoadingHudAndResetFlag(message, on: window)
                switch state {
                case .normal:
                    openBlock()
                case .deleted:
                    UDToast.showTips(with: BundleI18n.LarkFile.Lark_Legacy_FileWithdrawTip, on: window)
                case .recoverable:
                    UDToast.showTips(with: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days, on: window)
                case .unrecoverable:
                    UDToast.showTips(with: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days, on: window)
                case .freedUp:
                    UDToast.showTips(with: BundleI18n.LarkFile.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, on: window)
                @unknown default:
                    fatalError("unknown")
                }

            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                self.removeLoadingHudAndResetFlag(message, on: window)
                // 当服务出现错误，直接放过
                openBlock()
                self.logger.error("getFileStateRequest error, error = \(error)")
            }).disposed(by: self.disposeBag)
    }

    private func tryToShowLoading(_ message: Message, on window: UIWindow?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak window, weak self] in
            guard self?.requestingSet.contains(message.id) == true,
                  let window = window else { return }
            UDToast.showLoading(on: window)
        }
    }

    private func removeLoadingHudAndResetFlag(_ message: Message, on window: UIWindow?) {
        if let window = window {
            UDToast.removeToast(on: window)
        }
        self.requestingSet.remove(message.id)
    }
}
