//
//  MessageCardViewModel+Dependency.swift
//  LarkOpenPlatform
//
//  Created by zhujingcheng on 10/19/23.
//

import Foundation
import RenderRouterInterface
import LarkMessengerInterface
import LarkMessageBase
import LarkAccountInterface
import RustPB
import LarkContainer
import LarkUIKit
import LarkCore
import LarkModel

protocol MessageUniversalCardDependency: UniversalCardActionDependency {
    var userResolver: UserResolver? { get }
    var targetVC: UIViewController? { get }
    var message: LarkModel.Message { get }
    var chat: Chat { get }
    var scene: ContextScene? { get }
    func actionTimeout()
    func dataSynchronization()
}

extension MessageCardViewModel: MessageUniversalCardDependency {
    var userResolver: UserResolver? {
        return context.userResolver
    }
    
    var targetVC: UIViewController? { context.targetVC }
    
    var chat: Chat { metaModel.getChat() }
    
    var scene: ContextScene? {
        return context.scene
    }
    
    func openProfile(chatterID: String, from: UIViewController) {
        let body = PersonCardBody(chatterId: chatterID, chatId: metaModel.getChat().id, source: .chat)
        userResolver?.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }
    
    func showImagePreview(
        properties: [RustPB.Basic_V1_RichTextElement.ImageProperty],
        index: Int,
        from: UIViewController
    ) {
        let chat = metaModel.getChat()
        var assets: [LKDisplayAsset] = []
        var assetPositionMap: [String: (position: Int32, id: String)] = [:]
        let userService = try? userResolver?.resolve(assert: PassportUserService.self)
        properties.forEach { (imageProperty) in
            let imageAsset = LKDisplayAsset.createAsset(
                postImageProperty: imageProperty,
                isTranslated: false,
                isAutoLoadOrigin: userService?.user.userID == message.fromId
            )
            imageAsset.detectCanTranslate = message.localStatus == .success
            imageAsset.trackExtraInfo = ["message_id": message.id, "is_message_delete": message.isDeleted]
            imageAsset.extraInfo[ImageAssetMessageIdKey] = message.id
            imageAsset.extraInfo[ImageAssetFatherMFIdKey] = message.fatherMFMessage?.id
            assets.append(imageAsset)
            assetPositionMap[imageAsset.key] = (message.position, message.id)
        }
        let assetResult = CreateAssetsResult(assets: assets, selectIndex: index, assetPositionMap: assetPositionMap)
        let body = PreviewImagesBody(assets: assetResult.assets.map { $0.transform() },
                                     pageIndex: index,
                                     scene: .normal(assetPositionMap: assetResult.assetPositionMap, chatId: nil),
                                     shouldDetectFile: chat.shouldDetectFile,
                                     canSaveImage: !chat.enableRestricted(.download),
                                     canShareImage: !chat.enableRestricted(.forward),
                                     canEditImage: !chat.enableRestricted(.download) || !chat.enableRestricted(.forward),
                                     showSaveToCloud: !chat.enableRestricted(.download),
                                     canTranslate: false,
                                     translateEntityContext: (message.id, .message))
        userResolver?.navigator.present(body: body, from: from)
    }

    func getChatID() -> String? {
        return metaModel.getChat().id
    }

    func getCardLinkScene() -> UniversalCardLinkSceneType? {
        if metaModel.getChat().chatMode == .threadV2 { return .topic }
        switch metaModel.getChat().type {
        case .group, .topicGroup: return .multi
        case .p2P: return .single
        @unknown default: return nil
        }
    }

    //更新localData后同步VM数据至渲染层
    func dataSynchronization() {
        self.syncToBinder()
    }

}
