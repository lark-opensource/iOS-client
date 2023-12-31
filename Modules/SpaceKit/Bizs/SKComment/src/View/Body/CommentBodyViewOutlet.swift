//
//  CommentBodyViewOutlet.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/18.
//  

import Foundation
import LarkReactionView
import UIKit
import SpaceInterface
import SKCommon

protocol CommentCollectionViewCellDelegate: CommentTableViewCellDelegate {

}

protocol CommentTableViewCellDelegate: AnyObject {
    func didClickAvatarImage(item: CommentItem, newInput: Bool)
    func didClickAtInfo(_ atInfo: AtInfo, item: CommentItem, rect: CGRect, rectInView: UIView)
    func didClickURL(_ url: URL)
    func didClickMoreAction(button: UIView, cell: UIView, commentItem: CommentItem)
    func didClickReaction(_ commentItem: CommentItem?, reactionVM: ReactionInfo, tapType: ReactionTapType)
    func didLongPressToShowReaction(_ cell: UIView, gesture: UILongPressGestureRecognizer)
    func didClickTranslationIcon(_ commentItem: CommentItem, _ cell: CommentTableViewCell)
    func didClickSendingDelete(_ commentItem: CommentItem)
    func didClickRetry(_ commentItem: CommentItem)
    func didClickPreviewImage(_ commentItem: CommentItem, imageInfo: CommentImageInfo)
    func markReadMessage(commentItem: CommentItem)
    func didLoadImagefailed(_ commentItem: CommentItem, imageInfo: CommentImageInfo)

    // 是否可以预览缩略图
    func commentThumbnailImageSyncGetCanPreview() -> Bool?

    // cache
    func didFinishFetchImage(_ image: UIImage, cacheable: CommentImageCacheable)
    
    func inquireImageCache(by cacheable: CommentImageCacheable) -> UIImage?
}
