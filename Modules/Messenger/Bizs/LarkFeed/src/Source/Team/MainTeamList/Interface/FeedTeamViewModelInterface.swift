//
//  FeedTeamViewModelInterface.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/21.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkSDKInterface
import RustPB
import LarkModel
import LarkContainer

protocol FeedTeamViewModelInterface: UserResolverWrapper {
    var teamUIModel: FeedTeamDataSourceInterface { get }
    var dataSource: [FeedTeamItemViewModel] { get }
    var displayFooter: Bool { get }
    var dataSourceObservable: Observable<FeedTeamDataSourceInterface> { get }
    var loadingStateObservable: Observable<Bool> { get }
    var shouldLoading: Bool { get }
    func reload()

    var subTeamId: String? { get }
    func setSubTeamId(_ id: String?)

    var isActive: Bool { get }
    func willActive()
    func willResignActive()

    func updateTeamExpanded(_ teamItemId: Int, isExpanded: Bool, section: Int?)
    func updateChatSelected(_ chatEntityId: String?)

    func frozenDataQueue(_ taskType: FeedDataQueueTaskType)
    func resumeDataQueue(_ taskType: FeedDataQueueTaskType)

    func observeSelect() -> Observable<String?>
    func setSelected(feedId: String?)
    func shouldSkip(feedId: String, traitCollection: UIUserInterfaceSizeClass?) -> Bool
    func findSelectedIndexPath() -> IndexPath?

    func preloadDetail(_ chats: [FeedTeamChatItemViewModel])

    // 判断当前数据流是否被冻结
    func isQueueState() -> Bool

    // 透传，不需要vm参与逻辑
    var dependency: FeedTeamDependency { get }

    func hideChat(_ cellViewModel: FeedTeamChatItemViewModel, on window: UIWindow?)

    // 补偿兜底逻辑
    func fetchMissedChats(_ teamIds: [Int], dataFrom: DataFrom)
    var muteActionSetting: FeedSetting.FeedGroupActionSetting { get }
    var clearBadgeActionSetting: FeedSetting.FeedGroupActionSetting { get }
    var atAllSetting: FeedAtAllSetting { get }
}
