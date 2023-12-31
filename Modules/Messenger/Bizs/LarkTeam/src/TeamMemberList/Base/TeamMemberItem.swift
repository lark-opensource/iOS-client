//
//  TeamMemberItem.swift
//  LarkTeam
//
//  Created by 夏汝震 on 2022/8/3.
//

import Foundation
import RustPB
import RxSwift
import LarkTag
import RxCocoa
import LarkModel
import EENavigator
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignDialog
import LarkMessengerInterface
import LarkListItem

protocol TeamMemberItem {
    var itemId: String { get }
    var isChatter: Bool { get }
    var itemAvatarKey: String { get }
    var itemName: String { get }
    var realName: String { get }
    var itemDescription: String? { get }
    var itemTags: [Tag]? { get }
    var itemCellClass: AnyClass { get set }
    var isSelectedable: Bool { get set }
    var order: Int64 { get set }
}
