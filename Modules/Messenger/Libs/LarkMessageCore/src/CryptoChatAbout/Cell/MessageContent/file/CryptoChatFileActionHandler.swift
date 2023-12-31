//
//  CryptoChatFileActionHandler.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/5/21.
//

import RxSwift
import RxRelay
import LarkCore
import LarkModel
import LarkMessageBase
import LKCommonsLogging
import LarkFeatureGating
import UniverseDesignToast
import LarkMessengerInterface
import LarkSDKInterface

private typealias Path = LarkSDKInterface.PathWrapper

private let logger = Logger.log(NSObject(), category: "LarkMessageCore.cell.FileContentActionHandler")

public final class CryptoChatFileActionHandler<C: PageContext>: FileAndFolderContentActionHandler<C> {
    /// 点击事件网络请求专用标记
    private var isRequesting = false
    private var canShowLoading = true

    public override func open(
        chat: Chat,
        message: Message,
        useLocalChat: Bool,
        canViewInChat: Bool,
        canForward: Bool,
        canSearch: Bool,
        canSaveToDrive: Bool,
        canOfficeClick: Bool
    ) {
        IMTracker.Chat.Main.Click.Msg.File(chat, message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        if self.context.getStaticFeatureGating("im.file.delete.by.script.toast") {
            self.openFile(message: message)
            return
        }
        // 如果文件存在需要获取远端状态
        if let content = message.content as? FileContent, Path(content.cacheFilePath).exists {
            self.getFileStateAndJudgeOpenFile(message: message)
        } else {
            self.openFile(message: message)
        }
    }

    private func getFileStateAndJudgeOpenFile(message: Message) {
        guard isRequesting == false,
              let window = self.context.targetVC?.view.window else {
            return
        }
        self.isRequesting = true
        self.tryToShowLoading()
        // 有缓存,此时需要调用获取文件状态，若文件可用则直接使用否则报错
        self.context.fileAPI?.getFileStateRequest(messageId: message.id,
                                                  sourceType: message.sourceType,
                                                  sourceID: message.sourceID,
                                                  authToken: (message.content as? FileContent)?.authToken,
                                                  downloadFileScene: context.downloadFileScene)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (state) in
                guard let `self` = self else { return }
                self.removeLoadingHudAndResetFlag()
                switch state {
                case .normal:
                    self.openFile(message: message)
                case .deleted:
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_Legacy_FileWithdrawTip, on: window)
                case .recoverable:
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days, on: window)
                case .unrecoverable:
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days, on: window)
                case .freedUp:
                    UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_ViewOrDownloadFile_FileDeleted_Text, on: window)
                @unknown default:
                    fatalError("unknown")
                }
                self.isRequesting = false
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                self.removeLoadingHudAndResetFlag()
                // 当服务出现错误，直接放过
                self.openFile(message: message)
                self.isRequesting = false
                logger.error("getFileStateRequest error, error = \(error)")
            }).disposed(by: self.disposeBag)
    }

    private func openFile(message: Message) {
        let body = MessageFileBrowseBody(message: message, scene: .chat, downloadFileScene: context.downloadFileScene, chatFromTodo: nil)
        context.navigator(type: .push, body: body, params: nil)
    }

    private func tryToShowLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard self.canShowLoading,
                  let window = self.context.targetVC?.view.window else { return }
            UDToast.showLoading(on: window)
        }
    }

    private func removeLoadingHudAndResetFlag() {
        if let window = self.context.targetVC?.view.window {
            UDToast.removeToast(on: window)
        }
        self.canShowLoading = false
    }
}
