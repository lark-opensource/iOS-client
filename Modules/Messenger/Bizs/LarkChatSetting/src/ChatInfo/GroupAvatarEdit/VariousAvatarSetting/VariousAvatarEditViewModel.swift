//
//  VariousAvatarEditViewModel.swift
//  LarkChatSetting
//
//  Created by liluobin on 2023/2/14.
//

import UIKit
import RxSwift
import RustPB
import LarkContainer
import LarkMessengerInterface

final class VariousAvatarEditViewModel: AvatarBaseViewModel {
    let avatarType: VariousAvatarType
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
         defaultCenterIcon: UIImage,
         drawStyle: AvatarDrawStyle,
         name: String?,
         avatarType: VariousAvatarType,
         avatarMetaObservable: Observable<RustPB.Basic_V1_AvatarMeta?>) {
        self.avatarType = avatarType
        self.config = ColorImageSettingConfig(userResolver: resolver)
        super.init(name: name,
                   defaultCenterIcon: defaultCenterIcon,
                   drawStyle: drawStyle,
                   resolver: resolver,
                   avatarMetaObservable: avatarMetaObservable)
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
