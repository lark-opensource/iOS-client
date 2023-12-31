//
//  TextAvatarSettingViewModel.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/10/8.
//

import UIKit
import RxSwift
import RustPB
import LarkContainer
import LarkMessengerInterface

final class TextAvatarSettingViewModel {

    let userResolver: UserResolver
    let drawStyle: AvatarDrawStyle
    let defaultCenterIcon: UIImage
    var avatarMeta: RustPB.Basic_V1_AvatarMeta
    let chatId: String
    /// 服务端下发的颜色
    let config: ColorImageSettingConfig
    lazy var borderItems: [SolidColorPickItem] = {
        return self.config.borderIcons.map { element in
            SolidColorPickItem(key: element.key,
                               fsUnit: self.config.fsUnit,
                               startColorInt: element.startColorInt,
                               endColorInt: element.endColorInt)
        }
    }()

    lazy var fillItems: [SolidColorPickItem] = {
        return self.config.fillIcons.map { element in
            SolidColorPickItem(key: element.key,
                               fsUnit: self.config.fsUnit,
                               startColorInt: element.startColorInt,
                               endColorInt: element.endColorInt)
        }
    }()

    init(resolver: UserResolver,
         chatId: String,
         defaultCenterIcon: UIImage,
         drawStyle: AvatarDrawStyle,
         avatarMeta: RustPB.Basic_V1_AvatarMeta) {
        self.userResolver = resolver
        self.chatId = chatId
        self.defaultCenterIcon = defaultCenterIcon
        self.drawStyle = drawStyle
        self.avatarMeta = avatarMeta
        self.config = ColorImageSettingConfig(userResolver: resolver)
    }

    func resetFillItems() {
        self.fillItems.forEach { $0.selected = false }
    }

    func resetBorderItems() {
        self.borderItems.forEach { $0.selected = false }
    }

    func selectedFillItem(_ idx: Int?) -> SolidColorPickItem? {
        return self.selectedItem(idx, items: self.fillItems)
    }

    func selectedBorderItem(_ idx: Int?) -> SolidColorPickItem? {
        return self.selectedItem(idx, items: self.borderItems)
    }

    private func selectedItem(_ idx: Int?, items: [SolidColorPickItem]) -> SolidColorPickItem? {
        guard var idx = idx else {
            return nil
        }
        if idx > items.count - 1 {
            idx = 0
        }
        var selectedItem: SolidColorPickItem?
        for (index, item) in items.enumerated() {
            item.selected = (index == idx)
            if item.selected {
                selectedItem = item
            }
        }
        return selectedItem
    }
}
