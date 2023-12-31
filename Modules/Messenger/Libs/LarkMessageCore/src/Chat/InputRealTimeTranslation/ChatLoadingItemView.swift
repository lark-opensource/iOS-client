//
//  ChatLoadingItemView.swift
//  LarkMessageCore
//
//  Created by bytedance on 2022/3/24.
//

import Foundation
import UIKit
///... 无限循环loading
final class ChatLoadingItemView: UILabel {
    func getSuggestWidth() -> CGFloat {
        let height = self.font.pointSize
        return "...".lu.width(font: self.font, height: height)
    }
    var repeatCount: Int = 0

    private lazy var timer: Timer = {
        let timer = Timer(timeInterval: 0.3,
                          target: self,
                          selector: #selector(updateText),
                          userInfo: nil,
                          repeats: true)
        RunLoop.current.add(timer, forMode: .common)
        timer.fireDate = Date.distantFuture
        return timer
    }()

    /// 开始loading
    func startLoading() {
        self.text = ""
        repeatCount = 0
        self.timer.fireDate = Date()
    }

    func stopLoading() {
        self.text = ""
        self.timer.fireDate = Date.distantFuture
    }

    func stop() {
        self.timer.invalidate()
    }

    /// 停止loading
    /// 重新开始loading
    @objc
    func updateText() {
        let arr = [".", "..", "..."]
        if repeatCount > arr.count - 1 {
            repeatCount = 0
        }
        self.text = arr[repeatCount]
        repeatCount += 1
    }
}
