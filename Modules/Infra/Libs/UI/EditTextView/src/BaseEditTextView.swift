//
//  BaseEditTextView.swift
//  EditTextView
//
//  Created by 李晨 on 2019/4/22.
//

import UIKit
import Foundation
import LarkFoundation

open class BaseEditTextView: BaseTextView {

    open var interactionHandler: TextViewInteractionHandler = TextViewInteractionHandler()

    open var maxHeight: CGFloat = 120 {
        didSet {
            self.setNeedsLayout()
        }
    }

    private var layoutDeep: Int = 0
    private let maxLayoutDeep: Int = 5

    // 用于强制 textView 不滚动
    open var forceScrollEnabled: Bool = true {
        didSet {
            self.isScrollEnabled = self.forceScrollEnabled
        }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        var needResetLayoutDeep: Bool = true

        if self.maxHeight > 0 {
            if self.text.isEmpty, self.isScrollEnabled {
                self.isScrollEnabled = false
                self.invalidateIntrinsicContentSize()
                return
            }
            let sizeThatFits: CGSize
            if #available(iOS 14.0, *) {
                if Utils.isiOSAppOnMac {
                    sizeThatFits = self.contentSize
                } else {
                    sizeThatFits = self.sizeThatFits(self.frame.size)
                }
            } else {
                sizeThatFits = self.sizeThatFits(self.frame.size)
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

            /*
                iOS 13.2 中，如果设置完文字立刻调用 layoutIfNeeded 方法，frame 不会立刻方法变化
                且手动调用的话不会像系统一样自动改变 frame 并触发第二次 layoutSubviews
                与设置 isScrollEnabled 自适应 autolayout 大小产生冲突
                这里判断如果发生这种情况，恢复 isScrollEnabled 并且主线程异步重新 layout
            */
            if self.maxHeight > self.frame.height && shouldScroll {
                /*
                 直接粘贴或者插入超过 maxHeight 的文本也会走到这个分支，但是系统会自动再次 layout
                 这里设置 setNeedsLayout 主要为了防止用户手动调用 layoutsubviews
                 使用 layoutDeep 控制，避免在某些特殊场景下造成无线循环调用
                 */
                if self.layoutDeep < self.maxLayoutDeep {
                    self.isScrollEnabled = false
                    DispatchQueue.main.async {
                        self.setNeedsLayout()
                    }
                    needResetLayoutDeep = false
                }
            }
        } else {
            self.isScrollEnabled = true
        }

        if !self.forceScrollEnabled {
            self.isScrollEnabled = false
        }

        /// reset layout deep number
        if needResetLayoutDeep {
            self.layoutDeep = 0
        } else {
            self.layoutDeep += 1
        }
    }

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // 禁用 Bold / Italics / Underline 菜单
        if action == #selector(toggleBoldface(_:)) || action == #selector(toggleItalics(_:)) ||
            action == #selector(toggleUnderline(_:)) || action == NSSelectorFromString("_showTextStyleOptions:") {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }

    override open func paste(_ sender: Any?) {
        if self.interactionHandler.pasteHandler(self) {
            return
        }
        super.paste(sender)
    }

    override open func copy(_ sender: Any?) {
        if self.interactionHandler.copyHandler(self) {
            return
        }
        super.copy(sender)
    }

    override open func cut(_ sender: Any?) {
        if self.interactionHandler.cutHandler(self) {
            return
        }
        super.cut(sender)
    }

    override open func canPaste(_ itemProviders: [NSItemProvider]) -> Bool {
        return super.canPaste(itemProviders)
    }

    /// 设置可以粘贴的内容类别，会清空之前的 paste config 设置
    public func setAcceptablePaste(types: [NSItemProviderReading.Type]) {
        let pasteConfig = UIPasteConfiguration()
        types.forEach { pasteConfig.addTypeIdentifiers(forAccepting: $0) }
        pasteConfiguration = pasteConfig
    }

    /// 设置可以粘贴的内容 UTI，会清空之前的 paste config 设置
    public func setAcceptablePaste(typeIdentifiers: [String]) {
        pasteConfiguration = UIPasteConfiguration(acceptableTypeIdentifiers: typeIdentifiers)
    }
}
