//
//  DriveAtInputTextViewDependency.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/3/27.
//

import UIKit
import RxSwift
import SwiftyJSON
import SKCommon
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignToast
import UniverseDesignDialog
import SpaceInterface
import SKInfra
import LarkDocsIcon

class DriveAtInputTextViewDependency: AtInputTextViewDependency {

    var atInputTextType: SpaceInterface.AtInputTextType = .global

    var fileType: DocsType = .file

    var fileToken: String = ""

    var dataVersion: String = ""

    var commentDocsInfo: CommentDocsInfo? { docsInfo }

    // here?
    weak var fromVC: UIViewController?

    var docsInfo: DocsInfo? {
        var info = driveCommentAdapter?.docsInfo
        if info == nil {
            info = DocsInfo(type: fileType, objToken: self.fileToken)
        }
        if info?.fileType == nil {
            info?.fileType = driveFileType
        }
        return info
    }
    
    var commentConentView: UIView? {
        return fromVC?.view
    }

    var canSupportPic: Bool {
        return false
    }

    var canSupportInviteUser: Bool {
        return false
    }

    var keyboardDidShowHeight: CGFloat? {
        return nil
    }

    var atViewType: SpaceInterface.AtViewType = .comment

    var commentSendCompletion: ((RNCommentData) -> Void)?

    // 评论引用信息
    var commentQuote: (key: String, params: [String]) = (DriveMessageQuoteType.comment.rawValue, [])

    // area comment
    var areaBoxClicked: ((UIButton) -> Void)?
    var areaBoxHighlighted: Bool = false
    var showAreaBox: Bool = false
    var area: DriveAreaComment.Area = DriveAreaComment.Area.blankArea

    weak var driveCommentAdapter: DriveCommentAdapter?

    var needMagicLayout: Bool { return true }

    private let disposeBag = DisposeBag()

    var driveFileType: String?
    
    func didCancelVoiceCommentInput(_ atInputTextView: AtInputViewType) {

    }

    func didSendCommentContent(_ atInputTextView: AtInputViewType, content: SpaceInterface.CommentContent) {
        guard let comment = _constructComment(atInputTextView, content: content) else {
            DocsLogger.driveInfo("no comment")
            return
        }
        let extraDic = ["key": commentQuote.key,
                        "params": commentQuote.params] as [String: Any]
        let extranInfo = ["quote": JSON(extraDic).rawString()]
        
        driveCommentAdapter?.createNewCommentV3(comment,
                                                extranInfo: extranInfo as [String: Any],
                                                callback: { [weak self] (commentData) in
                                                    self?.commentSendCompletion?(commentData)
                                                    self?.report(content: content, commentData: commentData, atInputTextView: atInputTextView)
        })

        atInputTextView.clearAllContent()
        atInputTextView.textViewResignFirstResponder()
    }

    func willSendCommentContent(_ atInputTextView: AtInputViewType, content: CommentContent) -> Bool {
        guard DocsNetStateMonitor.shared.isReachable else {
            if let showView = fromVC?.view {
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Doc_CommentFailed, on: showView)
            }
            return false
        }

        return true
    }

    func customSelectBoxButton() -> UIButton? {
        guard showAreaBox else { return nil }
        let button = UIButton()
        button.setImage(BundleResources.SKResource.Drive.icon_drive_areacomment_nor.withColor(UIColor.ud.N600), for: .normal)
        button.setImage(BundleResources.SKResource.Drive.icon_drive_areacomment_nor.withColor(UIColor.ud.colorfulBlue), for: .selected)
        button.addTarget(self, action: #selector(checkBoxBtnClick(sender:)), for: .touchUpInside)
        button.isSelected = areaBoxHighlighted
        return button
    }

    private func _constructComment(_ atInputTextView: AtInputViewType, content: SpaceInterface.CommentContent) -> MountComment? {
        let mountNodePoint = (type: fileType, token: fileToken)
        let focusType = atInputTextView.focusType

        let info = MountCommentInfo(type: atInputTextType,
                                                   focusType: focusType,
                                                   mountNodePoint: mountNodePoint,
                                                   commentID: nil,
                                                   replyID: nil)

        return MountComment(content: content, info: info)
    }

    @objc
    private func checkBoxBtnClick(sender: UIButton) {
        areaBoxClicked?(sender)
    }
    
    public var commentDraftScene: CommentDraftKeyScene? {
        return .newComment(isWhole: false)
    }
    
    public func showMutexDialog(withTitle str: String) {
        DispatchQueue.main.async {
            let dialog = UDDialog()
            dialog.setTitle(text: str)
            dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Ok)
            self.fromVC?.present(dialog, animated: true)
        }
    }
    
    func didCopyCommentContent() {
        PermissionStatistics.shared.reportDocsCopyClick(isSuccess: true)
    }
}

extension DriveAtInputTextViewDependency {
    
    func report(content: SpaceInterface.CommentContent, commentData: RNCommentData, atInputTextView: AtInputViewType) {
        
        var extra: [String: Any] = ["is_part_image_flag": "\(!area.isBlankArea)",
                                    "is_content_image_flag": "false"]
        if  commentData.comments.count > 1 {
            extra["is_first_flag"] = "false"
        } else {
            extra["is_first_flag"] = "true"
        }
        if let imageInfos = content.imageInfos, !imageInfos.isEmpty {
            extra["is_content_image_flag"] = "true"
        }
        let comment = commentData.comments.last
        let isFullComment = area.isBlankArea // 无选区，表示全文评论
        let tracker = DocsContainer.shared.resolve(CommentTrackerInterface.self)
        tracker?.commentReport(action: "add_comment",
                                     docsInfo: docsInfo,
                                     cardId: comment?.commentID,
                                     id: comment?.commentList.last?.replyID,
                                     isFullComment: isFullComment,
                                     extra: extra)

    }
}
