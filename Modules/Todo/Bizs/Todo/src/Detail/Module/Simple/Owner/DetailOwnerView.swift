//
//  DetailOwnerView.swift
//  Todo
//
//  Created by wangwanxin on 2022/7/18.
//

import CTFoundation
import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import LarkBizAvatar

struct DetailOwnerViewData {
    enum Scene {
        case empty
        case single(canClear: Bool)
        case multi(showIcon: Bool)
    }

    var avatars: [(seed: AvatarSeed, isCompleted: Bool)] = []
    var contentText: String?
    var scene: Scene = .empty
    var sectionText: String?
}

final class DetailOwnerView: BasicCellLikeView, ViewDataConvertible {

    var viewData: DetailOwnerViewData? {
        didSet {
            guard let viewData = viewData else { return }
            switch viewData.scene {
            case .empty:
                content = .customView(emptyView)
                emptyView.onTapHandler = onEmptyHandler
            case .single(let canClear):
                content = .customView(contentView)
                let icon: UIImage? = canClear ? UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 14, height: 14)) : nil
                let avatars = viewData.avatars.map { CheckedAvatarViewData(icon: .avatar($0.seed), isChecked: $0.isCompleted) }
                let groupViewData = AvatarGroupViewData(avatars: avatars, style: .big)
                contentView.userView.viewData = DetailUserViewData(
                    avatarData: groupViewData,
                    content: viewData.contentText,
                    icon: icon
                )
                if let sectionText = viewData.sectionText {
                    contentView.sectionView.isHidden = false
                    contentView.sectionView.sectionText = sectionText
                    contentView.sectionView.onTapHandler = onTapSection
                } else {
                    contentView.sectionView.isHidden = true
                    contentView.sectionView.sectionText = nil
                    contentView.sectionView.onTapHandler = nil
                }
                contentView.userView.onTapIconHandler = onSingleClearHandler
                contentView.userView.onTapContentHandler = onSingleContentHandler
                contentView.setNeedsLayout()
            case .multi(let showIcon):
                content = .customView(contentView)
                let icon = showIcon ? UDIcon.rightOutlined.ud.resized(to: CGSize(width: 14, height: 14)) : nil
                let avatars = viewData.avatars.map { CheckedAvatarViewData(icon: .avatar($0.seed), isChecked: $0.isCompleted) }
                let groupViewData = AvatarGroupViewData(avatars: Array(avatars.prefix(5)), style: .big)
                contentView.userView.viewData = DetailUserViewData(
                    avatarData: groupViewData,
                    content: viewData.contentText,
                    icon: icon
                )
                if let sectionText = viewData.sectionText {
                    contentView.sectionView.isHidden = false
                    contentView.sectionView.sectionText = sectionText
                    contentView.sectionView.onTapHandler = onTapSection
                } else {
                    contentView.sectionView.isHidden = true
                    contentView.sectionView.sectionText = nil
                    contentView.sectionView.onTapHandler = nil
                }
                contentView.userView.onTapIconHandler = onMultiHandler
                contentView.userView.onTapContentHandler = onMultiHandler
                contentView.setNeedsLayout()
            }
        }
    }

    var onEmptyHandler: (() -> Void)?
    var onSingleClearHandler: (() -> Void)?
    var onSingleContentHandler: (() -> Void)?
    var onMultiHandler: (() -> Void)?
    var onTapSection: (() -> Void)?

    private lazy var emptyView = initEmptyView()
    private lazy var contentView = DetailOwnerContaienrView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let ownerIcon = UDIcon.getIconByKey(
            .memberOutlined,
            renderingMode: .automatic,
            iconColor: nil,
            size: CGSize(width: 20, height: 20)
        )
        iconAlignment = .centerVertically
        content = .customView(emptyView)
        icon = .customImage(ownerIcon.ud.withTintColor(UIColor.ud.iconN3))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.noIntrinsicMetric, height: 48)
    }

    private func initEmptyView() -> DetailEmptyView {
        let view = DetailEmptyView()
        view.text = I18N.Todo_TaskDetails_AddAnOwner_Button
        return view
    }
}

final class DetailOwnerSectionView: UIView {

    var sectionText: String? {
        didSet {
            guard let sectionText = sectionText else {
                isHidden = true
                return
            }
            isHidden = false
            sectionView.text = sectionText
        }
    }

    var onTapHandler: (() -> Void)? {
        didSet { sectionView.onTapHandler = onTapHandler }
    }

    private lazy var separateLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var sectionView = DetailTaskListContentRightView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(separateLine)
        addSubview(sectionView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        separateLine.frame = CGRect(
            x: 0,
            y: (bounds.height - 20) / 2,
            width: 1.0,
            height: 20
        )

        sectionView.frame = CGRect(
            x: 7,
            y: 0,
            width: bounds.width - 7,
            height: bounds.height
        )
    }

    override var intrinsicContentSize: CGSize {
        let width = sectionView.intrinsicContentSize.width + separateLine.frame.width + 7.0
        return CGSize(width: width, height: 36.0)
    }
}

final class DetailOwnerContaienrView: UIView {

    private(set) lazy var userView = DetailUserContentView()

    private(set) lazy var sectionView = DetailOwnerSectionView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(userView)
        addSubview(sectionView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let userIntrisicW = userView.intrinsicContentSize.width
        if sectionView.isHidden {
            // 可以显示
            userView.frame = CGRect(
                x: 0,
                y: 0,
                width: userIntrisicW,
                height: 48
            )
            return
        }
        // 这里也有碰撞检测，分组最小宽度64
        let sectionIntrisicW = sectionView.intrinsicContentSize.width
        // 两边的padding 16 + 16
        let totalMaxWidth = bounds.width - 32, ownerMaxWidth = totalMaxWidth - 72.0, sectionMaxWidth = totalMaxWidth - userIntrisicW
        var userWidth = userIntrisicW, sectionWidth = sectionIntrisicW
        if userIntrisicW + sectionIntrisicW > totalMaxWidth {
            // 不可以显示
            userWidth = min(userWidth, ownerMaxWidth)
            sectionWidth = max(sectionMaxWidth, 72.0)
        } else {
            // 可以显示
            sectionWidth = max(sectionIntrisicW, 72.0)
        }

        // 不可以显示
        userView.frame = CGRect(
            x: 0,
            y: 0,
            width: userWidth,
            height: 48
        )
        sectionView.frame = CGRect(
            x: userView.frame.maxX + 16,
            y: 0,
            width: sectionWidth,
            height: 48
        )
    }

}
