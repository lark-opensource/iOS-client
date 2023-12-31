//
//  FeedTeamViewModel+iPadSelection.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import Foundation
import RxSwift
import LarkUIKit

extension FeedTeamViewModel {
    /// 设置选中
    func setSelected(feedId: String?) {
        self.dependency.setSelected(feedId: feedId)
    }

    /// iPad选中态监听
    func observeSelect() -> Observable<String?> {
        self.dependency.observeSelect()
    }

    /// 是否需要跳过: 避免重复跳转
    func shouldSkip(feedId: String, traitCollection: UIUserInterfaceSizeClass?) -> Bool {
        return false
    }

    // 记录当前filter下，被选中的feedID
    func storeSelectedId() {
        guard FeedSelectionEnable else { return }
        selectedID = findCurrentSelectedId()
    }

    // 获取当前选中chatId
    func findCurrentSelectedId() -> String? {
        var selectedID: String?
        teamUIModel.teamModels.forEach { team in
             team.chatModels.forEach { chat in
                if chat.isSelected {
                    selectedID = chat.chatEntity.id
                    return
                }
             }
        }
        return selectedID
    }

    func findSelectedIndexPath() -> IndexPath? {
        guard let selectedID = self.selectedID else {
            return nil
        }
        var indexPath: IndexPath?
        for i in 0..<teamUIModel.teamModels.count {
            let team = teamUIModel.teamModels[i]
            for j in 0..<team.chatModels.count {
                let chat = team.chatModels[j]
                if chat.chatEntity.id == selectedID {
                    indexPath = IndexPath(row: j, section: i)
                    break
                }
            }
        }
        return indexPath
    }
}
