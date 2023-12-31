//
//  RedPacketExclusiveAvatarListView.swift
//  LarkMessageCore
//
//  Created by zhaojiachen on 2021/11/26.
//

import UIKit
import Foundation
import LarkBizAvatar
import LarkModel

final class RedPacketExclusiveAvatarListView: UIView {
    func update(_ configs: [RedPacketExclusiveAvatarConfig]) {
        guard let subviews = self.subviews as? [BizAvatar] else { return }
        var idx = 0
        while idx < configs.count && idx < subviews.count {
            let config = configs[idx]
            let avatarView = subviews[idx]
            avatarView.frame = config.frame
            avatarView.setAvatarByIdentifier(config.entityId,
                                          avatarKey: config.avatarKey,
                                          avatarViewParams: .init(sizeType: .size(RedPacketExclusiveAvatarLayoutEngine.exclusiveAvatarSize)))
            idx += 1
        }
        for i in idx..<configs.count {
            let avatarView = BizAvatar()
            avatarView.layer.borderWidth = 1
            avatarView.layer.cornerRadius = 12
            avatarView.layer.ud.setBorderColor(UIColor.ud.yellow.alwaysLight)
            let config = configs[i]
            avatarView.frame = config.frame
            avatarView.setAvatarByIdentifier(config.entityId,
                                             avatarKey: config.avatarKey,
                                             avatarViewParams: .init(sizeType: .size(RedPacketExclusiveAvatarLayoutEngine.exclusiveAvatarSize)))
            self.addSubview(avatarView)
        }
        for i in idx..<subviews.count {
            subviews[i].removeFromSuperview()
        }
    }
}

struct RedPacketExclusiveAvatarConfig {
    var frame: CGRect = .zero
    var avatarKey: String = ""
    var entityId: String = ""
}

final class RedPacketExclusiveAvatarLayoutEngine {
    static let exclusiveAvatarSize: CGFloat = 24
    static let overlappingWidth: CGFloat = 4

    static func layout(_ chatters: [Chatter], containerWidth: CGFloat) -> [RedPacketExclusiveAvatarConfig] {
        var chatters = chatters.prefix(5)
        let displayNumber = chatters.count
        let offsetX: CGFloat = exclusiveAvatarSize - overlappingWidth
        let startX: CGFloat = (containerWidth - offsetX * CGFloat(displayNumber) - overlappingWidth) / 2
        var configs: [RedPacketExclusiveAvatarConfig] = []
        for (index, chatter) in chatters.enumerated() {
            configs.append(
                RedPacketExclusiveAvatarConfig(
                    frame: CGRect(x: startX + CGFloat(index) * offsetX, y: 0, width: exclusiveAvatarSize, height: exclusiveAvatarSize),
                    avatarKey: chatter.avatarKey,
                    entityId: chatter.id
                )
            )
        }
        return configs
    }
}
