//
//  EmotionShopAssembly.swift
//  LarkMessageCore
//
//  Created by huangjianming on 2019/8/12.
//

import Foundation
import Swinject
import RxSwift
import EENavigator
import LarkMessengerInterface
import LarkAssembler

public final class EmotionShopAssembly: LarkAssemblyInterface {
    public init() {}

    public func registRouter(container: Container) {
        //表情商店
        Navigator.shared.registerRoute.type(EmotionShopListBody.self).factory(EmotionShopListHandler.init)

        //表情商店详情
        Navigator.shared.registerRoute.type(EmotionShopDetailBody.self).factory(EmotionShopDetailHandler.init)

        //表情商店详情(用于只有setid的情况)
        Navigator.shared.registerRoute.type(EmotionShopDetailWithSetIDBody.self).factory(EmotionShopDetailWithSetIDHandler.init)

        //表情设置页面
        Navigator.shared.registerRoute.type(EmotionSettingBody.self).factory(EmotionSettingHandler.init)

        //单个表情页面
        Navigator.shared.registerRoute.type(EmotionSingleDetailBody.self).factory(EmotionSingleDetailHandler.init)

        Navigator.shared.registerRoute.type(StickerManagerBody.self).factory(StickerManagerHandler.init)
    }
}
