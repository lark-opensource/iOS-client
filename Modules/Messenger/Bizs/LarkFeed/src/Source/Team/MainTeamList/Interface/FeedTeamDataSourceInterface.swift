//
//  FeedTeamDataSource+Interface.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/18.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkSDKInterface
import RustPB
import UniverseDesignToast
import ThreadSafeDataStructure
import RunloopTools
import LKCommonsLogging
import LarkPerf
import LarkModel
import LarkBizAvatar
import LarkBadge

protocol FeedTeamDataSourceInterface {
    var teamModels: [FeedTeamItemViewModel] { get }
    var dataFrom: DataFrom { get set }
    var dataState: DataState { get set }
    var renderType: RenderType { get set }

    // MARK: 一级列表的数据处理
    func getTeam(teamItem: Basic_V1_Item) -> FeedTeamItemViewModel?
    func getChat(chatItem: Basic_V1_Item) -> FeedTeamChatItemViewModel?
    func getTeamIndex(teamItem: Basic_V1_Item) -> Int?
    func getChatIndexPath(chatItem: Basic_V1_Item) -> IndexPath?

    func getTeam(section: Int) -> FeedTeamItemViewModel?
    func getChat(indexPath: IndexPath) -> FeedTeamChatItemViewModel?

    mutating func updateTeams(teamItems: [Basic_V1_Item],
                              teamEntities: [Int: Basic_V1_Team])
    mutating func updateTeamEntities(_ teamEntities: [Int: Basic_V1_Team])

    mutating func removeTeams(_ teamItemIds: [Int])
    mutating func removeAllTeams()

    // MARK: 二级列表的数据处理
    mutating func updateChats(chatItems: [Int: [RustPB.Basic_V1_Item]],
                              chatEntities: [Int: FeedPreview])
    mutating func updateChatItems(_ chatItems: [Basic_V1_Item])

    mutating func removeChats(_ chatItems: [Basic_V1_Item])

    mutating func updateBadgeStyle()

    // MARK: UI 交互
    mutating func updateTeamExpanded(_ teamItemId: Int, isExpanded: Bool)
    mutating func updateChatSelected(_ chatEntityId: String?)

    var description: String { get }
    var uiDescription: String { get }

    // 移除隐藏的chat
    mutating func removeHidenChats()

    // 移除非隐藏的chat
    mutating func removeShownChats()
}
