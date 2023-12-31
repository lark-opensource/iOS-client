//
//  EmotionShopAssembly.swift
//  LarkMessageCore
//
//  Created by huangjianming on 2019/8/11.
//

import Foundation
import EENavigator
import Swinject
import RxSwift
import LarkAlertController
import LarkSetting
import LarkMessengerInterface
import RustPB
import LarkNavigator

final class EmotionShopListHandler: UserTypedRouterHandler {
    func handle(_ body: EmotionShopListBody, req: EENavigator.Request, res: Response) throws {
        let viewModel = EmotionShopViewModel(userResolver: self.userResolver)
        let vc = EmotionShopViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}

final class EmotionShopDetailHandler: UserTypedRouterHandler {
    func handle(_ body: EmotionShopDetailBody, req: EENavigator.Request, res: Response) throws {
        let viewModel = EmotionShopDetailViewModel(stickerSetID: body.stickerSet.stickerSetID, userResolver: self.userResolver)
        let vc = EmotionDetailViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}

final class EmotionShopDetailWithSetIDHandler: UserTypedRouterHandler {
    func handle(_ body: EmotionShopDetailWithSetIDBody, req: EENavigator.Request, res: Response) throws {
        //先从body取值,再从url里面取值
        let setID = body.stickerSetID
        guard !setID.isEmpty else {
            return
        }
        let viewModel = EmotionShopDetailViewModel(stickerSetID: setID, userResolver: self.userResolver)
        let vc = EmotionDetailViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}

final class EmotionSettingHandler: UserTypedRouterHandler {
    func handle(_ body: EmotionSettingBody, req: EENavigator.Request, res: Response) throws {
        let viewModel = EmotionSettingTableViewModel(userResolver: self.userResolver)
        let vc = EmotionSettingViewController(viewModel: viewModel, showType: body.showType)
        res.end(resource: vc)
    }
}

final class EmotionSingleDetailHandler: UserTypedRouterHandler {
    func handle(_ body: EmotionSingleDetailBody, req: EENavigator.Request, res: Response) throws {
        let viewModel = EmotionSingleDetailViewModel(stickerSet: body.stickerSet,
                                                     stickerSetID: body.stickerSetID,
                                                     sticker: body.sticker,
                                                     message: body.message,
                                                     userResolver: self.userResolver
                                                     )
        let vc = EmotionSingleDetailViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}

final class StickerManagerHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { MessageCore.userScopeCompatibleMode }

    func handle(_ body: StickerManagerBody, req: EENavigator.Request, res: Response) throws {
        let stickerManageVC = StickerManageViewController(showType: body.showType, userResolver: self.userResolver)
        res.end(resource: stickerManageVC)
    }
}
