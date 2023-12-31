//
//  GroupCardJoinViewModelProtocol.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/6/6.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import RxCocoa
import LarkCore
import LarkUIKit
import RxRelay
import LarkSDKInterface
import LarkMessengerInterface

typealias JoinStatusCallback = (JoinGroupApplyBody.Status) -> Void

protocol GroupCardJoinViewModelProtocol: AnyObject {
    typealias LoadJoinDataResult = ([GroupCardCellItem], Observable<([GroupCardCellItem], Chatter?)>?)

    var joinStatusRelay: BehaviorRelay<JoinGroupApplyBody.Status> { get }
    var chatId: String { get }
    var chat: Chat { get }
    var avatarKey: String? { get }
    var owner: Chatter? { get }
    var ownerId: String { get }
    var items: [GroupCardCellItem] { get }
    var router: GroupCardJoinRouter { get }
    var reloadData: Driver<Void> { get }
    var chatterAPI: ChatterAPI { get }
    var bottomDesc: String? { get }
    var trackInfo: [String: String] { get }

    /// 是否隐藏底部按钮, default is false
    var isJoinButtonHidden: Bool { get }

    /// 底部按钮的Title
    var joinButtonTitleRelay: BehaviorRelay<String> { get set }

    var joinButtonEnable: Bool { get }

    /// 进入个人名片页面
    func enterPersonalProfilePage()

    /// 预览头像
    func previewAvatar(with imageView: UIImageView)

    /// 点击底部加入群组按钮事件
    func joinGroupButtonTapped(from: UIViewController)

    /// 进聊天页面
    func enterChatPage(chatId: String)
    func loadGroupCardJoinData(name: String, memberCount: Int?, description: String) -> LoadJoinDataResult
}

extension GroupCardJoinViewModelProtocol {
    var isJoinButtonHidden: Bool { false }

    func enterPersonalProfilePage() {
        if let owner = owner {
            self.router.pushPersonCard(chatter: owner, chatId: chatId)
        }
    }

    func previewAvatar(with imageView: UIImageView) {
        if let avatarKey = self.avatarKey {
            let asset = LKDisplayAsset.createAsset(avatarKey: avatarKey, chatID: chatId)
            asset.visibleThumbnail = imageView
            self.router.presentPreviewImageController(asset: asset, shouldDetectFile: chat.shouldDetectFile)
        }
    }

    func enterChatPage(chatId: String) {
        self.router.pushChatController(chatId: chatId)
    }

    private func structureJoinItems(
        owner: Chatter?,
        name: String,
        memberCount: Int?,
        description: String
    ) -> [GroupCardCellItem] {
        var items: [GroupCardCellItem] = [
            .title(chatName: name),
            .description(description: description),
            .count(membersCount: memberCount)
        ]

        if let owner = owner {
            items.append(.owner(owner, chatId: self.chatId))
        }

        return items
    }

    func loadGroupCardJoinData(name: String, memberCount: Int?, description: String) -> LoadJoinDataResult {
        let items = structureJoinItems(owner: owner, name: name, memberCount: memberCount, description: description)

        // 群主不为nil则直接返回，群主为nil则进行异步拉取
        guard owner == nil else { return (items, nil) }

        let ob = chatterAPI.getChatter(id: ownerId)
            .filter { $0 != nil }
            .map { [weak self] (chatter) -> ([GroupCardCellItem], Chatter?) in
                guard let self = self else { return ([], nil) }

                let items = self.structureJoinItems(
                    owner: chatter,
                    name: name,
                    memberCount: memberCount,
                    description: description
                )

                return (items, chatter)
            }

        return (items, ob)
    }

    var bottomDesc: String? {
        return nil
    }

    var trackInfo: [String: String] {
        return ["occasion": "other"]
    }
}
