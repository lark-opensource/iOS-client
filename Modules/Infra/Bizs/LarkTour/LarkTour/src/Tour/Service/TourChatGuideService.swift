//
//  TourChatGuideService.swift
//  LarkTour
//
//  Created by Meng on 2020/6/18.
//

import Foundation
import LarkTourInterface
import LarkContainer

struct ChatInputGuide {
    var title: String
    var detail: String
}

final class TourChatGuideManager: TourChatGuideService {
    private var chatGuides: [String: ChatInputGuide] = [:]

    /// 是否需要显示chat引导
    func needShowChatUserGuide(for chatId: String) -> Bool {
        /// note by hujinzang: 外部有依赖，暂时保留接口
        return false
    }

    /// 注册需要显示的chat引导，需要显式指定过期时间，单位秒
    func register(_ guide: ChatInputGuide, for chatId: String, expired: TimeInterval) {
        chatGuides[chatId] = guide
        DispatchQueue.main.asyncAfter(deadline: .now() + expired) { [weak self] in
            self?.chatGuides.removeValue(forKey: chatId)
        }
    }

    /// 手动remove chatGuide
    func removeGuideIfNeeded(for chatId: String) {
        chatGuides.removeValue(forKey: chatId)
    }

    /// 显示chatGuide
    func showChatUserGuideIfNeeded(
        with chatId: String,
        on targetRect: CGRect,
        completion: ((Bool) -> Void)?
    ) {
        /// note by hujinzang: 外部有依赖，暂时保留接口
        completion?(false)
    }
}
