//
//  UpdateImageTranslationInfoHandler.swift
//  LarkMessageCore
//
//  Created by shizhengyu on 2020/4/1.
//

import Foundation
import RxSwift
import LarkModel
import LarkContainer
import RustPB

final class UpdateImageTranslationInfoHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return UpdateImageTranslationInfoHandler(needCachePush: needCachePush, userResolver: userResolver)
    }
}

/// NOTE:
/// 在收到图片翻译的sdk push后更新消息实体内imageTranslationInfo的isTranslated值
/// 未来可能需要支持某条消息内单个图片节点的翻译状态更新，因此可以在此基础上进行实现
final class UpdateImageTranslationInfoHandler: PushHandler {
    let disposeBag: DisposeBag = DisposeBag()

    override func startObserve() throws {
        try self.userResolver.userPushCenter.observable(for: UpdateImageTranslationInfo.self).subscribe(onNext: { [weak self] (push) in
            let newImageTranslationInfo = push.imageTranslationInfo
            let messageId = newImageTranslationInfo.entityID

            self?.dataSourceAPI?.update(messageIds: [messageId], doUpdate: { data in
                let message = data.message
                /// 仅对含图且支持翻译的消息类型的消息进行更新
                /// 这里只更新对应消息类型译文的imageTranslationInfo信息
                if var translatedImageContent = message.translateContent as? ImageContent,
                    self?.checkConsistency(old: translatedImageContent.imageTranslationInfo, new: newImageTranslationInfo) ?? false {
                    translatedImageContent.imageTranslationInfo = newImageTranslationInfo
                    message.translateContent = translatedImageContent
                    return data
                }
                if var translatedPostContent = message.translateContent as? PostContent,
                    self?.checkConsistency(old: translatedPostContent.imageTranslationInfo, new: newImageTranslationInfo) ?? false {
                    translatedPostContent.imageTranslationInfo = newImageTranslationInfo
                    message.translateContent = translatedPostContent
                    return data
                }
                return nil
            })
        }).disposed(by: disposeBag)
    }

    private func checkConsistency(old: ImageTranslationInfo?, new: ImageTranslationInfo) -> Bool {
        if let keys = old?.translatedImages.keys {
            let mappingKeys = [String](keys)
            let newMappingKeys = [String](new.translatedImages.keys)
            return mappingKeys.containsSameElements(as: newMappingKeys)
        }
        return true
    }
}

extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}
