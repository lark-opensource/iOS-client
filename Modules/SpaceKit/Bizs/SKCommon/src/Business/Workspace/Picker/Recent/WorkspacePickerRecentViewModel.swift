//
//  WorkspacePickerRecentViewModel.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/9/28.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SpaceInterface

class WorkspacePickerRecentViewModel {

    private let action: WorkspacePickerAction
    private let filter: WorkspacePickerNetworkAPI.RecentFilter
    private let networkAPI: WorkspacePickerNetworkAPI.Type
    private let disposeBag = DisposeBag()

    convenience init(config: WorkspacePickerConfig) {
        let networkAPI: WorkspacePickerNetworkAPI.Type
        if config.usingLegacyRecentAPI {
            networkAPI = WorkspacePickerLegacyNetworkAPI.self
        } else {
            networkAPI = WorkspacePickerStandardNetworkAPI.self
        }
        self.init(config: config, networkAPI: networkAPI)
    }

    convenience init(config: WorkspacePickerConfig,
                     networkAPI: WorkspacePickerNetworkAPI.Type) {
        let filter: WorkspacePickerNetworkAPI.RecentFilter
        if config.entrances.contains(.wiki) && config.entrances.contains(.mySpace) {
            filter = .all
        } else if config.entrances.contains(.wiki) {
            filter = .wikiOnly
        } else {
            filter = .spaceOnly
        }
        self.init(action: config.action, filter: filter, networkAPI: networkAPI)
    }

    // 供单测用的完整初始化方法
    init(action: WorkspacePickerAction,
         filter: WorkspacePickerNetworkAPI.RecentFilter,
         networkAPI: WorkspacePickerNetworkAPI.Type) {
        self.action = action
        self.filter = filter
        self.networkAPI = networkAPI
    }

    func reload() -> Single<[WorkspacePickerRecentEntry]> {
        networkAPI.loadRecentEntries(action: action, filter: filter)
    }
}
