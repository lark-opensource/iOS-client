//
//  TrackShortcutActionData.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/11/20.
//

import UIKit
import Foundation
import AppReciableSDK

final class TrackShortcutActionData {

    enum ShortcutAction: Int {
      case add = 1 // 点击置顶
      case delete = 2 // 取消置顶
    }

    let id: String
    let action: ShortcutAction
    let disposedKey: DisposedKey
    var sdkCost: TimeInterval?  // sdk接口耗时
    var updated: Bool = false // 渲染是否完成

    private var start: CFTimeInterval?

    init(id: String,
         action: ShortcutAction,
         disposedKey: DisposedKey) {
        self.id = id
        self.action = action
        self.disposedKey = disposedKey
        start = CACurrentMediaTime() // 开始计时
    }

    /// 停止计时
    func end() {
        guard let start = self.start else { return }
        let end = CACurrentMediaTime()
        sdkCost = (end - start) * 1000
        self.start = nil
    }
}
