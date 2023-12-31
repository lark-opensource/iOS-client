//
//  CommentDraftManager+text.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/8/9.
//


import UIKit
import SpaceInterface

// MARK: GET attributedText

protocol SystemAttributedTextInputView: NSObject {
    
    var attributedString: NSAttributedString { get }
}

extension UITextView: SystemAttributedTextInputView {
    var attributedString: NSAttributedString { attributedText }
}

extension UITextField: SystemAttributedTextInputView {
    var attributedString: NSAttributedString { attributedText ?? NSAttributedString() }
}

// MARK: CommentDraftKeyProvider

public protocol CommentDraftKeyProvider: AnyObject {
    
    var commentDraftKey: CommentDraftKey { get }
}

public protocol CommentDraftSceneDataSource: AnyObject {
    
    var commentDraftScene: CommentDraftKeyScene { get }
}



private class WeakWrapper: NSObject {
    weak var object: AnyObject?
    init(_ object: AnyObject) {
        self.object = object
    }
}

private var draftKey: UInt8 = 0

extension SystemAttributedTextInputView {
    
    var commentDraftKeyProvider: CommentDraftKeyProvider? {
        get {
            let obj = objc_getAssociatedObject(self, &draftKey) as? WeakWrapper
            return obj?.object as? CommentDraftKeyProvider
        }
        set {
            let obj = newValue.map { WeakWrapper($0) }
            objc_setAssociatedObject(self, &draftKey, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: CommentDraftManager

extension CommentDraftManager {
    
    func setupNotification() {
        let name1 = UITextView.textDidChangeNotification
        NotificationCenter.default.addObserver(self, selector: #selector(onTextChanged), name: name1, object: nil)
        let name2 = UITextField.textDidChangeNotification
        NotificationCenter.default.addObserver(self, selector: #selector(onTextChanged), name: name2, object: nil)
        let name3 = Notification.Name.commentDraftClear
        NotificationCenter.default.addObserver(self, selector: #selector(handleDraftClear), name: name3, object: nil)
    }
    
    @objc
    private func onTextChanged(_ noti: Notification) {
        guard let inputView = noti.object as? SystemAttributedTextInputView else { return }
        guard let provider = inputView.commentDraftKeyProvider else { return }
        
        let key = provider.commentDraftKey
        let text = AtInfo.encodedString(attributedString: inputView.attributedString)
        //debugPrint("feat: comment draft: text:\(text), for key:\(key)")
        updateCommentText(text, for: key)
    }

    @objc
    private func handleDraftClear(_ noti: Notification) {
        guard let draftKey = noti.object as? CommentDraftKey else { return }
        removeCommentModel(forKey: draftKey)
    }

    public func handleDocsDelete(token: String) {
        guard !token.isEmpty else { return }
        mmkvStorage.removeAllKeysOfCurrentUserWith(prefix: token)
    }
}

extension Notification.Name {
    
    /// 清理评论草稿，在发送评论完成时触发，object为CommentDraftKey
    public static var commentDraftClear: Notification.Name {
        Notification.Name("docs.bytedance.notification.name.commentDraftClear")
    }
}

extension CommentDraftKey: Equatable {
    
    public static func == (lhs: CommentDraftKey, rhs: CommentDraftKey) -> Bool {
        let entityIdSame = (lhs.entityId == rhs.entityId)
        let commentIdSame = (lhs.getCommentId() == rhs.getCommentId())
        let replyIdSame = (lhs.getReplyId() == rhs.getReplyId())
        return entityIdSame && commentIdSame && replyIdSame
    }
    
    private func getCommentId() -> String? {
        switch sceneType {
        case .newComment: return nil
        case .newReply(let commentId): return commentId
        case .editExisting(let commentId, _): return commentId
        }
    }
    
    private func getReplyId() -> String? {
        switch sceneType {
        case .newComment: return nil
        case .newReply: return nil
        case .editExisting(_, let replyId): return replyId
        }
    }
}
