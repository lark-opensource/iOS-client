//
//  ThumbReactionService.swift
//  LarkMessageCore
//
//  Created by bytedance on 2022/1/26.
//

import Foundation
import UIKit
import LarkContainer
import LarkSDKInterface
import LarkEmotionKeyboard
import LarkEmotion
import RxSwift
import LarkSetting
import ThreadSafeDataStructure

public protocol ThumbsupReactionService: AnyObject {
    var thumbsupUpdate: PublishSubject<String> { get }
    var thumbsupKey: String { get }
}

public final class ThumbReactionServiceIMP: ThumbsupReactionService, UserResolverWrapper {
    public let userResolver: UserResolver

    public let thumbsupUpdate: PublishSubject<String> = .init()
    @ScopedInjectedLazy private var reactionService: ReactionService?
    private var thumbsupEntity: SafeAtomic<ReactionEntity?> = nil + .readWriteLock

    public var thumbsupKey: String {
        return self.thumbsupEntity.value?.selectSkinKey ?? EmotionResouce.ReactionKeys.thumbsup
    }
    private lazy var reactionListener: ReactionListener = {
        let listener = ReactionListener()
        listener.allReactionChangeHandler = { [weak self] in
            guard let self = self else {
                return
            }
            guard let oldEntity = self.thumbsupEntity.value,
                let newEntity = self.reactionService?.getReactionEntityFromOriginKey(EmotionResouce.ReactionKeys.thumbsup) else {
                    return
                }
            if oldEntity.selectSkinKey != newEntity.selectSkinKey {
                self.thumbsupEntity.value = newEntity
                self.thumbsupUpdate.onNext(newEntity.selectSkinKey)
            }
        }
        return listener
    }()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.thumbsupEntity.value = self.reactionService?.getReactionEntityFromOriginKey(EmotionResouce.ReactionKeys.thumbsup)
        let fgService = try? userResolver.resolve(assert: FeatureGatingService.self)
        if fgService?.staticFeatureGatingValue(with: "messenger.message_emoji_skinstones") ?? false {
            self.reactionService?.registReactionListener(self.reactionListener)
        }
    }
}
