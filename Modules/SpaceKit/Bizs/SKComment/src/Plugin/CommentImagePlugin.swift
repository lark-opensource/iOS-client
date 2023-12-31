//
//  CommentImagePlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/9/26.
//  


import UIKit
import SKFoundation
import SpaceInterface
import SKCommon

class CommentImagePlugin: CommentPluginType {

    weak var context: CommentServiceContext?

    static let identifier: String = "ImagePlugin"
    
    lazy var imageMemoryCache = CommentImageMemoryCache()

    private(set) lazy var openImagePlugin: CommentPreviewPicOpenImageHandler = {
        var handler = CommentPreviewPicOpenImageHandler(delegate: self, transitionDelegate: self, docsInfo: context?.scheduler?.fastState.docsInfo)
        return handler
    }()
    
    private var openingCommentItem: CommentItem?
    
    func apply(context: CommentServiceContext) {
        self.context = context
    }
    
    func mutate(action: CommentAction) {
        switch action {
        case .removeAllMenu:
            openImagePlugin.closeImage()
        case let .interaction(ui):
            handleUIAction(ui)
        default:
            break
        }
    }
    
    func handleUIAction(_ action: CommentAction.UI) {
        switch action {
        case let .loadImagefailed(item):
            handleLoadImagefailed(item)
        case let .openImage(item, imageInfo):
            handleOpenImage(item, imageInfo)
        case let .cacheImage(image, cacheable):
            storeImage(cacheable, image)
        default:
            break
        }
    }
}

extension CommentImagePlugin: CommentCachePluginType {
    
    func cache<T>(key: String) -> T? {
        return imageMemoryCache.fetch(key: key) as? T
    }
    
    func storeImage(_ cacheable: CommentImageCacheable, _ key: UIImage) {
        imageMemoryCache.cache(cacheable, key)
    }
}


extension CommentImagePlugin {
    
    func handleLoadImagefailed(_ item: CommentItem) {
        if item.errorCode == 0, let commentId = item.commentId { // 保证无其他错误情况下，再设置图片错误状态
            DocsLogger.error("[image fail] cId:\(commentId) rId:\(item.replyID)", component: LogComponents.comment)
            item.errorCode = CommentItem.ErrorCode.loadImageError.rawValue
            context?.scheduler?.dispatch(action: .ipc(.refresh(commentId: commentId, replyId: item.replyID), nil))
        } else {
            DocsLogger.info("[image fail] There's a mistake somewhere code:\(item.errorCode)", component: LogComponents.comment)
        }
    }
    
    func handleOpenImage(_ item: CommentItem, _ imageInfo: CommentImageInfo) {
        self.openingCommentItem = item
        DocsLogger.info("CommentTableViewCell didClickPreviewImage ", component: LogComponents.commentPic)
        var currentShowImage: ShowPositionData?
        var imageList = [PhotoImageData]()
        var showIndex: Int = 0
        for (index, tempImage) in item.previewImageInfos.enumerated() {
            if let srcUrl = URL(string: tempImage.src) {
                //这里同一用src.path做key,因为其他的值都可能为空
                let uuid = srcUrl.path
                let imageData = PhotoImageData(uuid: uuid, src: tempImage.src, originalSrc: tempImage.originalSrc ?? tempImage.src)
                imageList.append(imageData)
                if imageInfo == tempImage {
                    showIndex = index
                    currentShowImage = ShowPositionData(uuid: uuid, src: tempImage.src, originalSrc: tempImage.originalSrc, position: nil)
                }
            } else {
                DocsLogger.info("transform err", component: LogComponents.commentPic)
            }
        }
        var allowCopyImg = false // 是否允许评论里的图片被复制，决定是否可以保存到相册&被截图
        if case .permit = context?.businessDependency?.externalCopyPermission {
            allowCopyImg = true
        } else {
            DocsLogger.info("copy permission denied", component: LogComponents.comment)
        }

        let canDownload = self.commentImageCanDownloadInitValue
        let toolStatus = PhotoToolStatus(comment: nil, copy: allowCopyImg, delete: nil, export: canDownload)
        let openImageData = OpenImageData(showImageData: currentShowImage, imageList: imageList, toolStatus: toolStatus, callback: nil)
        self.openImagePlugin.fromCommentItem = item
        self.openImagePlugin.closeImage()
        self.openImagePlugin.openImage(openImageData: openImageData)
        self.context?.scheduler?.dispatch(action: .api(.activateImageChange(item: item, index: showIndex), nil))
        
        guard let token = imageInfo.token,
              let service = context?.businessDependency?.businessConfig.imagePermissionDataSource else { return }
        
        requestCommentImageDownloadPermission(imageToken: token, service: service) { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .visible:
                self.openImagePlugin.setSaveButtonHidden(false)
                self.openImagePlugin.setSaveButtonGray(false)
            case .grayed:
                self.openImagePlugin.setSaveButtonHidden(false)
                self.openImagePlugin.setSaveButtonGray(true)
            case .hidden:
                self.openImagePlugin.setSaveButtonHidden(true)
            }
        }
    }
}

extension CommentImagePlugin: CommentImageDownloadPermissionProvider {

    func commentImageDownloadDefaultValue() -> Bool {
        if let item = openingCommentItem {
            let canDownload = item.permission.contains(.canDownload)
            return canDownload
        } else {
            return false
        }
    }
}


// MARK: - CommentPicOpenImageProtocol

extension CommentImagePlugin: CommentPicOpenImageProtocol {
    public func willSwipeTo(_ index: Int) {
        guard let commentItem = openImagePlugin.fromCommentItem else {
            DocsLogger.error("willSwipeTo, error, fromItem=\(openImagePlugin.fromCommentItem == nil)", component: LogComponents.commentPic)
            return
        }
        context?.scheduler?.dispatch(action: .api(.activateImageChange(item: commentItem, index: index), nil))
    }

    public func skAssetBrowserVCWillDismiss(assetVC: SKAssetBrowserViewController) {
        guard let commentItem = openImagePlugin.fromCommentItem else {
            DocsLogger.error("picVCWillDismiss, error, fromItem=\(openImagePlugin.fromCommentItem == nil)", component: LogComponents.commentPic)
            return
        }
        context?.scheduler?.dispatch(action: .api(.activateImageChange(item: commentItem, index: -1), nil))
    }

    public func scanQR(code: String) {
        DocsLogger.info("scanQR, code=\(code.count)", component: LogComponents.commentPic)
        context?.scheduler?.dispatch(action: .interaction(.scanQR(code)))
    }
    
}


// MARK: - CommentPreviewPicOpenTransitionDelegate

extension CommentImagePlugin: CommentPreviewPicOpenTransitionDelegate {
    public func getTopMostVCForCommentPreview() -> UIViewController? {
        var vc = context?.commentVC ?? context?.businessDependency?.browserVCTopMost
        return vc ?? context?.topMost
    }
}
