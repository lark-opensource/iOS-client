//   
//  KeyValue.swift
//  LarkEmotionKeyboard
//
//  Created by 李昊哲 on 2022/12/20.
//  

import Foundation
import LarkStorage

/// 存放一些 **跨模块共享/Public** 的 KV 数据
public extension KVPublic {

    /// Emotion 相关
    public struct Emotion {
        static let domain = Domain.biz.messenger.child("Emotion")

        public static let customEmotion = KVKey("CustomEmotionKey", default: "0")
            .config(domain: domain, type: Global.self)
    }

}

