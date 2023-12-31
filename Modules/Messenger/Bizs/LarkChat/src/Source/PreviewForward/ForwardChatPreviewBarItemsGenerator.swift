//
//  ForwardChatPreviewBarItemsGenerator.swift
//  LarkChat
//
//  Created by ByteDance on 2022/9/13.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignToast
import RxSwift
import EENavigator
import LarkModel
import LarkAlertController
import LarkCore
import LarkSDKInterface
import LarkMessengerInterface

final class ForwardChatPreviewBarItemsGenerator: RightBarButtonItemsGenerator {
    //仅提供视图，手势在相应VC中
    private let disposeBag = DisposeBag()
    public var groupMemberItem: LKBarButtonItem = LKBarButtonItem(image: Resources.suspend_icon_group)

    func rightBarButtonItems() -> [UIBarButtonItem] {
        var items: [UIBarButtonItem] = []
        groupMemberItem.button.contentHorizontalAlignment = .right
        items.append(groupMemberItem)
        return items
    }
}
