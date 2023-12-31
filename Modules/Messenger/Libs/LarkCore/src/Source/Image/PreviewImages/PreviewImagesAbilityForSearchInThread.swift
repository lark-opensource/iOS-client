//
//  PreviewImagesAbilityForSearchInThread.swift
//  LarkCore
//
//  Created by 李勇 on 2020/4/13.
//

import Foundation
import LarkContainer
import Swinject
import RxSwift
import LarkModel
import EENavigator
import LarkUIKit
import LarkSDKInterface
import LarkMessengerInterface
import LarkAssetsBrowser
import LarkImageEditor

final class PreviewImagesAbilityForSearchInThreadHandlerFactory: PreviewImagesAbilityForSearchInChatHandlerFactory {
   override func create(assets: [LKDisplayAsset], scene: PreviewImagesScene, resolver: UserResolver) -> PreviewImagesAbilityHandler {
        return PreviewImagesAbilityForSearchInThread(assets: assets, scene: scene, resolver: resolver)
    }
}

final class PreviewImagesAbilityForSearchInThread: PreviewImagesAbilityForSearchInChat {
    override var supportAbilities: [PreviewImagesAbilities] {
        return [.shareImage, .jumpToThreadDetail, .loadMore]
    }

    override func configData(assets: [LKDisplayAsset], scene: PreviewImagesScene) {
        switch scene {
        case .searchInThread(chatId: let chatId, messageID: let messageId, threadID: let threadId, position: let position, assetInfos: let assetInfos, currentAsset: let currentAsset):
            self.chatId = chatId
            for assetInfo in assetInfos {
                if case let .thread(position, threadId) = assetInfo.messageType {
                    assetPositionMap[assetInfo.asset.key] = (position, threadId)
                    threadIDsMap[assetInfo.asset.key] = threadId
                }
            }
            self.minFlag = messageId
            self.maxFlag = messageId
        default:
            break
        }
    }

    override func loadMoreOldImages(completion: @escaping ([LKDisplayAsset], Bool) -> Void) {
        guard !self.chatId.isEmpty else { return }
        switch scene {
        case .searchInThread(chatId: let chatId, messageID: let messageId, threadID: let threadId, position: let position, assetInfos: let assetInfos, currentAsset: let currentAsset):
            guard let currentPosition = assetInfos.firstIndex { $0.asset == currentAsset }, currentPosition > 0 else {
                completion([], false)
                return
            }
            completion(Array(assetInfos[0...currentPosition - 1]).map { $0.asset.transform() }, false)
        default: break
        }
    }

    override func loadMoreNewImages(completion: @escaping ([LKDisplayAsset], Bool) -> Void) {
        guard !self.chatId.isEmpty else { return }
        switch scene {
        case .searchInThread(chatId: let chatId, messageID: let messageId, threadID: let threadId, position: let position, assetInfos: let assetInfos, currentAsset: let currentAsset):
            guard let currentPosition = assetInfos.firstIndex { $0.asset == currentAsset }, currentPosition < assetInfos.count - 1 else {
                completion([], false)
                return
            }
            completion(Array(assetInfos[currentPosition + 1...assetInfos.count - 1]).map { $0.asset.transform() }, false)
        default: break
        }

    }

    override func jumpToChat(by assetKey: String, from: NavigatorFrom) {
        guard let positionInfo = self.assetPositionMap[assetKey] else { return }

        var threadID = positionInfo.1
        if let threadIDTmp = self.threadIDsMap[assetKey], !threadIDTmp.isEmpty {
            threadID = threadIDTmp
        }

        let body = ThreadDetailUniversalIDBody(
            chatID: self.chatId,
            threadId: threadID,
            loadType: .position,
            position: positionInfo.0
        )
        userResolver.navigator.push(body: body, from: from)
    }
}
