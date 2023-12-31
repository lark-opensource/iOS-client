//
//  LocationNavigateHandler.swift
//  LarkChat
//
//  Created by Fangzhou Liu on 2019/6/14.
//  Copyright © 2019 ByteDance Inc. All rights reserved.
//

import Foundation
import LarkMessengerInterface
import LarkModel
import LarkUIKit
import EENavigator
import Swinject
import LarkSDKInterface
import RxSwift
import UniverseDesignToast
import LarkLocationPicker
import LarkCoreLocation
import LarkNavigator
import LarkContainer

open class LocationNavigateHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { M.userScopeCompatibleMode }

    private let disposeBag: DisposeBag = DisposeBag()

    public func handle(_ body: LocationNavigateBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        /// 获得消息体
        let messageId = body.messageID
        let resolver = self.resolver
        if let message = body.message, let content = message.content as? LocationContent {
            let viewModel = LocationNavigateViewModel(
                message: message,
                content: content,
                isCrypto: body.fromCryptoChat,
                source: body.source,
                favoriteAPI: try resolver.resolve(assert: FavoritesAPI.self)
            )
            let authorization = try self.resolver.resolve(assert: LocationAuthorization.self)
            let targetVC = LocationNavigateViewController(userResolver: userResolver, viewModel: viewModel, forToken: PSDAToken(body.psdaToken, type: .location), authorization: authorization)
            res.end(resource: targetVC)
            return
        }
        let onError = { res.end(error: $0) }
        try resolver.resolve(assert: MessageAPI.self)
            .fetchMessage(id: messageId)
            .flatMap({ (message) -> Observable<(Message, LocationContent)> in
                if let content = message.content as? LocationContent {
                    return .just((message, content))
                }
                return .error(RouterError.invalidParameters("content is not LocationContent \(messageId)"))
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (message, content) in
              do {
                // 经纬度为空时直接返回, 否则空的经纬度会产生崩溃
                guard let self = self else { throw UserScopeError.disposed }
                if let locationContent = message.content as? LocationContent, locationContent.latitude.isEmpty || locationContent.longitude.isEmpty {
                    if let window = req.from.fromViewController?.view.window {
                        UDToast.showTips(with: BundleI18n.LarkChat.Lark_Legacy_LoadingFailed, on: window)
                    }
                    res.end(resource: nil)
                    return
                }
                let favoriteAPI = try resolver.resolve(assert: FavoritesAPI.self)
                let authorization = try self.resolver.resolve(assert: LocationAuthorization.self)
                let viewModel = LocationNavigateViewModel(
                    message: message,
                    content: content,
                    isCrypto: body.fromCryptoChat,
                    source: body.source,
                    favoriteAPI: favoriteAPI
                )
                let targetVC = LocationNavigateViewController(
                    userResolver: self.userResolver,
                    viewModel: viewModel, forToken: PSDAToken(body.psdaToken, type: .location), authorization: authorization)
                res.end(resource: targetVC)
              } catch {
                res.end(error: error)
              }
            }, onError: onError).disposed(by: self.disposeBag)

        res.wait()
    }
}

open class OpenLocationHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { M.userScopeCompatibleMode }
    public func handle(_ body: OpenLocationBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let name = body.name.isEmpty ? BundleI18n.LarkChat.Lark_Chat_MessageReplyStatusLocation("") : body.name
        let setting = LocationSetting(
            name: name,
            description: body.address,
            center: body.location,
            zoomLevel: body.zoomLevel,
            isCrypto: false,
            isInternal: body.type == .GCJ02,
            defaultAnnotation: true,
            needRightBtn: false
        )
        let authorization = try self.resolver.resolve(assert: LocationAuthorization.self)
        let targetVC = OpenLocationController(forToken: PSDAToken(body.psdaToken, type: .location), setting: setting, authorization: authorization)
        res.end(resource: targetVC)
    }
}

open class SendLocationHandler: UserTypedRouterHandler {
    static public func compatibleMode() -> Bool { M.userScopeCompatibleMode }

    public func handle(_ body: SendLocationBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let authorization = try self.resolver.resolve(assert: LocationAuthorization.self)
        let targetVC = LocationPickerViewController(forToken: PSDAToken(body.psdaToken, type: .location), authorization: authorization)
        targetVC.sendCallBack = body.sendAction
        res.end(resource: targetVC)
    }
}

open class ChooseLocationHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { M.userScopeCompatibleMode }

    public func handle(_ body: ChooseLocationBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let authorization = try self.resolver.resolve(assert: LocationAuthorization.self)
        let targetVC = ChooseLocationViewController(forToken: PSDAToken(body.psdaToken, type: .location), authorization: authorization)
        targetVC.cancelCallBack = body.cancelAction
        targetVC.sendLocationCallBack = { (chooseLocation) in
            let larkLocation = LarkLocation(
                name: chooseLocation.name,
                address: chooseLocation.address,
                location: chooseLocation.location,
                zoomLevel: chooseLocation.zoomLevel,
                image: chooseLocation.image,
                mapType: chooseLocation.mapType,
                selectType: chooseLocation.selectType
            )
            body.sendAction?(larkLocation)
        }
        res.end(resource: targetVC)
    }
}
