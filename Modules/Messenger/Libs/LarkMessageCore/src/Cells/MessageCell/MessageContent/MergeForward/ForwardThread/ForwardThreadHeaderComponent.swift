//
//  ForwardThreadHeaderComponent.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/3/29.
//

import UIKit
import Foundation
import RichLabel
import LarkBizAvatar
import AsyncComponent
import LarkMessageBase
import UniverseDesignFont

/// 发帖人 + 发帖群
final class ForwardThreadHeader: UIView {
    /// 发帖人头像
    private let avatarView = LarkMedalAvatar(frame: .zero)
    /// 发帖人名称
    private let nameLabel: LKLabel = {
        let label = LKLabel(frame: .zero)
        label.outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: [.font: UDFont.title3, .foregroundColor: UIColor.ud.textTitle])
        label.numberOfLines = 1
        label.font = UDFont.title3
        label.backgroundColor = UIColor.clear
        return label
    }()
    /// 竖线
    private lazy var lineView: UIView = {
        let view = UIView(frame: .zero)
        view.frame = CGRect(origin: .zero, size: CGSize(width: 1, height: 14.auto()))
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()
    /// "在 xxx 发布"
    private let tripLabel: LKLabel = {
        let label = LKLabel(frame: .zero)
        label.font = UDFont.body2
        label.numberOfLines = 0
        label.backgroundColor = UIColor.clear
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.avatarView)
        self.addSubview(self.nameLabel)
        self.addSubview(self.lineView)
        self.addSubview(self.tripLabel)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func updateInfo(props: ForwardThreadHeaderProps) {
        // 头像
        let avatarSize = ForwardThreadContentConfig.headerAvatarSize
        self.avatarView.setAvatarByIdentifier(props.senderInfo.entityID, avatarKey: props.senderInfo.key, avatarViewParams: .init(sizeType: .size(avatarSize)))
        self.avatarView.frame = CGRect(origin: CGPoint(x: 0, y: 2), size: CGSize(width: avatarSize, height: avatarSize))

        // 名称，如果多行展示，则名称直接铺满一行
        self.nameLabel.frame.origin = CGPoint(x: self.avatarView.frame.maxX + 6, y: 0)
        self.nameLabel.preferredMaxLayoutWidth = max(0, self.frame.width - avatarSize - 6)
        if props.multiLineModel {
            self.nameLabel.frame.size = CGSize(width: self.frame.size.width - self.nameLabel.frame.origin.x, height: props.nameSize.height)
        } else {
            self.nameLabel.frame.size = props.nameSize
        }
        self.nameLabel.attributedText = props.senderInfo.name

        // 竖线
        self.lineView.isHidden = props.multiLineModel
        // 这里间距本身是6，但是LKLabel算出来末尾会自带一些间距，暂未排查原因，先减少这里的间距为2
        self.lineView.frame.origin = CGPoint(x: self.nameLabel.frame.maxX + 2, y: (self.frame.height - self.lineView.frame.height) / 2)

        // "在 xxx 发布"，如果多行展示，则单独起一行
        self.tripLabel.attributedText = props.tripInfo
        self.tripLabel.preferredMaxLayoutWidth = self.frame.width
        if props.multiLineModel {
            self.tripLabel.frame.origin = CGPoint(x: 0, y: self.nameLabel.frame.maxY + 2)
            self.tripLabel.frame.size = CGSize(width: self.frame.size.width, height: props.tripSize.height)
        } else {
            self.tripLabel.frame.origin = CGPoint(x: self.lineView.frame.maxX + 6, y: (self.frame.height - props.tripSize.height) / 2)
            self.tripLabel.frame.size = props.tripSize
        }
    }
}

final class ForwardThreadHeaderProps: ASComponentProps {
    /// 发帖人信息：头像 + 名称
    var senderInfo: (entityID: String, key: String, name: NSAttributedString) = ("", "", NSAttributedString(string: ""))
    /// 名称占用大小，每次sizeToFit调用后赋值
    var nameSize: CGSize = .zero
    /// "在 xxx 发布"内容
    var tripInfo: NSAttributedString = NSAttributedString(string: "")
    /// "在 xxx 发布"大小，每次sizeToFit调用后赋值
    var tripSize: CGSize = .zero
    /// 是否展示成多行模式："在 xxx 发布"另起一行展示，每次sizeToFit调用后赋值
    var multiLineModel: Bool = false
}

final class ForwardThreadHeaderComponent<C: Context>: ASComponent<ForwardThreadHeaderProps, EmptyState, ForwardThreadHeader, C> {
    public override var isSelfSizing: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    /// 使用NSAttributedString.componentTextSize(...)计算不准确，需要用LKTextLayoutEngineImpl来计算
    private let layoutEngine = LKTextLayoutEngineImpl()
    // attachment也需要经过parser才能参与size计算
    private let textParser = LKTextParserImpl()

    public override func update(view: ForwardThreadHeader) {
        super.update(view: view)
        view.updateInfo(props: self.props)
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        self.layoutEngine.preferMaxWidth = size.width
        // nameSize
        self.textParser.originAttrString = self.props.senderInfo.name
        self.textParser.parse()
        self.layoutEngine.attributedText = self.textParser.renderAttrString
        self.layoutEngine.numberOfLines = 1
        self.props.nameSize = self.layoutEngine.layout(size: size)

        // tripSize
        self.textParser.originAttrString = self.props.tripInfo
        self.textParser.parse()
        self.layoutEngine.attributedText = self.textParser.renderAttrString
        self.layoutEngine.numberOfLines = 0
        self.props.tripSize = self.layoutEngine.layout(size: size)

        let avatarSize = ForwardThreadContentConfig.headerAvatarSize
        // 头部区域优先用一行展示，如果一行能展示下，则直接返回所有的宽度
        let oneLineWidth = avatarSize + 6 + self.props.nameSize.width + 6 + 1 + 6 + self.props.tripSize.width
        if oneLineWidth <= size.width {
            self.props.multiLineModel = false
            return CGSize(width: oneLineWidth, height: self.props.nameSize.height)
        }
        // 如果换行展示，则取「头像 + 名称」和「在 xxx 发布」的最大值，然后和size.width取min
        self.props.multiLineModel = true
        return CGSize(width: min(size.width, max(avatarSize + 6 + self.props.nameSize.width, self.props.tripSize.width)), height: self.props.nameSize.height + 2 + self.props.tripSize.height)
    }
}
