//
//  ReactionSkinTonesAPI.swift
//  LarkEmotionKeyboard
//
//  Created by bytedance on 2022/1/19.
//
import Foundation
import RxSwift
public protocol ReactionSkinTonesAPI {
    /// 更新表情的肤色
    func updateReactionSkin(defaultReactionKey: String, skinKey: String) -> Observable<Void>
}
