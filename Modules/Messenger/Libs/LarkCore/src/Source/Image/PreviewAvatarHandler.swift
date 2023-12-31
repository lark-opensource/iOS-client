//
//  PreviewAvatarHandler.swift
//  Lark
//
//  Created by liuwanlin on 2018/8/17.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import Swinject
import LarkMessengerInterface
import EENavigator
import LarkSDKInterface
import LarkAvatar
import LarkAccountInterface
import LarkAssetsBrowser
import LarkEnv
import LarkReleaseConfig
import LarkBizAvatar
import LKCommonsLogging
import LarkFeatureGating
import LKCommonsTracker
import Homeric
import RxSwift
import ByteWebImage
import SwiftyJSON
import LarkFoundation
import LarkRustClient
import LarkNavigator
import LarkContainer

open class PreviewAvatarHandler: UserTypedRouterHandler {

    static let logger = Logger.log(PreviewAvatarHandler.self, category: "Modules.LarkCore")

    public func handle(_ body: PreviewAvatarBody, req: EENavigator.Request, res: Response) throws {
        guard let vc = req.from.fromViewController else {
            assertionFailure()
            return
        }
        let userPushCenter = try userResolver.userPushCenter
        let rustClient = try userResolver.resolve(assert: RustService.self)
        let chatterManager = try userResolver.resolve(assert: ChatterManagerProtocol.self)
        let chatterAPI = try userResolver.resolve(assert: ChatterAPI.self)
        let passportUser = try userResolver.resolve(assert: PassportUserService.self)

        // 是否是国内环境
        var isInternal: Bool {
            // 海外版
            if ReleaseConfig.releaseChannel == "Oversea" { return false }
            // 国内动态环境是海外
            if !passportUser.isFeishuBrand { return false }
            return false // 关闭头像装饰功能
        }

        let topmostFrom = WindowTopMostFrom(vc: vc)
        let asset = LKDisplayAsset.createAsset(avatarKey: body.avatarKey,
                                               avatarViewParams: .defaultBig,
                                               chatID: body.entityId)
        asset.detectCanTranslate = false
        let userResolver = self.userResolver
        let actionHandler = try AssetBrowserActionHandlerFactory.handler(
            with: self.userResolver,
            shouldDetectFile: true,
            canTranslate: false,
            canImageOCR: false,
            onSaveImage: { imageAsset in
                try? self.userResolver.resolve(type: ChatSecurityAuditService.self)
                    .auditEvent(.saveImage(key: imageAsset.key),
                               isSecretChat: false)
            },
            onSaveVideo: { mediaInfoItem in
                try? self.userResolver.resolve(type: ChatSecurityAuditService.self)
                    .auditEvent(.saveVideo(key: mediaInfoItem.key),
                                isSecretChat: false)
            }
        )
        let controller: AvatarPreivewViewController
        switch body.scene {
        case .personalizedAvatar:
            var pushAvatarKey: () -> Observable<String> = { .empty() }
            var getAvatarChoreButtonObservable: () -> Observable<AvatarProcessItem?> = { .just(nil) }
            // fg开启并且是国内环境则去增加个性化头像的按钮
            if isInternal {
                let currentId = userResolver.userID
                let larkCoreAvatarDependency = try userResolver.resolve(assert: LarkCoreAvatarDependency.self)
                let pushChatter = userPushCenter.observable(for: PushChatters.self)
                pushAvatarKey = {
                    return pushChatter.flatMap { (push) -> Observable<String> in
                        if let chatter = push.chatters.first(where: { $0.id == currentId }) {
                            asset.key = chatter.avatarKey
                            return .just(chatter.avatarKey)
                        }
                        return .empty()
                    }
                }
                getAvatarChoreButtonObservable = {
                    return larkCoreAvatarDependency.fetchAvatarApplicationList(appVersion: Utils.appVersion,
                                                                               accessToken: passportUser.user.sessionKey ?? "")
                        .observeOn(MainScheduler.instance)
                        .flatMap { (apps) -> Observable<AvatarProcessItem?> in
                            // 目前的业务是取第一个应用直接跳转
                            guard let app = apps?.first else { return .just(nil) }
                            let button = AvatarProcessItem(labelText: BundleI18n.LarkCore.Lark_Profile_DecorateProfilePhoto) { _ in
                                // 埋点
                                Tracker.post(TeaEvent(Homeric.PROFILE_AVATAR_SETTING))
                                // 跳转小程序
                                guard let url = URL(string: app.openUrl) else {
                                    Self.logger.info("app'sopenUrl transform to swift URL failed")
                                    return
                                }
                                userResolver.navigator.open(url, from: topmostFrom)
                            }
                            return .just(button)
                        }
                }
            }
            let notifyAvatarChanged: ([String]) -> Void = { (urls) in
                guard !urls.isEmpty else { return }
                guard let chatterManager = try? userResolver.resolve(assert: ChatterManagerProtocol.self) else { return }
                let currentChatter = chatterManager.currentChatter
                currentChatter.avatarKey = urls[0]
                chatterManager.currentChatter = currentChatter
                userPushCenter.post(PushChatters(chatters: [currentChatter]))
            }

            let provider: UploadImageViewControllerProvider = { finish in
                let currentChatter = chatterManager.currentChatter
                let supportReset = currentChatter.id == body.entityId && !currentChatter.isDefaultAvatar
                return UploadImageViewController(
                    multiple: false,
                    max: 1,
                    imageUploader: AvatarImageUploader(chatterAPI: chatterAPI),
                    userResolver: userResolver,
                    crop: true,
                    supportReset: supportReset,
                    saveHandler: {
                        actionHandler.handleSaveAsset(asset, relatedImage: nil, saveImageCompletion: nil)
                    },
                    finish: {
                        finish($0, $1, $2)
                        notifyAvatarChanged($1)
                    }
                )
            }
            controller = AvatarPersonalizedViewController(
                assets: [asset],
                pageIndex: 0,
                getAvatarChoreButtonObservable: getAvatarChoreButtonObservable(),
                pushAvatarKey: pushAvatarKey(),
                entityId: body.entityId,
                provider: provider,
                actionHandler: actionHandler,
                rustService: try userResolver.resolve(assert: RustService.self),
                navigator: userResolver.navigator)
            Tracker.post(TeaEvent(Homeric.IM_AVATAR_MAIN_VIEW))
        case .simple:
            controller = AvatarPreivewViewController(
                assets: [asset],
                pageIndex: 0,
                actionHandler: actionHandler)

        }

        controller.getExistedImageBlock = { (_) -> UIImage? in
            return nil
        }
        controller.prepareAssetInfo = { (displayAsset) in
            var passThrough: ImagePassThrough?
            if !displayAsset.fsUnit.isEmpty {
                passThrough = ImagePassThrough()
                passThrough?.key = displayAsset.key
                passThrough?.fsUnit = displayAsset.fsUnit
            }
            return (LarkImageResource.avatar(key: displayAsset.key, entityID: body.entityId, params: .defaultBig),
                    passThrough, TrackInfo(scene: .ProfileAvatar, fromType: .avatar)) // 目前只有个人头像会用 PreviewAvatarBody
        }
        controller.isSavePhotoButtonHidden = true

        // 目前头像个性化页面需要跳转小程序, 因此包装成NavigationController
        if body.scene == .personalizedAvatar {
            let nav = AvatarPreviewNavigationController(rootViewController: controller)
            res.end(resource: nav)
            return
        }
        res.end(resource: controller)
    }
}

extension LarkCoreAvatarDependency {
    func fetchAvatarApplicationList(appVersion: String, accessToken: String) -> Observable<[AvatarApplication]?> {
        fetchRawAvatarApplicationList(appVersion: appVersion, accessToken: accessToken)
            .flatMap { (code: Int?, json: JSON) -> Observable<[AvatarApplication]?> in
                PreviewAvatarHandler.logger.info("getAvatarAppList success \(code ?? -1)")
                if let resultCode = code, resultCode == 0 {
                    if let dataModel = try? JSONDecoder().decode(AvatarAppListModel.self,
                                                                 from: json.rawData()) {
                        let avatarApplications = dataModel.data?.availableAppList?.map({ (model) -> AvatarApplication in
                            let avatarApplication = AvatarApplication(name: model.name ?? "",
                                                                      openUrl: model.mobileApplinkUrl ?? "")
                            return avatarApplication

                        })
                        return .just(avatarApplications).observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
                    } else {
                        let buildDataModelFailCode = -1
                        let buildDataModelFailMessage = "fetch data complete, parse to model failed"
                        let error = NSError(domain: "LarkAvatarDependecyImpl.fetchAvatarApplicationList",
                                            code: buildDataModelFailCode,
                                            userInfo: [NSLocalizedDescriptionKey: buildDataModelFailMessage])
                        PreviewAvatarHandler.logger.error("\(buildDataModelFailMessage)", error: error)
                    }
                } else {
                    let errCode = json["code"].intValue
                    let errMsg = json["msg"].stringValue
                    PreviewAvatarHandler.logger.error("fetchAvatarApplicationList failed with errCode: \(errCode), errMsg: \(errMsg)")
                }
                return .just(nil)
            }
            .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
    }
}

// 头像小程序的抽象模型
struct AvatarApplication {
    public var name: String
    public var openUrl: String
    public init(name: String,
                openUrl: String) {
        self.name = name
        self.openUrl = openUrl
    }
}

struct AvatarAppListModel: Codable {
    var msg: String?
    var data: AvatarAvailableAppListModel?
    var code: Int?
}

struct AvatarAvailableAppListModel: Codable {
    /// 最小刷新间隔
    var minUpdateInterval: Int?
    /// 可用应用list
    var availableAppList: [AvatarAppListCellModel]?
    var ts: Int?
}

/// 索引页面单个cell的数据
struct AvatarAppListCellModel: Codable {
    let appId: String
    let name: String?
    let desc: String?
    let icon: AvatarModel
    /// PC端AppLink
    let pcApplinkUrl: String?
    /// 移动端AppLink
    let mobileApplinkUrl: String?
}

/// 头像数据相关
struct AvatarModel: Codable {
    let key: String
    let fsUnit: String?
}
