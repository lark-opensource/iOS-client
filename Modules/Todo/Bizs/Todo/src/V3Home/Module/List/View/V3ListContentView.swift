//
//  V3ListContentView.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/22.
//

import Foundation
import LarkBizAvatar

// MARK: - List Content
/// V3ListContentView 基本结构如下：
///
///     +----------------------------------------+
///     | [ checkBox ] |-- title ----------------|
///     |              |-- title ----------------|
///     |              |-- time -----------------|
///     |              |-- extension ------------|
///     +----------------------------------------+
///

final class V3ListContentView: UIView {

    var viewData: V3ListContentData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            checkbox.viewData = {
                var data = CheckBoxViewData()
                data.identifier = viewData.checkboxInfo.identifier
                data.checkState = viewData.checkboxInfo.state
                data.isRotated = viewData.checkboxInfo.isRotated
                return data
            }()

            titleLabel.clearRenderContent()
            titleLabel.outOfRangeText = viewData.titleInfo.outOfRangeText
            titleLabel.attributedText = viewData.titleInfo.title

            if let owner = viewData.ownerInfo {
                ownerView.isHidden = false
                ownerView.viewData = owner
            } else {
                ownerView.isHidden = true
            }

            if let timeInfo = viewData.timeInfo {
                timeView.isHidden = false
                timeView.viewData = timeInfo
            } else {
                timeView.isHidden = true
            }

            if let extensionInfo = viewData.extensionInfo {
                extensionView.isHidden = false
                extensionView.viewData = extensionInfo
            } else {
                extensionView.isHidden = true
            }
            setNeedsLayout()
        }
    }

    // checkbox
    private(set) lazy var checkbox = Todo.Checkbox()
    // title
    private lazy var titleLabel: RichContentLabel = {
        var titleLabel = RichContentLabel()
        titleLabel.isUserInteractionEnabled = false
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.numberOfLines = 2
        // url自动刷新
        titleLabel.needsAutoUpdate = { [weak self] state in
            guard let self = self, case .needsUpdate(let entity) = state else { return nil }
            return entity
        }
        return titleLabel
    }()
    private(set) lazy var ownerView: AvatarGroupView = AvatarGroupView(style: .big)
    // time
    private lazy var timeView = V3ListTimeView()

    private lazy var separateLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    // extension
    private lazy var extensionView = V3ListExtensionView()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = .clear
        setupSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubViews() {
        checkbox.hitTestEdgeInsets = UIEdgeInsets(top: -12, left: -12, bottom: -12, right: -12)
        addSubview(checkbox)
        addSubview(titleLabel)
        addSubview(ownerView)
        addSubview(separateLine)
        addSubview(timeView)
        addSubview(extensionView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let viewData = viewData else { return }
        typealias Config = ListConfig.Cell
        checkbox.frame = CGRect(
            origin: CGPoint(x: Config.leftPadding, y: 0),
            size: Config.checkBoxSize
        )

        let contentLeft = checkbox.frame.maxX + Config.horizontalSpace
        // 内容最大宽度
        let contentMaxW = frame.width - contentLeft - Config.rightPadding
        var titleMax = contentMaxW
        if !ownerView.isHidden {
            titleMax = contentMaxW - Config.horizontalSpace - (viewData.ownerInfo?.width ?? 0)
        }

        let multiLine = viewData.titleInfo.size.width > titleMax
        titleLabel.frame = CGRect(
            x: contentLeft,
            y: multiLine ? Config.topPadding - Config.singleSpace : Config.topPadding + Config.singleSpace,
            width: titleMax,
            height: multiLine ? Config.maxTitleHeight : Config.minTitleHeight
        )
        checkbox.frame.origin.y = Config.topPadding + Config.checkBoxTop
        separateLine.frame = .zero
        if !ownerView.isHidden {
            ownerView.frame = CGRect(
                x: frame.width - Config.rightPadding - (viewData.ownerInfo?.width ?? 0),
                y: Config.topPadding,
                width: viewData.ownerInfo?.width ?? 0,
                height: Config.userHeight
            )
        }

        switch (timeView.isHidden, extensionView.isHidden) {
        case (false, false):
            // time extension 都显示
            if ((viewData.timeInfo?.totalWidth ?? 0) + (viewData.extensionInfo?.totalWidth ?? 0) + Config.separateWidth + Config.separateSpace * 2) <= contentMaxW {
                timeView.frame = CGRect(
                    x: contentLeft,
                    y: titleLabel.frame.maxY + Config.verticalSpace,
                    width: viewData.timeInfo?.totalWidth ?? 0,
                    height: Config.timeHeight
                )
                separateLine.frame = CGRect(
                    x: timeView.frame.maxX + Config.separateSpace,
                    y: 0,
                    width: Config.separateWidth,
                    height: Config.separateHeight
                )
                separateLine.frame.centerY = timeView.frame.centerY
                extensionView.frame = CGRect(
                    x: separateLine.frame.maxX + Config.separateSpace,
                    y: titleLabel.frame.maxY + Config.verticalSpace,
                    width: viewData.extensionInfo?.totalWidth ?? 0,
                    height: Config.extensionHeight
                )
            } else {
                timeView.frame = CGRect(
                    x: contentLeft,
                    y: titleLabel.frame.maxY + Config.verticalSpace,
                    width: contentMaxW,
                    height: Config.timeHeight
                )
                separateLine.frame = .zero
                extensionView.frame = CGRect(
                    x: contentLeft,
                    y: timeView.frame.maxY + Config.verticalSpace,
                    width: contentMaxW,
                    height: Config.extensionHeight
                )
            }
        case (true, false):
            // time 隐藏 extension 都显示
            extensionView.frame = CGRect(
                x: contentLeft,
                y: titleLabel.frame.maxY + Config.verticalSpace,
                width: contentMaxW,
                height: Config.extensionHeight
            )
        case (false, true):
            // time 显示 extension 隐藏
            timeView.frame = CGRect(
                x: contentLeft,
                y: titleLabel.frame.maxY + Config.verticalSpace,
                width: contentMaxW,
                height: Config.timeHeight
            )
        case (true, true):
            if viewData.titleInfo.size.width > titleMax {
                // 多行
            } else {
                // 单行需要居中
                titleLabel.frame.centerY = frame.height / 2
                checkbox.frame.centerY = titleLabel.frame.centerY
                if !ownerView.isHidden {
                    ownerView.frame.centerY = titleLabel.frame.centerY
                }
            }
        }
    }
}
