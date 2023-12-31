//
//  TeamMemberViewModel+.swift
//  LarkTeam
//
//  Created by 夏汝震 on 2021/12/15.
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

// MARK: 身份及权限的判断及管理
extension TeamMemberViewModel {
    func isShowRemoveMode() -> Bool {
        guard let team = team, datas.count > 1, team.isTeamManagerForMe else { return false }
        return true
    }

    // item在这个团队里的角色
    func isMeForItem(cellVM: TeamMemberCellVM) -> Bool {
        return cellVM.isChatter && cellVM.itemId == currentUserId
    }

    // 过滤掉自己和群组
    func otherMembers(cellVM: TeamMemberCellVM) -> Bool {
        return cellVM.isChatter && cellVM.itemId != currentUserId
    }
}
