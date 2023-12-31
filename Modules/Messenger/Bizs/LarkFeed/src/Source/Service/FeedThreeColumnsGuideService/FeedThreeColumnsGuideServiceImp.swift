//
//  FeedThreeColumnsGuideServiceImp.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/5/7.
//

import Foundation
import LarkMessengerInterface
import LarkOpenFeed
import RustPB

final class FeedThreeColumnsGuideServiceImp: FeedThreeColumnsGuideService {
    var context: FeedContextService?

    init(context: FeedContextService) {
        self.context = context
    }

    /// 触发移动端汉堡菜单引导气泡 (触发条件包括: 侧滑栏选中任一分组选项、未读Feed数量多于20、创建标签或标记)
    func triggerThreeColumnsGuide(scene: Feed_V1_ThreeColumnsSetting.TriggerScene) -> Bool {
        guard let mainVC = context?.page as? FeedMainViewController else { return false }
        let needGuide = mainVC.filterTabViewModel.filterFixedViewModel.updateThreeColumnsSettings(scene: scene)
        return needGuide
    }
}
