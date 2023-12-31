//
//  ImageContentFactory.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/5/29.
//

import UIKit
import CoreServices
import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import LarkSendMessage
import LarkInteraction
import ByteWebImage
import LarkAccountInterface
import LarkMessengerInterface
import RustPB
import LarkUIKit
import LarkSDKInterface
import LarkAssetsBrowser
import LarkContainer
import EENavigator
import LarkCache
import UniverseDesignToast

public protocol ImageContentContext: PageContext {
    var scene: ContextScene { get }
    func progressValue(key: String) -> Observable<Progress>
    func getProgressValue(key: String) -> Progress?
    func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>(_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>]
    func isMe(_ id: String) -> Bool
    /// 获取预览权限。 用于会话中展示图片时，获取预览权限使用
    func checkPermissionPreview(chat: Chat, message: Message) -> (Bool, ValidateResult?)
    /// 获取预览权限和接收权限。 用于点开图片到大图查看器时，获取预览权限和接收权限使用。
    /// 接收权限是异步返回，未返回结果前会话内展示灰图。此处获取接收权限，是通过安全缓存。安全缓存会根据message_id等信息生成key，当发起
    func checkPreviewAndReceiveAuthority(chat: Chat, message: Message) -> PermissionDisplayState
    func handlerPermissionPreviewOrReceiveError(receiveAuthResult: DynamicAuthorityEnum?,
                                                previewAuthResult: ValidateResult?,
                                                resourceType: SecurityControlResourceType)
    var downloadFileScene: RustPB.Media_V1_DownloadFileScene? { get }
    func getChatAlbumDataSourceImpl(chat: Chat, isMeSend: @escaping (String) -> Bool) -> LKMediaAssetsDataSource
}

public class ImageContentFactory<C: ImageContentContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is ImageContent
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ImageContentComponentBinder(
            imageViewModel: ChatImageContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            imageActionHandler: ChatImageContentActionHandler(context: context)
        )
    }

    public override func registerDragHandler<M: CellMetaModel, D: CellMetaModelDependency>(with dargManager: DragInteractionManager, metaModel: M, metaModelDependency: D) {
        let handler = DragHandlerImpl(
            handleViewTag: "ImageContent",
            canHandle: { (context) -> Bool in
                guard let chat = context.getValue(key: DragContextKey.chat) as? Chat,
                    let message = context.getValue(key: DragContextKey.message) as? Message else {
                        return false
                }
                if message.type != .image {
                    return false
                }
                return true
            }
        ) { [weak self] (info, context) -> [DragItem]? in
            if let message = context.getValue(key: .message) as? Message,
               let content = message.content as? ImageContent,
               let imageView = info.view as? ChatImageViewWrapper,
               let previewImage = imageView.imageView.image {
                // 确定图片格式，目前只有从预览图上取
                let uti: [String]
                if previewImage.bt.imageFileFormat == .gif {
                    uti = [kUTTypeGIF as String]
                } else if let cgImage = previewImage.cgImage, !ImageDecoderUtils.containsAlpha(cgImage) {
                    // 保持和 originData 的逻辑一致
                    uti = [kUTTypeJPEG as String]
                } else {
                    uti = [kUTTypePNG as String]
                }
                // 尝试查找原图
                let imageSet = content.image
                let itemProviderWriting = ItemProviderWriting(
                    supportUTI: uti
                ) { [weak self] (_, callback) -> Progress? in
                    guard let self else { return nil }
                    let progress = Progress()
                    progress.totalUnitCount = 100
                    self.checkSecurity(context: context, service: self.context.chatSecurityService, from: imageView.window) { isAllow in
                        guard isAllow else {
                            callback(nil, NoImageError())
                            return
                        }
                        LarkImageService.shared.setImage(
                            with: .default(key: imageSet.origin.key),
                            progress: { _, downloadedSize, expectedSize in
                                progress.completedUnitCount = Int64(downloadedSize / expectedSize)
                            },
                            completion: { result in
                                switch result {
                                case .success(let imageResult):
                                    progress.completedUnitCount = 100
                                    if let data = imageResult.image?.bt.originData {
                                        callback(data, nil)
                                        return
                                    }
                                case .failure:
                                    break
                                }
                                // 降级策略：拿预览图
                                if let imageData = previewImage.bt.originData {
                                    callback(imageData, nil)
                                } else {
                                    callback(nil, NoImageError())
                                }
                            })
                    }
                    return progress
                }
                let itemProvider = NSItemProvider(object: itemProviderWriting)

                if let imageView = info.view {
                    var item = DragItem(dragItem: UIDragItem(itemProvider: itemProvider))
                    let previewParams = UIDragPreviewParameters()
                    previewParams.backgroundColor = UIColor.ud.primaryOnPrimaryFill
                    previewParams.visiblePath = UIBezierPath(
                        roundedRect: imageView.bounds,
                        cornerRadius: 8
                    )
                    item.params.targetDragPreviewParameters = previewParams
                    return [item]
                }
            }
            return nil
        }
        dargManager.register(handler)
    }

    func checkSecurity(context: DragContext, service: ChatSecurityControlService?, from: NavigatorFrom?, completion: @escaping (Bool) -> Void) {
        guard let service,
              let message = context.getValue(key: .message) as? Message,
              let chat = context.getValue(key: DragContextKey.chat) as? Chat,
              let content = message.content as? ImageContent else {
            completion(true)
            return
        }
        let chatType: Int64 = (chat.chatMode == .threadV2) ? 3 : ((chat.type == .p2P) ? 1 : 2)
        let info = SecurityExtraInfo(fileKey: content.image.origin.key,
                                     chatID: (chat.id as NSString).longLongValue,
                                     chatType: chatType,
                                     senderUserId: (message.fromId as NSString).longLongValue,
                                     senderTenantId: ((message.fromChatter?.tenantId ?? "") as NSString).longLongValue,
                                     msgId: message.id)
        service.downloadAsyncCheckAuthority(event: .saveImage, securityExtraInfo: info, completion: { result in
            if !result.authorityAllowed {
                service.authorityErrorHandler(event: .saveImage, authResult: result, from: from)
                completion(false)
            } else if LarkCache.isCryptoEnable() {
                if let window = from?.fromViewController?.view ?? from as? UIView {
                    UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_Core_SecuritySettingKAToast, on: window)
                }
                completion(false)
            } else {
                completion(true)
            }
        })
    }
}

public final class MessageLinkImageContentFactory<C: ImageContentContext>: ImageContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ImageContentComponentBinder(
            imageViewModel: MessageLinkImageContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            imageActionHandler: MergeForwardDetailImageContentActionHandler(context: context) // 对齐合并转发，只支持查看当前消息的图片
        )
    }
}

public final class ThreadChatImageContentFactory<C: ImageContentContext>: ImageContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ThreadImageContentComponentBinder(
            imageViewModel: ThreadChatImageContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            imageActionHandler: ThreadChatImageContentActionHandler(context: context)
        )
    }
}

public final class ThreadDetailImageContentFactory<C: ImageContentContext>: ImageContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ThreadImageContentComponentBinder(
            imageViewModel: ThreadDetailImageContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            imageActionHandler: ThreadDetailImageContentActionHandler(context: context)
        )
    }
}

public final class MergeForwardImageContentFactory<C: ImageContentContext>: ImageContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ImageContentComponentBinder(
            imageViewModel: MergeForwardDetailImageContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            imageActionHandler: MergeForwardDetailImageContentActionHandler(context: context)
        )
    }
}

public final class MessageDetailImageContentFactory<C: ImageContentContext>: ImageContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return MessageDetailImageContentComponentBinder(
            imageViewModel: MessageDetailImageContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            imageActionHandler: MessageDetailImageContentActionHandler(context: context)
        )
    }
}

public final class PinImageContentFactory<C: ImageContentContext>: ImageContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return PinImageContentComponentBinder(
            imageViewModel: PinImageContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            imageActionHandler: PinImageContentActionHandler(context: context)
        )
    }
}

struct NoImageError: Error {}

extension PageContext: ImageContentContext {
    public func progressValue(key: String) -> Observable<Progress> {
        return (try? resolver.resolve(assert: ProgressService.self, cache: true))?
            .value(key: key) ?? .empty()
    }

    public func getProgressValue(key: String) -> Progress? {
        return try? resolver.resolve(assert: ProgressService.self, cache: true)
            .getProgressValue(key: key)
    }

    public func getChatAlbumDataSourceImpl(chat: Chat, isMeSend: @escaping (String) -> Bool) -> LKMediaAssetsDataSource {
        return (try? resolver.resolve(assert: ChatAlbumDataSourceImpl.self, arguments: chat, isMeSend)) ?? DefaultAlbumDataSourceImpl()
    }
}
