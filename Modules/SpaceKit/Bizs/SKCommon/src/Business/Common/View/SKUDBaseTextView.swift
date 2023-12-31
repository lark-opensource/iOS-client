//
//  SKBaseTextView.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/3/20.
//  

import SKFoundation
import SnapKit
import RxSwift
import LarkFoundation
import UniverseDesignInput
import UIKit
import LarkEMM

/*
 1. 支持高度自适应
 2. 支持 placeholder
 */
public final class SKUDBaseTextView: UDBaseTextView {

    public var canResign: Bool = true
    public override var canResignFirstResponder: Bool {
        return canResign
    }

    public var canBecomeFirst: Bool = true
    public override var canBecomeFirstResponder: Bool {
        return canBecomeFirst
    }
    
    /// 最大高度
    public var maxHeight: CGFloat = 60.0

    public var customKeyCommands: [UIKeyCommand] = []

    public var copyOperation: ((_ sender: Any?) -> Void)?

    public var pasteOperation: ((_ sender: Any?) -> Void)?
    
    public var cutOperation: ((_ sender: Any?) -> Void)?

    /// 行数
    public var numberOfLines: Int {
        return _numberOfLines()
    }

    private let disposeBag = DisposeBag()

    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = false
        return label
    }()

    public var hideSystemMenu: Bool = true

    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        _setupUI()
        _setupBind()
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: self)
    }
    
    
    @objc
    func textDidChange(_ noti: Notification) {
        guard let textView = noti.object as? SKUDBaseTextView, textView == self else {
            return
        }
        updateTextViewStatus()
    }
    
    public func updateTextViewStatus() {
        //Fix 系统问题：当删除全部内容的时候，布局不会刷新
        if self.text.isEmpty, self.isScrollEnabled {
            self.isScrollEnabled = false
            self.invalidateIntrinsicContentSize()
            return
        }

        // 1. 获取合适的 Size
        /* 设置 isScrollEnabled 的原因是
         1. 当 isScrollEnabled 为 false 的时候，TextView 高度自适应才会生效
         2. 当超过设定高度的时候，isScrollEnabled 要为 true，内容才可以自动滚动到最下面
         */
        let basicWidth = self.frame.size.width
        let basicFitSize = CGSize(width: basicWidth, height: CGFloat.greatestFiniteMagnitude)
        let sizeThatFits: CGSize
        if #available(iOS 14.0, *) {
            if Utils.isiOSAppOnMac {
                sizeThatFits = self.contentSize
            } else {
                sizeThatFits = self.sizeThatFits(basicFitSize)
            }
        } else {
            sizeThatFits = self.sizeThatFits(basicFitSize)
        }
        let newHeight = sizeThatFits.height
        let shouldScroll = newHeight >= self.maxHeight
        let originScrollEnable = self.isScrollEnabled
        if shouldScroll != self.isScrollEnabled {
            self.isScrollEnabled = shouldScroll
        }
        /*
         当 isScrollEnabled 从 true 变为 false 的时候，不会触发 autolayout 重新布局 size，如果这个时候又刚好处于某一行可容纳的最后一个字符，则会出现新输入文字再也不会触发
            layoutSubviews 的 bug，这里主动调用 invalidateIntrinsicContentSize 来通知布局引擎，
            触发重新布局
         */
        if !shouldScroll,
            originScrollEnable,
            sizeThatFits.height != self.frame.size.height {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateTextViewStatus()
    }

    override public var keyCommands: [UIKeyCommand]? {
        return self.customKeyCommands.count != 0 ? self.customKeyCommands : super.keyCommands
    }

    public func updatePlaceholderHeight(_ height: CGFloat) {
        placeholderLabel.snp.updateConstraints({ (make) in
            make.height.equalTo(height)
        })
    }
    
    // 手动刷新placeholder
    public func touchPlaceholder() {
        placeholderLabel.isHidden = !text.isEmpty
    }
    
    //处理复制粘贴保护逻辑
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        self.pointId = self.getEncryptId()
        if let remainItems = SCPasteboard.general(SCPasteboard.defaultConfig()).canRemainActionsDescrption(ignorePreCheck: true), 
           remainItems.contains(action.description) {
            return super.canPerformAction(action, withSender: sender)
        } else if hideSystemMenu && UserScopeNoChangeFG.WWJ.ccmSecurityMenuProtectEnable {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }

    @available(iOS 13.0, *)
    public override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        guard hideSystemMenu && UserScopeNoChangeFG.WWJ.ccmSecurityMenuProtectEnable else { return }
        guard let hiddenItems = SCPasteboard.general(SCPasteboard.defaultConfig()).hiddenItemsDescrption(ignorePreCheck: true) else {
            return
        }
        hiddenItems.forEach { identifier in
            builder.remove(menu: identifier)
        }
    }

    override public func copy(_ sender: Any?) {
        self.pointId = self.getEncryptId()
        copyOperation?(sender)

        super.copy(sender)
    }

    override public func paste(_ sender: Any?) {
        self.pointId = self.getEncryptId()
        pasteOperation?(sender)

        super.paste(sender)
    }
    
    public override func cut(_ sender: Any?) {
        self.pointId = self.getEncryptId()
        cutOperation?(sender)
        super.cut(sender)
    }

}

extension SKUDBaseTextView {
    private func _setupUI() {

        self.textAlignment = .left
        addSubview(placeholderLabel)

        placeholderLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(0)
            make.left.equalTo(5)
            make.width.equalToSuperview()
            make.height.equalTo(36)
        }
    }

    private func _setupBind() {
        // 监听 textView 内容来鉴定是否隐藏 placeholder
        rx.text.orEmpty
            .map({ !$0.isEmpty })
            .asDriver(onErrorJustReturn: false)
            .drive(placeholderLabel.rx.isHidden)
            .disposed(by: disposeBag)
    }

//    private func _refreshTextViewPlaceholder() {
//        placeholderLabel.text = placeholder
//        placeholderLabel.textColor = UIColor.ud.N500
//        placeholderLabel.font = self.font
//        placeholderLabel.textAlignment = .left
//    }

//    private func _refreshTextViewAttributedPlaceholder() {
//        placeholderLabel.attributedText = attributedPlaceholder
//    }

    private func _numberOfLines() -> Int {
        let layoutManager = self.layoutManager
        let numberOfGlyphs = layoutManager.numberOfGlyphs
        var lineRange: NSRange = NSRange(location: 0, length: 1)
        var index = 0
        var numberOfLines = 0

        while index < numberOfGlyphs {
            layoutManager.lineFragmentRect(
                forGlyphAt: index, effectiveRange: &lineRange
            )
            index = NSMaxRange(lineRange)
            numberOfLines += 1
        }
        return numberOfLines
    }
}

extension UITextView {
   public func getSelectionRect() -> CGRect {
        var resultRect: CGRect = .zero
        if let range = self.selectedTextRange {
            resultRect = self.caretRect(for: range.start)
        }
        resultRect = resultRect.insetBy(dx: -1, dy: -1) // 避免为0
        return resultRect
    }
}
