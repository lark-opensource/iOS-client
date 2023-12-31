//
//  EditorTextView+Attachment.swift
//  LarkUIKit
//
//  Created by 李晨 on 2019/3/6.
//

import UIKit
import Foundation

public protocol EditTextViewLog {
   func debug(message: String, params: [String: String]?)
   func info(message: String, params: [String: String]?)
   func warn(message: String, params: [String: String]?)
   func error(message: String, params: [String: String]?)
}

extension LarkEditTextView {

    // 管理 text view 所有的自定义 attachment
    final class AttachmentManager {

        weak var textView: LarkEditTextView?

        // 所有的 attachment，用于做集合判断
        private(set) var customAttachmentsSet: Set<CustomTextAttachment> = []

        // 所有 attachment 的数组
        private(set) var customAttachmentsArray: [CustomTextAttachment] = []

        // 所有显示在屏幕中的 attachment
        private(set) var showAttachmentsSet: Set<CustomTextAttachment> = []

        // 所有选中的 attachment
        private(set) var selectedAttachmentSet: Set<CustomTextAttachment> = []

        // text 变更， 全量刷新 attachment 数据
        func updateAttachmentViewData() {
            guard let textView = self.textView else {
                self.clearAllAttachment()
                return
            }
            let layoutManager = textView.layoutManager
            let textStorage = textView.textStorage
            let textContainer = textView.textContainer

            var allAttachmentSet: Set<CustomTextAttachment> = []
            var allAttachmentArray: [CustomTextAttachment] = []

            let range = NSRange(location: 0, length: textStorage.length)
            textStorage.enumerateAttribute(.attachment, in: range, options: []) { (attachment, aRange, _) in
                if let custom = attachment as? CustomTextAttachment {
                    let glyphIndex = layoutManager.glyphIndexForCharacter(at: aRange.location)
                    let glyphRange = NSRange(location: glyphIndex, length: 1)
                    let frame = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                    let size = layoutManager.attachmentSize(forGlyphAt: glyphIndex)
                    let location = layoutManager.location(forGlyphAt: glyphIndex)
                    ///attachmentView.attachmentView的superview尚未指定 或者attachmentView.superview为textView
                    if custom.attachmentView.superview == nil ||
                        custom.attachmentView.superview == textView ||
                        custom.attachmentView.superview == textView.containerView {
                        // 空间比较大时，从左下角排布
                        custom.frame = CGRect(
                            x: textView.textContainerInset.left + frame.minX,
                            y: textView.textContainerInset.top + frame.minY + location.y - size.height,
                            width: size.width,
                            height: size.height
                        )
                    }
                    _ = allAttachmentSet.insert(custom)
                    allAttachmentArray.append(custom)
                }
            }

            let deleted = self.customAttachmentsSet.subtracting(allAttachmentSet)
            for attachemnt in deleted {
                attachemnt.clearAttachmentView()
                showAttachmentsSet.remove(attachemnt)
            }

            self.customAttachmentsSet = allAttachmentSet
            self.customAttachmentsArray = allAttachmentArray
            self.updateAllAttachmentShowState()
        }

        // 刷新 attachment 选中状态
        func updateAttachmentSelectedState() {
            guard let textView = self.textView,
                let attributedText = textView.attributedText else {
                    self.clearAllAttachment()
                    return
            }

            var selectedAttachmentSet: Set<CustomTextAttachment> = []

            /// all attachment is unselected when textview is not first responsder
            if textView.isFirstResponder {
                let selectedRange = textView.selectedRange
                if selectedRange.location + selectedRange.length > attributedText.length {
                    self.textView?.logger?.error(message: "edit text view range error",
                                                 params: [
                                                    "length": "\(attributedText.length)",
                                                    "selectLocation": "\(selectedRange.location)",
                                                    "selectLength": "\(selectedRange.length)"
                                                ])
                    assertionFailure("edit text view range error")
                } else {
                    attributedText.enumerateAttribute(.attachment, in: selectedRange, options: []) { (attachment, _, _) in
                        if let custom = attachment as? CustomTextAttachment {
                            custom.selected = true
                            selectedAttachmentSet.insert(custom)
                        }
                    }
                }
            }

            let unselectedAttachmentSet = self.selectedAttachmentSet.subtracting(selectedAttachmentSet)
            unselectedAttachmentSet.forEach { (attachment) in
                attachment.selected = false
            }
            self.selectedAttachmentSet = selectedAttachmentSet
        }

        // 刷新所有 attachment 的显示状态
        func updateAllAttachmentShowState() {
            let screenRect = self.currentScreenRect

            // 利用二分法找到一个在屏幕中的 attachment
            if let index = self.searchOneShowAttachment(inScreen: screenRect) {

                var before = index
                var after = index

                // 向前寻找并显示所有需要被显示的 attachment
                while before >= 0 {
                    let attachment = self.customAttachmentsArray[before]
                    if self.needShow(attachment: attachment) {
                        self.show(attachment: attachment)
                    } else {
                        break
                    }
                    before -= 1
                }
                // 向后寻找并显示所有需要被显示的 attachment
                while after <= self.customAttachmentsArray.count - 1 {
                    let attachment = self.customAttachmentsArray[after]
                    if self.needShow(attachment: attachment) {
                        self.show(attachment: attachment)
                    } else {
                        break
                    }
                    after += 1
                }
            }
            self.clearOffScreenAttachment()
        }

        // 返回 attachment 是否需要显示在屏幕上
        private func needShow(attachment: CustomTextAttachment) -> Bool {
            let screenRect = self.currentScreenRect
            if let frame = attachment.frame, screenRect.intersects(frame) {
                return true
            }
            return false
        }

        private func show(attachment: CustomTextAttachment) {
            if let textView = self.textView,
                let frame = attachment.frame,
                !roughCheckEqual(attachment.attachmentView.frame, frame) ||
                attachment.attachmentView.superview != textView {

                attachment.attachmentView.frame = frame
                // 将自定义 View 放在 UITextSelectionView 下层，利用原生的选中效果
                // 结构：
                // _UITextContainerView
                //   - _UITextViewCanvasView
                //   - Attachments 所有的附件放在这里
                //   - UITextSelectionView
                if let containerView = textView.containerView,
                   containerView.subviews.count > 1 {
                    containerView.insertSubview(attachment.attachmentView, at: 1)
                    attachment.needCustomSelectedMask = false
                } else {
                    // 兜底方案，放在 TextView 上面
                    attachment.superViewBackgroundColor = textView.backgroundColor
                    textView.addSubview(attachment.attachmentView)
                }
            }
            self.showAttachmentsSet.insert(attachment)
        }

        /// 粗略判断 frame 相等，忽略小数点后3位的数字
        private func roughCheckEqual(_ frame1: CGRect, _ frame2: CGRect) -> Bool {
            ///截断 到小数点后某一位
            func truncate(_ value: CGFloat, _ places: Int) -> CGFloat {
                let divisor = pow(10.0, CGFloat(places))
                return CGFloat(Int(value * divisor)) / divisor
            }
            return truncate(frame1.origin.x, 2) == truncate(frame2.origin.x, 2) &&
                truncate(frame1.origin.y, 2) == truncate(frame2.origin.y, 2) &&
                truncate(frame1.size.width, 2) == truncate(frame2.size.width, 2) &&
                truncate(frame1.size.height, 2) == truncate(frame2.size.height, 2)
        }

        // 找到一个在屏幕中的 attachment
        private func searchOneShowAttachment(inScreen screenRect: CGRect) -> Int? {
            if self.customAttachmentsArray.isEmpty { return nil }

            var before = 0
            var mid: Int = 0
            var after = self.customAttachmentsArray.count - 1

            // 返回 nil 为无效
            // 0 为 相等， -1 为 指定 attachment 在屏幕上方， 1 为 指定 attachment 在屏幕下方
            let compare: (CustomTextAttachment) -> Int? = { attachment in
                guard let frame = attachment.frame else { return nil }
                // frame 在屏幕中返回 0
                if screenRect.intersects(frame) { return 0 } else {
                    // frame 在屏幕上方 返回 -1
                    if screenRect.minY > frame.maxY { return -1 }
                    // frame 在屏幕下方 返回 1
                    else { return 1 }
                }
            }

            // 判断第一个和最后一个是否在屏幕中
            if let result = compare(self.customAttachmentsArray[before]), result == 0 { return before }
            if let result = compare(self.customAttachmentsArray[after]), result == 0 { return after }

            // 使用二分查找
            while after - before > 1 {
                mid = (before + after) >> 1
                if let result = compare(self.customAttachmentsArray[mid]) {
                    if result == 0 { return mid } else if result < 0 { before = mid } else { after = mid }
                } else { after = mid }
            }

            // 判断最终状态
            if let result = compare(self.customAttachmentsArray[before]), result == 0 { return before }
            if let result = compare(self.customAttachmentsArray[after]), result == 0 { return after }

            return nil
        }

        // 清除屏幕外的 attachment
        private func clearOffScreenAttachment() {
            let checkOffScreenRect = self.checkOffScreenRect
            var removed: [CustomTextAttachment] = []
            for attachment in self.showAttachmentsSet {
                if let frame = attachment.frame,
                    checkOffScreenRect.intersects(frame) {
                    continue
                }
                attachment.clearAttachmentView()
                removed.append(attachment)
            }
            self.showAttachmentsSet.subtract(removed)
        }

        // 当前 screen 显示区域
        private var currentScreenRect: CGRect {
            guard let textView = self.textView else { return .zero }
            let screenRect = CGRect(
                x: textView.contentOffset.x,
                y: textView.contentOffset.y,
                width: textView.frame.width,
                height: textView.frame.height
            )
            return screenRect
        }

        /// 离开屏幕一半高度 才从视图删除，避免频繁增删
        private var checkOffScreenRect: CGRect {
            guard let textView = self.textView else { return .zero }
            let checkRect = CGRect(
                x: textView.contentOffset.x,
                y: textView.contentOffset.y - textView.frame.height / 2,
                width: textView.frame.width,
                height: textView.frame.height * 2
            )
            return checkRect
        }

        // 清除所有 attachment
        private func clearAllAttachment() {
            self.showAttachmentsSet.forEach { (attachment) in
                attachment.clearAttachmentView()
            }

            customAttachmentsSet = []
            customAttachmentsArray = []
            showAttachmentsSet = []
            selectedAttachmentSet = []
        }
    }
}

extension LarkEditTextView {
    public func updateAttachmentViewData() {
        self.attachmantManager.updateAttachmentViewData()
    }
}

extension LarkEditTextView: NSLayoutManagerDelegate {
    public func layoutManager(
        _ layoutManager: NSLayoutManager,
        didCompleteLayoutFor textContainer: NSTextContainer?,
        atEnd layoutFinishedFlag: Bool
    ) {
        /// update attachment frame after layout complete
        self.updateAttachmentViewData()
    }
}
