//
//  AttachmentPreviewProvider.swift
//  LarkMail
//
//  Created by tefeng liu on 2021/11/2.
//

import Foundation
import MailSDK
import SpaceInterface
import Swinject
import RxSwift
import EENavigator
import LarkContainer

class AttachmentPreviewProvider {
    private let resolver: UserResolver
    private var moreAction: DriveMoreActionProtocol? {
        return try? resolver.resolve(assert: DriveMoreActionProtocol.self)
    }
    init(resolver: UserResolver) {
        self.resolver = resolver
    }
}
extension MailSDK.DKAttachmentInfo {
    var toCCM: SpaceInterface.DKAttachmentInfo {
        return SpaceInterface.DKAttachmentInfo(fileID: fileID, name: name, type: type, size: size)
    }
}

extension MailSDK.DriveAttachmentInfo {
    var toCCM: SpaceInterface.DriveAttachmentInfo {
        return SpaceInterface.DriveAttachmentInfo(token: token, name: name, type: type, size: size, localPath: localPath)
    }
}

extension MailSDK.CustomMoreActionProviderImpl {
    var toCCM: SpaceCustomMoreActionProviderImpl {
        return SpaceCustomMoreActionProviderImpl(actionId: actionId, text: text, handler:  { vc, info in
            handler(vc, info.toMailDK)
        })
    }
}

extension SpaceInterface.DriveAttachmentInfo {
    var toMail: MailSDK.DriveAttachmentInfo {
        return MailSDK.DriveAttachmentInfo(token: token, name: name, type: type, size: size, localPath: localPath)
    }
}

extension SpaceInterface.DKAttachmentInfo {
    var toMailDK: MailSDK.DKAttachmentInfo {
        return MailSDK.DKAttachmentInfo(fileID: fileID, name: name, type: type, size: size, localPath: localPath)
    }
    var toMail: MailSDK.DriveAttachmentInfo {
        return self.driveInfo.toMail
    }
}

struct SpaceCustomMoreActionProviderImpl: SpaceInterface.DriveSDKCustomMoreActionProvider {
    var actionId: String
    var text: String
    var handler: (UIViewController, SpaceInterface.DKAttachmentInfo) -> Void
}

struct MailClientDependencyImpl: DriveSDKDependency {
    let more: MoreDependencyImpl
    let action = ActionDependencyImpl()
    var actionDependency: DriveSDKActionDependency {
        return action
    }
    var moreDependency: DriveSDKMoreDependency {
        return more
    }

    init(mailLocalFile: MailSDK.DriveLocalFileEntity) {
        self.more = MoreDependencyImpl(actions: mailLocalFile.actions.compactMap{ $0.toCCM2 })
    }

    init(mailOnlineFile: MailSDK.DriveThirdPartyFileEntity) {
        self.more = MoreDependencyImpl(actions: mailOnlineFile.actions.compactMap{ $0.toCCM2 })
    }
}

struct MoreDependencyImpl: DriveSDKMoreDependency {
    var moreMenuVisable: Observable<Bool> {
        return .just(true)
    }
    var moreMenuEnable: Observable<Bool> {
        return .just(true)
    }
    let actions: [DriveSDKMoreAction]
}

struct ActionDependencyImpl: DriveSDKActionDependency {
    var uiActionSignal: RxSwift.Observable<SpaceInterface.DriveSDKUIAction> {
        return actionSubject.compactMap{ $0.toCCM2 }
    }
    var actionSubject = PublishSubject<MailDriveSDKUIAction>()

    private var closeSubject = PublishSubject<Void>()
    private var stopSubject = PublishSubject<Reason>()
    var closePreviewSignal: Observable<Void> {
        return closeSubject.asObserver().debug("mailClient closePreview")
    }

    var stopPreviewSignal: Observable<Reason> {
        return stopSubject.asObserver().debug("mailClient stopPreview")
    }
}

extension MailSDK.DriveLocalFileEntity {
    var toCCM2: SpaceInterface.DriveSDKLocalFileV2 {
        return SpaceInterface.DriveSDKLocalFileV2(fileName: name ?? "",
                                                  fileType: fileType,
                                                  fileURL: fileURL,
                                                  fileId: fileURL.absoluteString,
                                                  dependency: MailClientDependencyImpl(mailLocalFile: self))
    }
}

extension MailSDK.DriveThirdPartyFileEntity {
    var toCCM2: SpaceInterface.DriveSDKAttachmentFile {
        let dependency = MailClientDependencyImpl(mailOnlineFile: self)
        var file = SpaceInterface.DriveSDKAttachmentFile(fileToken: fileToken,
                                                         mountNodePoint: mountNodePoint,
                                                         mountPoint: mountPoint,
                                                         fileType: fileType,
                                                         name: nil,
                                                         authExtra: authExtra,
                                                         dependency: dependency)
        file.handleBizPermission = handleBizPermission(dependency.action.actionSubject)
        return file
    }
}

extension MailSDK.DriveAlertVCAction {
    var toCCM2: SpaceInterface.DriveSDKMoreAction? {
        var action: SpaceInterface.DriveSDKMoreAction?
        switch self {
        case .openWithOtherApp(let callback):
            action = .customOpenWithOtherApp(customAction: nil, callback: {info, appID, isSuccess  in
                let mailInfo = info.toMail
                callback?(mailInfo, appID, isSuccess)
            })
        case .saveToSpace:
            action = .saveToSpace(handler: { state in

            })
        case .forward(handler: let handler):
            action = .forward(handler: { vc, info in
                handler(vc, info.toMail)
            })
        case .saveToLocal(handler: let handler):
            action = .saveToLocal(handler: { vc, info in
                handler(vc, info.toMail)
            })
        case .customUserDefine(impl:let impl):
            action = .customUserDefine(provider: impl.toCCM)
        @unknown default:
            break
        }
        return action
    }
}

extension MailSDK.MailDriveSDKUIAction {
    var toCCM2: SpaceInterface.DriveSDKUIAction? {
        var action: SpaceInterface.DriveSDKUIAction?
        switch self {
        case .showBanner(banner: let banner, bannerID: let bannerID):
            action = .showBanner(banner: banner, bannerID: bannerID)
        case .hideBanner(bannerID: let bannerID):
            action = .hideBanner(bannerID: bannerID)
        @unknown default:
            break
        }
        return action
    }
}

extension AttachmentPreviewProvider: AttachmentPreviewProxy {
    func saveToSpace(fileObjToken: String, fileSize: UInt64, fileName: String, sourceController: UIViewController) {
        moreAction?.saveToSpace(fileObjToken: fileObjToken, fileSize: fileSize, fileName: fileName, sourceController: sourceController)
    }
    
    func saveToLocal(fileSize: UInt64,
                     fileObjToken: String,
                     fileName: String,
                     sourceController: UIViewController) {
        moreAction?.saveToLocal(fileSize: fileSize, fileObjToken: fileObjToken, fileName: fileName, sourceController: sourceController)
    }
    
    func openDriveFileWithOtherApp(fileSize: UInt64, fileObjToken: String, fileName: String, sourceController: UIViewController) {
        moreAction?.openDriveFileWithOtherApp(fileSize: fileSize, fileObjToken: fileObjToken, fileName: fileName, sourceController: sourceController)
    }
    
    var emailAppID: String {
        return "10"
    }
    
    func driveThirdPartyActtachController(files: [MailSDK.DriveThirdPartyFileEntity],
                                          index: Int,
                                          from: UIViewController) {
        let config = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: false)
        let body = DriveSDKAttachmentFileBody(files: files.map({ $0.toCCM2 }),
                                              index: index,
                                              appID: emailAppID,
                                              naviBarConfig: config)
        resolver.navigator.push(body: body, naviParams: nil, from: from, animated: true, completion: nil)
    }
    
    func driveLocalFileController(files: [MailSDK.DriveLocalFileEntity], index: Int, from: UIViewController) {
        let config = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: false)
        let body = DriveSDKLocalFileBody(files: files.map({ $0.toCCM2 }),
                                         index: 0,
                                         appID: emailAppID,
                                         thirdPartyAppID: nil,
                                         naviBarConfig: config)
        resolver.navigator.push(body: body, naviParams: nil, from: from, animated: true, completion: nil)
    }
}
