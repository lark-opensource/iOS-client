//
//  FileNavigtaion.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/7/3.
//
//  File模块内部各种Controller构造方法

import Foundation
import LarkContainer
import RxSwift
import Swinject
import EENavigator
import LarkCore
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import WebKit
import WebBrowser
import SuiteAppConfig
import LarkAlertController
import LarkModel
import LarkFeatureGating
import LarkAssembler

public struct FileNavigationAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let userGraph = container.inObjectScope(File.userGraph)

        userGraph.register(FileBrowserController.self) { (r, file: FileMessageInfo, menuOptions: FileBrowseMenuOptions, context: [String: Any], fileViewOptions: FileViewOptions) in
            let pushCenter = try r.userPushCenter
            let saveToSpaceStoreStateDriver = pushCenter.driver(for: PushSaveToSpaceStoreState.self)
            let fileAPI = try r.resolve(assert: SecurityFileAPI.self)
            let favoriteAPI = try r.resolve(assert: FavoritesAPI.self)
            let messageAPI = try r.resolve(assert: MessageAPI.self)
            let appConfigService = try r.resolve(assert: AppConfigService.self)
            return try FileBrowserController(file: file,
                                             menuOptions: menuOptions,
                                             fileViewOptions: fileViewOptions,
                                             fileAPI: fileAPI,
                                             favoriteAPI: favoriteAPI,
                                             messageAPI: messageAPI,
                                             spaceStoreStateDriver: saveToSpaceStoreStateDriver,
                                             downloadFileDriver: pushCenter.driver(for: PushDownloadFile.self),
                                             messageDriver: pushCenter.driver(for: PushChannelMessage.self),
                                             fileNavigation: FileNavigation(resolver: r),
                                             context: context,
                                             appConfigService: appConfigService,
                                             resolver: r)
        }

        userGraph.register(LocalFileViewController.self) { (r, config: LocalFileViewControllerConfig) in
            let appConfigService = try r.resolve(assert: AppConfigService.self)

            return LocalFileViewController(
                config: config,
                appConfigService: appConfigService,
                userResolver: r
            )
        }
    }
}

struct FileNavigation {

    let resolver: UserResolver
    let disposeBag: DisposeBag = DisposeBag()

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func fileBrowserController(file: FileMessageInfo,
                               menuOptions: FileBrowseMenuOptions,
                               fileViewOptions: FileViewOptions,
                               context: [String: Any]) throws -> FileBrowserController {
        return try resolver.resolve(assert: FileBrowserController.self, arguments:
                                        file, menuOptions, context, fileViewOptions)
    }

    func localFileViewController(config: LocalFileViewControllerConfig) throws -> LocalFileViewController {
        return try resolver.resolve(assert: LocalFileViewController.self, argument: config)
    }

    func goChat(messageId: String, from: NavigatorFrom) {
        let messageApi = try? resolver.resolve(assert: MessageAPI.self)
        messageApi?.fetchLocalMessage(id: messageId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (message) in
                let body = ChatControllerByIdBody(
                    chatId: message.channel.id,
                    position: message.position,
                    fromWhere: .search
                )
                resolver.navigator.push(body: body, from: from)
            }).disposed(by: disposeBag)
    }

    func gotoForward(messageId: String, from: NavigatorFrom) {
        let messageApi = try? resolver.resolve(assert: MessageAPI.self)
        messageApi?.fetchMessage(id: messageId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (message) in
                let body = ForwardMessageBody(originMergeForwardId: nil,
                                              message: message,
                                              type: .message(message.id),
                                              from: .file)
                resolver.navigator.present(
                    body: body,
                    from: from,
                    prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
                )
            })
            .disposed(by: disposeBag)
    }

    func checkFileDeletedStatus(with message: Message, from: NavigatorFrom) -> Bool {
        // 判断文件删除状态
        switch message.fileDeletedStatus {
        case .normal:
            return true
        // 文件被删除，可被管理员恢复
        case .recoverable:
            self.showAlert(
                message: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days,
                from: from
            )
            return false
        // 文件彻底被删除
        case .unrecoverable:
            self.showAlert(
                message: BundleI18n.LarkFile.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days,
                from: from
            )
            return false
        case .recalled:
            self.showAlert(
                title: BundleI18n.LarkFile.Lark_Legacy_Hint,
                message: BundleI18n.LarkFile.Lark_Legacy_FileWithdrawTip,
                from: from
            )
            return false
        case .freedUp:
            self.showAlert(message: BundleI18n.LarkFile.Lark_IM_ViewOrDownloadFile_FileDeleted_Text,
                           from: from)
            return false
        @unknown default:
            assertionFailure()
            return false
        }
    }

    private func showAlert(title: String? = nil, message: String, from: NavigatorFrom) {
        let alertController = LarkAlertController()
        if let title = title {
            alertController.setTitle(text: title)
        }
        alertController.setContent(text: message)
        alertController.addPrimaryButton(text: BundleI18n.LarkFile.Lark_Legacy_Sure)
        resolver.navigator.present(alertController, from: from)
    }
}
