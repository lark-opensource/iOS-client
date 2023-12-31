//
//  FavoriteVMDataProvider.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2018/6/19.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import LarkContainer
import RxSwift
import LarkCore
import Swinject
import RxCocoa
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import TangramService

final class FavoriteVMDataProvider: FavoriteDataProvider {
    let userResolver: UserResolver

    let audioPlayer: AudioPlayMediator
    let favoriteAPI: FavoritesAPI
    let audioResourceService: AudioResourceService

    var deleteFavoritesPush: Observable<[String]> {
        return (try? resolver.userPushCenter)?.observable(for: PushDeleteFavorites.self).map { (message) -> [String] in
            return message.favoriteIds
        } ?? .empty()
    }

    var refreshObserver = PublishSubject<Void>()

    var abbreviationEnable: Bool {
        let enterpriseEntityService = try? resolver.resolve(assert: EnterpriseEntityWordService.self)
        return enterpriseEntityService?.abbreviationHighlightEnabled() ?? false
    }

    let checkIsMe: CheckIsMe
    lazy var is24HourTime: Driver<Bool> = {
        return (try? resolver.resolve(assert: UserGeneralSettings.self))?.is24HourTime.asDriver() ?? .just(Date.lf.is24HourTime)
    }()

    let inlinePreviewVM: MessageInlineViewModel

    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        self.favoriteAPI = try resolver.resolve(assert: FavoritesAPI.self)
        self.audioPlayer = try resolver.resolve(assert: AudioPlayMediator.self)
        self.audioResourceService = try resolver.resolve(assert: AudioResourceService.self)
        self.inlinePreviewVM = MessageInlineViewModel()
        let me = resolver.userID
        self.checkIsMe = { $0 == me }
    }
}
