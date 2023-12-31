//
//  FeedTeamViewModel+StoreTeamExpandedState.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/21.
//

import UIKit
import Foundation

extension FeedTeamViewModel {
    func observeApplicationNotification() {
        NotificationCenter.default.rx
            .notification(UIApplication.didEnterBackgroundNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.saveTeamsExpandedState()
            }).disposed(by: disposeBag)
    }

    func handleTeamLastExpandedState() {
        guard let map = getLastTeamsExpandedState() else {
            return
        }
        map.forEach { (key: Int, value: Bool) in
            self.updateTeamExpanded(key, isExpanded: value, section: nil)
        }
    }

    private func getLastTeamsExpandedState() -> [Int: Bool]? {
        return FeedKVStorage(userId: userId).getLastTeamsExpandedState()
    }

    private func saveTeamsExpandedState() {
        var map = [Int: Bool]()
        self.teamUIModel.teamModels.forEach { team in
            map[Int(team.teamItem.id)] = team.isExpanded
        }
        FeedKVStorage(userId: userId).saveTeamsExpandedState(map)
    }
}
