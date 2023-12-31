//
//  AtInputTextViewDependency.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/4/23.
//  

import Foundation

public enum AtInputTextType: Int {
    case none = 0
    /// 评论卡片时使用
    case cards = 1
    /// 文档中插入时使用
    case docs = 2
    /// 全文评论时使用
    case global = 3
    /// 图片评论时使用
    case photo = 4
    
    case add
    case reply
}

public enum AtInputFocusType: Int {
    case new // 新评论
    case edit // 编辑评论
}

public protocol AtInputTextViewDependency: AnyObject {

    // 关键字
    var responseSign: Character { get }

    // 文档类型
    var fileType: DocsType { get }

    // 文档 Token 用来请求 @ 数据
    var fileToken: String { get }

    // 妥协了 ... 要一个 docs info
    var commentDocsInfo: CommentDocsInfo? { get }

    // @ 出来 View 的样式
    var atViewType: AtViewType { get }

    // 定制各种业务的样式的标记位
    var atInputTextType: AtInputTextType { get }

    // 是否需要点击空白区域收起键盘
    var needBlankView: Bool { get }

    // 场景是否支持插入图片
    var canSupportPic: Bool { get }
    
    // 默认返回nil，外部不做配置
    var canSupportVoice: Bool? { get }

    // 场景是否支持atUser邀请
    var canSupportInviteUser: Bool { get }

    // 普通键盘didShow时的高度
    var keyboardDidShowHeight: CGFloat? { get }

    // 为了解决神奇的 Layout 问题
    // 目前是给 comment footer view 用的
    var needMagicLayout: Bool { get }

    // 是否吧textView加到toolView上
    var textViewInToolView: Bool { get }
    
    // 是否在toolView上显示atListView，iPad评论中at面板以Popver的形式再评论输入框的上面（或下面）， 默认为true在ToolView上显示
    var atListViewInToolView: Bool { get }
    
    // 发送评论前的判断
    // true: 可以发送
    // fasle: 不可以发送
    func willSendCommentContent(_ atInputTextView: AtInputViewType, content: CommentContent) -> Bool

    // 点击发送按钮的回调
    func didSendCommentContent(_ atInputTextView: AtInputViewType, content: CommentContent)

    // 点击空白区域的事件
    func didTapBlankView(_ atInputTextView: AtInputViewType)

    // 取消发送
    func didCancelVoiceCommentInput(_ atInputTextView: AtInputViewType)

    // for drive - custom button
    func customSelectBoxButton() -> UIButton? // Drive 自定义选择框

    // 点击了话筒按钮
    func didClickRecord(_ atInputTextView: AtInputViewType)

    // 需要弹授权popover Tips
    func showInvitePopoverTips(at: AtInfo, rect: CGRect, inView: UIView)
    
    // 点击收起键盘按钮的回调
    func resignInputView()
    
    // 禁止textView显示多行，即：textView只能显示一行文字
    var diableTextMultiLine: Bool { get }

    // 评论草稿的key
    var commentDraftScene: CommentDraftKeyScene? { get }
    
    var commentConentView: UIView? { get }
    
    // 语音输入被占用时展示
    func showMutexDialog(withTitle str: String)
    
    var supportAtSubtypeTag: Bool { get }
    
    // 点击复制或剪切的回调
    func didCopyCommentContent()
    
    var canShowDraftDarkName: Bool { get }
}

public extension AtInputTextViewDependency {

    var responseSign: Character {
        return "@"
    }

    var textViewInToolView: Bool {
        return true
    }
    
    var atListViewInToolView: Bool {
        return true
    }

    var needBlankView: Bool {
        return false
    }

    var needMagicLayout: Bool {
        return false
    }

    func didTapBlankView(_ atInputTextView: AtInputViewType) {

    }

    func customSelectBoxButton() -> UIButton? {
        return nil
    }

    func didClickRecord(_ atInputTextView: AtInputViewType) {}

    func showInvitePopoverTips(at: AtInfo, rect: CGRect, inView: UIView) {}
    
//    public func showMutexDialog(withTitle str: String) {}
    
    var diableTextMultiLine: Bool {
        return false
    }
    
    var commentDraftScene: CommentDraftKeyScene? { nil }
    
    func resignInputView() {}
    
    var canSupportVoice: Bool? { return nil }
    
    var supportAtSubtypeTag: Bool { return false }
    
    var canShowDraftDarkName: Bool { return false }
}
