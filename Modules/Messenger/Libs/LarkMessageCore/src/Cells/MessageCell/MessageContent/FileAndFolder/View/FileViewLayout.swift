//
//  FileViewLayout.swift
//  LarkMessageCore
//
//  Created by bytedance on 2020/8/5.
//

import Foundation
import UIKit
import RichLabel
import LarkMessengerInterface
import LarkContainer

/// 存储layout的结果
struct FileViewLayoutResult {
    var nameLabelFrame: CGRect = CGRect(x: 40.auto() + 24, y: 12, width: 0, height: 0)
    var sizeAndRateLabelFrame = CGRect(x: 40.auto() + 24, y: 0, width: 0, height: 0)
    var statusLabelFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 17)
    var progressViewFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 2.0)
    var topBorderViewFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 1)
    var bottomBorderViewFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 1)
    var noPermissionLabelFrame: CGRect = CGRect(x: 40.auto() + 24, y: 0, width: 0, height: 17)
    var fileIconImageViewFrame: CGRect {
        let height = FileView.Cons.fileNameFont.rowHeight + FileView.Cons.sizeAndRateFont.rowHeight + 4
        return CGRect(x: 12, y: 14, width: 40.auto(), height: height)
    }
    var lanTransIconImageViewFrame: CGRect {
        let fileIconFrame = fileIconImageViewFrame
        let lanIconSize: CGFloat = 28.auto()
        return CGRect(
            x: fileIconFrame.maxX - floor(lanIconSize / 3 * 2),
            y: fileIconFrame.maxY - floor(lanIconSize / 3 * 2),
            width: lanIconSize,
            height: lanIconSize
        )
    }
    var layoutEngine: LKTextLayoutEngine?
}

final class FileViewLayoutConfig {
    var fileName: String = ""
    var statusText: String = ""
    var sizeText: String = ""
    var lastEditInfoText = ""
    var rate: String = ""
    var bottomSpaceHeight: CGFloat = 12
    var preferMaxWidth: CGFloat = 0
    var fitSize = CGSize.zero
    var hasPermissionPreview: Bool = true
    var dynamicAuthorityEnum: DynamicAuthorityEnum = .loading
    var hasPermissionPreviewAndReceive: Bool {
        return hasPermissionPreview && dynamicAuthorityEnum.authorityAllowed
    }
}

public struct FileAndFolderViewConfig {
    public static let contentMaxWidth: CGFloat = 400
}

// fileViewLayout 布局类
// 根据输入的fileName和BottomSpaceSize计算出FileVie各个控件的布局
final class FileViewLayout {
    static let fileViewMaxWidth: CGFloat = FileAndFolderViewConfig.contentMaxWidth

    var layoutResult: FileViewLayoutResult = FileViewLayoutResult()
    let layoutConfig = FileViewLayoutConfig()

    var fileName = ""
    var statusText = ""
    var sizeText = ""
    var lastEditInfoText = ""
    var rateText = ""
    var fileNamelabelHeight: CGFloat = 24
    var sizeAndRateLableHeight: CGFloat = 17
    var noPermissionLabelHeight: CGFloat = 17
    private var sizeAndRateWidth: CGFloat = 0
    private var fileViewWidth: CGFloat = -1
    private var statusSize: CGSize = CGSize(width: 0, height: 17)
    private var hasPermissionPreview: Bool = true
    private var dynamicAuthorityEnum: DynamicAuthorityEnum = .loading

    private var hasPermissionPreviewAndReceive: Bool {
        return hasPermissionPreview && dynamicAuthorityEnum.authorityAllowed
    }

    func layoutViewIfNeed() -> CGSize {
        var needLayout = false
        //文件名变化 导致高度变化 需要重新布局
        if self.fileName != layoutConfig.fileName {
           self.fileName = layoutConfig.fileName
            self.updateLabelHeight(hasPermissionPreviewAndReceive: layoutConfig.hasPermissionPreviewAndReceive)
            needLayout = true
        }

        let preferMaxWidth = self.fileViewWithPreferMaxWidth(layoutConfig.preferMaxWidth)
        if self.hasPermissionPreview != layoutConfig.hasPermissionPreview {
            self.hasPermissionPreview = layoutConfig.hasPermissionPreview
            needLayout = true
        }
        if self.dynamicAuthorityEnum != layoutConfig.dynamicAuthorityEnum {
            self.dynamicAuthorityEnum = layoutConfig.dynamicAuthorityEnum
            needLayout = true
        }
        //速率，大小，阅读状态是否改变
        if self.statusText != layoutConfig.statusText || self.sizeText != layoutConfig.sizeText || self.rateText != layoutConfig.rate || self.lastEditInfoText != layoutConfig.lastEditInfoText {
            self.statusText = layoutConfig.statusText
            self.sizeText = layoutConfig.sizeText
            self.lastEditInfoText = layoutConfig.lastEditInfoText
            self.rateText = layoutConfig.rate
            self.updateSizeAndRate(maxWidth: preferMaxWidth)
            needLayout = true
        }
        // 无预览权限
        if !layoutConfig.hasPermissionPreviewAndReceive {
            self.updateNoPermissionHintFrame(maxWidth: preferMaxWidth)
        }

        // 更新完NameLabel的高度之后 就可以更新 fileViewSize
        let fileViewSize = self.sizeToFit(layoutConfig.fitSize, preferMaxWidth: layoutConfig.preferMaxWidth)
        if fileViewSize.width != fileViewWidth {
            fileViewWidth = fileViewSize.width
            needLayout = true
        }

        //吸附底部的view 需要更新y的值
        self.layoutResult.progressViewFrame.origin.y = fileViewSize.height - self.layoutResult.progressViewFrame.size.height
        self.layoutResult.bottomBorderViewFrame.origin.y = fileViewSize.height - self.layoutResult.bottomBorderViewFrame.size.height

        if needLayout {
            self.updateFrames(hasPermissionPreviewAndReceive: layoutConfig.hasPermissionPreviewAndReceive)
        }
        return fileViewSize
    }

    private func updateLabelHeight(hasPermissionPreviewAndReceive: Bool) {
        if self.fileName.isEmpty {
            self.fileNamelabelHeight = 24
        } else {
            let width = self.fileViewWithPreferMaxWidth(self.layoutConfig.preferMaxWidth)
            let textAttributes = hasPermissionPreviewAndReceive ? FileView.Cons.fileViewTextAttributes : FileView.Cons.noPermissionPreviewfileViewTextAttributes
            let (layoutEngine, nameLabelHeight) = FileViewTextLayout.contentHeight(text: self.fileName,
                                                                                   size: CGSize(width: width - 48 - 30.auto(), height: 500),
                                                                                   textAttributes: textAttributes)
            self.fileNamelabelHeight = nameLabelHeight
            self.layoutResult.layoutEngine = layoutEngine
        }
    }

    func updateSizeAndRate(maxWidth: CGFloat) {
        var sizeAndRateStr = sizeText + lastEditInfoText + rateText
        var sizeAndRateSize: CGSize = FileViewTextLayout.textSizeForSystemFont(
            text: sizeAndRateStr,
            fontSize: FileView.Cons.sizeAndRateFont.pointSize,
            width: maxWidth - 16 * 3 - 30.auto()
        )
        sizeAndRateWidth = sizeAndRateSize.width
        statusSize = FileViewTextLayout.textSizeForSystemFont(
            text: statusText,
            fontSize: FileView.Cons.fileStatusFont.pointSize,
            width: maxWidth - sizeAndRateWidth - 16 * 3 - 30.auto() - 4
        )
        self.sizeAndRateLableHeight = sizeAndRateSize.height
    }

    func updateNoPermissionHintFrame(maxWidth: CGFloat) {
        var noPermissionHintSize: CGSize = FileViewTextLayout.textSizeForSystemFont(
            text: ChatSecurityControlServiceImpl.getNoPermissionSummaryText(permissionPreview: layoutConfig.hasPermissionPreview,
                                                                            dynamicAuthorityEnum: layoutConfig.dynamicAuthorityEnum,
                                                                            sourceType: .file),
            fontSize: FileView.Cons.noPermissionHintFont.pointSize,
            width: maxWidth - 16 * 3 - 30.auto()
        )
        self.noPermissionLabelHeight = noPermissionHintSize.height
    }

    private func updateFrames(hasPermissionPreviewAndReceive: Bool) {
        // 更新约束
        self.layoutResult.topBorderViewFrame.size.width = fileViewWidth
        self.layoutResult.bottomBorderViewFrame.size.width = fileViewWidth

        self.layoutResult.progressViewFrame.size.width = fileViewWidth

        self.layoutResult.nameLabelFrame.size.width = fileViewWidth - 16 * 3 - 30.auto()
        self.layoutResult.nameLabelFrame.size.height = self.fileNamelabelHeight

        if hasPermissionPreviewAndReceive {
            self.layoutResult.sizeAndRateLabelFrame.origin.y = 12 + self.fileNamelabelHeight + 4
            self.layoutResult.sizeAndRateLabelFrame.size.width = self.sizeAndRateWidth
            self.layoutResult.sizeAndRateLabelFrame.size.height = self.sizeAndRateLableHeight
            self.layoutResult.statusLabelFrame.origin.x = 62 + self.sizeAndRateWidth + (self.sizeText.isEmpty ? 0 : 4)
            self.layoutResult.statusLabelFrame.origin.y = 12 + self.fileNamelabelHeight + 4
            self.layoutResult.statusLabelFrame.size.width = statusSize.width
            self.layoutResult.statusLabelFrame.size.height = statusSize.height
            self.layoutResult.noPermissionLabelFrame.size = .zero
        } else {
            self.layoutResult.noPermissionLabelFrame.size = .init(width: 200, height: 17)
            self.layoutResult.noPermissionLabelFrame.origin.y = 12 + self.fileNamelabelHeight + 4
            self.layoutResult.sizeAndRateLabelFrame.size = .zero
            self.layoutResult.statusLabelFrame.size = .zero
        }
    }

    func sizeToFit(_ size: CGSize, preferMaxWidth: CGFloat) -> CGSize {
        var height: CGFloat
        if hasPermissionPreviewAndReceive {
            var contentHeight = self.sizeAndRateLableHeight > self.statusSize.height ? self.sizeAndRateLableHeight : self.statusSize.height
            height = 12 + self.fileNamelabelHeight + 4 + contentHeight + self.layoutConfig.bottomSpaceHeight

        } else {
            height = 12 + self.fileNamelabelHeight + 4 + self.layoutConfig.bottomSpaceHeight + self.noPermissionLabelHeight
        }
        return CGSize(width: self.fileViewWithPreferMaxWidth(preferMaxWidth), height: height)
    }

    func fileViewWithPreferMaxWidth(_ preferMaxWidth: CGFloat) -> CGFloat {
        //fileView的宽度 要有 preferMaxWidth 和 实际的fitSize.width 对比出来
        return min(preferMaxWidth, self.layoutConfig.fitSize.width)
    }

    func copyLayoutResultTo(_ layoutResult: inout FileViewLayoutResult) {
        layoutResult.nameLabelFrame = self.layoutResult.nameLabelFrame
        layoutResult.statusLabelFrame = self.layoutResult.statusLabelFrame
        layoutResult.progressViewFrame = self.layoutResult.progressViewFrame
        layoutResult.topBorderViewFrame = self.layoutResult.topBorderViewFrame
        layoutResult.bottomBorderViewFrame = self.layoutResult.bottomBorderViewFrame
        layoutResult.layoutEngine = self.layoutResult.layoutEngine
        layoutResult.sizeAndRateLabelFrame = self.layoutResult.sizeAndRateLabelFrame
        layoutResult.noPermissionLabelFrame = self.layoutResult.noPermissionLabelFrame
    }
}
