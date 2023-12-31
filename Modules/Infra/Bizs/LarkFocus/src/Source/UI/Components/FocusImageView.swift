//
//  FocusImageView.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/10/8.
//

import Foundation
import UIKit
import LarkEmotion
import LarkFocusInterface

/// 展示个人状态图标的 ImageView，封装了失败重试策略
final class FocusImageView: UIImageView {

    /// 图片加载失败的重试次数，默认为 5
    var maximumRetryTimes: Int = 5

    /// 图片加载失败的最小重试间隔，第 n 次重试的时间间隔为 retryInterval * n^2，默认为 0.1
    var retryInterval: TimeInterval = 0.1

    private var currentIconKey: String?

    func config(with iconKey: String) {
        setIconKey(iconKey, currentRetryTimes: 1, fallbackIcon: EmotionResouce.placeholder, isNew: true)
    }

    func config(with focus: FocusStatus) {
        setIconKey(focus.iconKey, currentRetryTimes: 1, fallbackIcon: focus.defaultIcon, isNew: true)
    }

    private func setIconKey() {
        if let iconKey = self.currentIconKey {
            setIconKey(iconKey, currentRetryTimes: 1, isNew: true)
        } else {
            self.image = EmotionResouce.placeholder
        }
    }

    private func setIconKey(_ iconKey: String,
                            currentRetryTimes: Int,
                            fallbackIcon: UIImage? = nil,
                            isNew: Bool = true) {
        // 如果重试过程中，设置了新的 iconKey，则丢弃旧的 iconKey
        if !isNew, currentIconKey != iconKey { return }
        currentIconKey = iconKey
        // 如果到达最大重试次数，停止重试
        guard currentRetryTimes <= maximumRetryTimes else { return }
        if let icon = EmotionResouce.shared.imageBy(key: iconKey) {
            self.image = icon
        } else {
            fallbackIcon.map { image = $0 }
            // 退避策略：重试时间逐次增加（感觉暂时没必要做指数退避+随机间隔）
            let interval = retryInterval * TimeInterval(currentRetryTimes * currentRetryTimes)
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
                self?.setIconKey(iconKey, currentRetryTimes: currentRetryTimes + 1, isNew: false)
            }
        }
    }
}
