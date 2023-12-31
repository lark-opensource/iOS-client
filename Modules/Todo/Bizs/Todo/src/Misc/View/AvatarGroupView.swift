//
//  AvatarGroupView.swift
//  Todo
//
//  Created by wangwanxin on 2022/9/16.
//

import UIKit
import LarkBizAvatar
import UniverseDesignIcon
import UniverseDesignFont

/// AvatarGroupView 基本结构如下：
///
///     +----------------------------------------+
///     | [Avatar][Check]                        |
///     |      [Avatar][Check]                   |
///     |          [Avatar][Check]               |
///     |                          [Count]       |
///     +----------------------------------------+
///     需要

/// View Data
struct AvatarGroupViewData {
    // 展示的头像
    var avatars: [CheckedAvatarViewData]
    // UI上展示的数字
    var remainCount: String?
    // 数字宽度
    var remainCntWidth: CGFloat?
    // 总宽度
    var width: CGFloat?

    init(avatars: [CheckedAvatarViewData], style: CheckedAvatarView.Style, remainCount: Int? = nil) {
        self.avatars = avatars
        makeData(by: remainCount, and: style)
    }
}

extension AvatarGroupViewData {

    /// 构建GroupViewData
    /// - Parameters:
    ///   - totalCnt: nil 为不展示数字
    ///   - style: 类型
    mutating func makeData(by remainCnt: Int?, and style: CheckedAvatarView.Style) {
        // 展示个数
        let dispalyCnt = avatars.count
        // 总个数
        let totalCnt = remainCnt ?? 0
        var totalCountStr: String?
        if totalCnt >= 1_000 {
            totalCountStr = "+999+"
        } else if totalCnt >= 1 {
            totalCountStr = "+\(totalCnt)"
        } else {
            totalCountStr = nil
        }

        // 总个数的数字宽度, 总长度
        var totalCountStrW: CGFloat?, allWidth: CGFloat?
        if let countStr = totalCountStr {
            if totalCnt >= 10 {
                let w = CGFloat(ceil(countStr.size(withAttributes: [
                    .font: style.font
                ]).width))
                totalCountStrW = style.countPadding * 2 + w
            } else {
                totalCountStrW = style.width
            }
            allWidth = style.width * CGFloat(dispalyCnt) - style.space * CGFloat(dispalyCnt - 1) + (totalCountStrW ?? 0) - style.space
        } else {
            allWidth = style.width * CGFloat(dispalyCnt) - style.space * CGFloat(dispalyCnt - 1)
        }
        remainCount = totalCountStr
        remainCntWidth = totalCountStrW
        width = allWidth
    }

}

final class AvatarGroupView: UIView {
    var viewData: AvatarGroupViewData? {
        didSet {
            guard let viewData = viewData else { return }
            generateAvatarViews(by: viewData.avatars, with: viewData.remainCount)
            invalidateIntrinsicContentSize()
        }
    }

    // 更新board的color
    var borderColor: UIColor? = UIColor.ud.bgBodyOverlay {
        didSet {
            guard let color = borderColor else { return }
            avatarViews.forEach { view in
                view.boarderColor = color
            }
            countBoarder.backgroundColor = color
        }
    }

    private var avatarViews: [CheckedAvatarView] = []
    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.ud.textCaption
        label.backgroundColor = UIColor.ud.N300
        label.layer.cornerRadius = style.width / 2
        label.layer.masksToBounds = true
        label.font = style.font
        return label
    }()
    private lazy var countBoarder: UIView = {
        let view = UIView()
        view.layer.cornerRadius = (style.width + style.boarderWidth) / 2
        view.layer.masksToBounds = true
        return view
    }()
    private let style: CheckedAvatarView.Style

    init(style: CheckedAvatarView.Style = .normal) {
        self.style = style
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func generateAvatarViews(by avatars: [CheckedAvatarViewData]?, with totalCount: String?) {
        for view in avatarViews {
            view.removeFromSuperview()
        }
        countBoarder.removeFromSuperview()
        countLabel.removeFromSuperview()
        avatarViews.removeAll()
        guard let avatars = avatars, !avatars.isEmpty else { return }
        var countBoarderBgColor = UIColor.ud.bgBodyOverlay
        for (_, data) in avatars.enumerated() {
            let view = CheckedAvatarView(style: style)
            view.viewData = data
            addSubview(view)
            avatarViews.append(view)
            countBoarderBgColor = data.boarderColor
        }

        guard let totalCount = totalCount, !totalCount.isEmpty else { return }
        addSubview(countBoarder)
        addSubview(countLabel)
        countBoarder.backgroundColor = countBoarderBgColor
        countLabel.text = totalCount
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        for (index, view) in avatarViews.enumerated() {
            view.frame = CGRect(
                x: CGFloat(index * style.offset),
                y: 0,
                width: style.width,
                height: style.height
            )
        }
        if !countLabel.isHidden {
            countLabel.frame = CGRect(
                x: CGFloat(avatarViews.count * style.offset),
                y: 0,
                width: viewData?.remainCntWidth ?? 0,
                height: style.height
            )
            countBoarder.frame = CGRect(
                x: 0,
                y: 0,
                width: countLabel.frame.width + style.boarderWidth,
                height: countLabel.frame.height + style.boarderWidth
            )
            countBoarder.center = countLabel.center
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: viewData?.width ?? 0, height: style.height)
    }

}

///
///     +----------------------------------------+
///     | [Avatar][Check]                        |
///     +----------------------------------------+
struct CheckedAvatarViewData {
    enum IconType {
        case avatar(AvatarSeed)
        case image(UIImage)
    }
    var icon: IconType?
    var isChecked: Bool = false
    var boarderColor: UIColor = UIColor.ud.bgBodyOverlay
}

final class CheckedAvatarView: UIView {
    // Avatar 尺寸
    enum Style {
        // 用于分享面板
        case superBig
        // 目前用于详情页，列表
        case big
        // 用于快捷创建
        case normal

        var height: CGFloat {
            switch self {
            case .superBig: return 30.0
            case .big: return 24.0
            case .normal: return 20.0
            }
        }
        var width: CGFloat { height }

        var boarderWidth: CGFloat { 2.0 }
        // 间距
        var offset: Int { Int(width - space) }
        // 两个头像间的距离
        var space: CGFloat {
            switch self {
            case .superBig: return 4.0
            default: return 2.0
            }
        }

        var countPadding: CGFloat { 8.0 }

        var checkViewWith: CGFloat { 10.0 }
        var checkViewHeight: CGFloat { checkViewWith }

        var font: UIFont {
            switch self {
            case .big, .superBig: return UDFont.systemFont(ofSize: 14, weight: .medium)
            case .normal: return UDFont.systemFont(ofSize: 12, weight: .medium)
            }
        }
    }

    var viewData: CheckedAvatarViewData? {
        didSet {
            guard let viewData = viewData, let icon = viewData.icon else { return }
            updteView(by: icon, isChecked: viewData.isChecked, boarderColor: viewData.boarderColor)
        }
    }

    var boarderColor: UIColor? {
        didSet {
            guard let color = boarderColor else { return }
            avatar.updateBorderImage((Resources.QucikCreate.avatarBoarder).ud.withTintColor(color))
        }
    }

    private let style: Style
    private lazy var avatar = BizAvatar()
    private lazy var imageView = UIImageView()
    private lazy var checkView: UIImageView = {
        let image = UDIcon.getIconByKey(
            .yesFilled,
            iconColor: UIColor.ud.primaryContentDefault,
            size: CGSize(width: style.checkViewWith, height: style.checkViewHeight)
        )
        return UIImageView(image: image)
    }()
    private lazy var checkColorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        return view
    }()

    init(style: CheckedAvatarView.Style = .normal) {
        self.style = style
        super.init(frame: .zero)
        addSubview(avatar)
        addSubview(imageView)
        addSubview(checkColorView)
        addSubview(checkView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updteView(by icon: CheckedAvatarViewData.IconType, isChecked: Bool, boarderColor: UIColor) {
        switch icon {
        case .avatar(let data):
            avatar.isHidden = false
            imageView.isHidden = true
            avatar.setAvatarByIdentifier(
                data.avatarId,
                avatarKey: data.avatarKey,
                avatarViewParams: .init(sizeType: .size(style.width), format: .webp)
            )
        case .image(let image):
            avatar.isHidden = true
            imageView.isHidden = false
            imageView.image = image
        }
        avatar.updateBorderSize(CGSize(width: style.width + style.boarderWidth,
                                       height: style.height + style.boarderWidth))
        avatar.updateBorderImage((Resources.QucikCreate.avatarBoarder).ud.withTintColor(boarderColor))
        if isChecked {
            checkView.isHidden = false
            checkColorView.isHidden = false
        } else {
            checkView.isHidden = true
            checkColorView.isHidden = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatar.frame = CGRect(x: 0, y: 0, width: style.width, height: style.height)
        imageView.frame = CGRect(x: 0, y: 0, width: style.width, height: style.height)
        if !checkView.isHidden {
            checkView.frame = CGRect(
                x: style.width + style.boarderWidth - style.checkViewWith,
                y: style.height + style.boarderWidth - style.checkViewHeight,
                width: style.checkViewWith,
                height: style.checkViewHeight
            )
            checkColorView.frame.size = CGSize(width: 6, height: 6)
            checkColorView.frame.center = checkView.frame.center
        }
    }
}
