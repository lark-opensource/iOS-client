//
//  V3ListExtensionView.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/22.
//

import Foundation
import UIKit
import UniverseDesignIcon

// MARK: - List Extension: [SubTasks, Attachments, Comments]

struct V3ListExtensionInfo {
    // 子任务进度
    var subTasksProgress: String?
    var subTasksProgressWidth: CGFloat = 0
    // 附件数
    var attachmentsCnt: String?
    var attachmentsCntWidth: CGFloat = 0
    // 评论数
    var commentsCnt: String?
    var commentsCntWidth: CGFloat = 0
    // 总长度
    var totalWidth: CGFloat = 0
}

final class V3ListExtensionView: UIView {

    var viewData: V3ListExtensionInfo? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            if let subTask = viewData.subTasksProgress {
                subTaskView.isHidden = false
                subTaskView.viewData = .init(countStr: subTask, countStrWidth: viewData.subTasksProgressWidth)
            } else {
                subTaskView.isHidden = true
            }
            if let attachment = viewData.attachmentsCnt {
                attachmentView.isHidden = false
                attachmentView.viewData = .init(countStr: attachment, countStrWidth: viewData.attachmentsCntWidth)
            } else {
                attachmentView.isHidden = true
            }
            if let comment = viewData.commentsCnt {
                commentView.isHidden = false
                commentView.viewData = .init(countStr: comment, countStrWidth: viewData.commentsCntWidth)
            } else {
                commentView.isHidden = true
            }
            setNeedsLayout()
        }
    }

    private lazy var subTaskView: V3ListIconTextView = {
        let icon = UDIcon.getIconByKey(
            .subtasksOutlined,
            iconColor: UIColor.ud.iconN3,
            size: ListConfig.Cell.extensionIconSize
        )
        return V3ListIconTextView(icon: icon)
    }()

    private lazy var attachmentView: V3ListIconTextView = {
        let icon = UDIcon.getIconByKey(
            .attachmentOutlined,
            iconColor: UIColor.ud.iconN3,
            size: ListConfig.Cell.extensionIconSize
        )
        return V3ListIconTextView(icon: icon)
    }()

    private lazy var commentView: V3ListIconTextView = {
        let icon = UDIcon.getIconByKey(
            .addCommentOutlined,
            iconColor: UIColor.ud.iconN3,
            size: ListConfig.Cell.extensionIconSize
        )
        return V3ListIconTextView(icon: icon)
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(subTaskView)
        addSubview(attachmentView)
        addSubview(commentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let viewData = viewData else { return }
        let iconY = (ListConfig.Cell.extensionHeight - ListConfig.Cell.extensionIconSize.height) / 2
        let iconHeight = ListConfig.Cell.extensionIconSize.height
        let iconWidth = ListConfig.Cell.extensionIconSize.width + ListConfig.Cell.extensionIconTextSpace
        switch (subTaskView.isHidden, attachmentView.isHidden, commentView.isHidden) {
        case (false, false, false):
            // 三个都显示
            subTaskView.frame = CGRect(
                x: 0,
                y: iconY,
                width: iconWidth + viewData.subTasksProgressWidth,
                height: iconHeight
            )
            attachmentView.frame = CGRect(
                x: subTaskView.frame.maxX + ListConfig.Cell.extensionSpace,
                y: iconY,
                width: iconWidth + viewData.attachmentsCntWidth,
                height: iconHeight
            )
            commentView.frame = CGRect(
                x: attachmentView.frame.maxX + ListConfig.Cell.extensionSpace,
                y: iconY,
                width: iconWidth + viewData.commentsCntWidth,
                height: iconHeight
            )
        case (true, false, false):
            // subTask隐藏，attachment 和 comment 显示
            attachmentView.frame = CGRect(
                x: 0,
                y: iconY,
                width: iconWidth + viewData.attachmentsCntWidth,
                height: iconHeight
            )
            commentView.frame = CGRect(
                x: attachmentView.frame.maxX + ListConfig.Cell.extensionSpace,
                y: iconY,
                width: iconWidth + viewData.commentsCntWidth,
                height: iconHeight
            )
        case (true, true, false):
            // subTask attachment隐藏 comment 显示
            commentView.frame = CGRect(
                x: 0,
                y: iconY,
                width: iconWidth + viewData.commentsCntWidth,
                height: iconHeight
            )
        case (true, false, true):
            // attachment 显示 subTask, comment 隐藏
            attachmentView.frame = CGRect(
                x: 0,
                y: iconY,
                width: iconWidth + viewData.attachmentsCntWidth,
                height: iconHeight
            )
        case (false, true, false):
            // subTask 显示，attachment 隐藏 comment 显示
            subTaskView.frame = CGRect(
                x: 0,
                y: iconY,
                width: iconWidth + viewData.subTasksProgressWidth,
                height: iconHeight
            )
            commentView.frame = CGRect(
                x: subTaskView.frame.maxX + ListConfig.Cell.extensionSpace,
                y: iconY,
                width: iconWidth + viewData.commentsCntWidth,
                height: iconHeight
            )
        case (false, false, true):
            // subTask, attachment 显示 comment 隐藏
            subTaskView.frame = CGRect(
                x: 0,
                y: iconY,
                width: iconWidth + viewData.subTasksProgressWidth,
                height: iconHeight
            )
            attachmentView.frame = CGRect(
                x: subTaskView.frame.maxX + ListConfig.Cell.extensionSpace,
                y: iconY,
                width: iconWidth + viewData.attachmentsCntWidth,
                height: iconHeight
            )
        case (false, true, true):
            // subTask 显示，attachment comment 隐藏
            subTaskView.frame = CGRect(
                x: 0,
                y: iconY,
                width: iconWidth + viewData.subTasksProgressWidth,
                height: iconHeight
            )
        case (true, true, true): break
        }
    }

}

// MARK: - List Extension: Dot? + Icon + Text

struct V3ListIconTextInfo {
    // 个数
    var countStr: String
    // 宽度
    var countStrWidth: CGFloat
}

private final class V3ListIconTextView: UIView {

    var viewData: V3ListIconTextInfo? {
        didSet {
            if let viewData = viewData {
                label.isHidden = false
                iconView.isHidden = false
                label.text = viewData.countStr
            } else {
                iconView.isHidden = true
                label.isHidden = true
            }
            setNeedsLayout()
        }
    }

    private let icon: UIImage
    private lazy var iconView: UIImageView = {
        return UIImageView(image: icon)
    }()
    private lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = ListConfig.Cell.detailFont
        label.numberOfLines = 1
        return label
    }()

    init(icon: UIImage) {
        self.icon = icon
        super.init(frame: .zero)
        addSubview(label)
        addSubview(iconView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let viewData = viewData else { return }
        iconView.frame = CGRect(
            x: 0,
            y: (frame.height - ListConfig.Cell.extensionIconSize.height) / 2,
            width: ListConfig.Cell.extensionIconSize.width,
            height: ListConfig.Cell.extensionIconSize.height
        )
        label.frame = CGRect(
            x: iconView.frame.maxX + ListConfig.Cell.extensionIconTextSpace,
            y: 0,
            width: viewData.countStrWidth,
            height: frame.height
        )
    }
}
