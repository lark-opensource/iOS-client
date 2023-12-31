//
//  FlagMessageCell.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import UIKit
import LarkUIKit
import LarkContainer
import LarkCore
import EENavigator
import LarkMessengerInterface
import ByteWebImage
import LarkBizAvatar
import UniverseDesignIcon
import LKCommonsLogging
import LarkMessageCore

public class FlagMessageCell: BaseFlagListTableCell {

    public enum Cons {
        public static var nameFont: UIFont { UIFont.ud.body0 }
        public static var sourceFont: UIFont { UIFont.ud.body2 }
        public static var timeFont: UIFont { UIFont.ud.caption1 }
        public static var topMargin: CGFloat { 8 }
        public static var bottomMargin: CGFloat { 8 }
        public static var avatarSize: CGFloat { 48 }
        public static var contentInset: CGFloat { 16 }
        public static var avatarRightMargin: CGFloat { 12 }
        public static var contentTopMargin: CGFloat { 10 }
        public static var contentRightMargin: CGFloat { 16 }
        public static var sourceLabelTopMargin: CGFloat { 4 }
        public static var sourceLabelHeight: CGFloat { 20 }
        public static var sourceLabelBottomMargin: CGFloat { 8 }
        public static var sourceLabelRiskTipPadding: CGFloat { 6 }
        public static var contentRiskTipPadding: CGFloat { 4 }
        static let downsampleSize = CGSize(width: Cons.avatarSize, height: Cons.avatarSize)
        public static var contentBottomMargin: CGFloat {
            return sourceLabelTopMargin + sourceLabelHeight + sourceLabelBottomMargin
        }
        public static var textMaxHeight: CGFloat { 240 }
    }

    override class var identifier: String {
        return FlagMessageCellViewModel.identifier
    }

    public let logger = Logger.log("FlagMessageCell")

    public var highlightColor = UIColor.ud.fillHover
    // NOTE: 新定义的业务token色值 imtoken/feed/fill/active，由于feed模块暂未处理业务token，且仅此处使用，所以暂且做特化处理
    public var selectedColor = UIColor.ud.rgb(0x3385FF).withAlphaComponent(0.12)

    public var bubbleContentMaxWidth: CGFloat {
        var width = UIScreen.main.bounds.width
        if Display.pad {
            width = self.frame.width
        }
        return width - 2 * Cons.contentInset - Cons.avatarRightMargin - Cons.avatarSize - Cons.contentRightMargin
    }

    public lazy var flagAvatarView: LarkMedalAvatar = {
        let flagAvatarView = LarkMedalAvatar(frame: .zero)
        flagAvatarView.topBadge.isZoomable = true
        flagAvatarView.bottomBadge.isZoomable = true
        return flagAvatarView
    }()

    public var contentWraper: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()

    private var sourceLabelContainer: FlagMessageSourceView = FlagMessageSourceView(frame: .zero)

    private lazy var flagIcon: UIImageView = {
        let image = UDIcon.getIconByKey(.flagFilled, iconColor: UIColor.ud.colorfulRed, size: CGSize(width: 12, height: 12))
        let imageView = UIImageView(image: image)
        return imageView
    }()

    public var isShowName: Bool = false {
        didSet {
            nameLabel.isHidden = !isShowName
        }
    }

    public lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = Cons.nameFont
        label.textColor = UIColor.ud.textTitle
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .left
        return label
    }()

    private lazy var maskShadowLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.locations = [0, 1]
        layer.startPoint = CGPoint(x: 0.0, y: 0.0)
        layer.endPoint = CGPoint(x: 0.0, y: 1.0)
        return layer
    }()

    public lazy var riskTip: UIView = {
        let view = FileNotSafeTipView()
        view.isHidden = true
        return view
    }()

    lazy var bottomMaskView: UIView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public func setupUI() {
        // 禁用Cell自带选中态/高亮: Cell自带选中态/高亮的会使subView的背景色都置为clear
        selectionStyle = .none
        setupBackgroundViews(highlightOn: true)
        self.backgroundColor = UIColor.ud.bgBody
        self.swipeView.backgroundColor = .clear
        self.swipeView.addSubview(self.contentWraper)
        self.swipeView.addSubview(self.flagAvatarView)
        self.swipeView.addSubview(self.sourceLabelContainer)
        self.swipeView.addSubview(self.riskTip)
        self.contentWraper.addSubview(self.flagIcon)
        self.contentWraper.addSubview(self.nameLabel)
        self.contentWraper.addSubview(bottomMaskView)
        bottomMaskView.layer.addSublayer(maskShadowLayer)
        bottomMaskView.isHidden = true

        self.swipeView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalToSuperview()
        }
        self.contentWraper.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Cons.contentTopMargin)
            make.right.equalToSuperview().offset(-Cons.contentInset)
        }

        self.flagAvatarView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Cons.contentInset)
            make.top.equalToSuperview().offset(Cons.topMargin)
            make.right.equalTo(self.contentWraper.snp.left).offset(-Cons.avatarRightMargin)
            make.width.height.equalTo(Cons.avatarSize)
            make.bottom.lessThanOrEqualToSuperview().offset(-Cons.bottomMargin)
        }

        self.riskTip.snp.makeConstraints { make in
            make.top.equalTo(self.contentWraper.snp.bottom).offset(Cons.contentRiskTipPadding)
            make.left.right.equalTo(self.contentWraper)
        }

        self.sourceLabelContainer.snp.makeConstraints { make in
            make.top.equalTo(self.contentWraper.snp.bottom).offset(Cons.sourceLabelTopMargin)
            make.left.right.equalTo(self.contentWraper)
            make.height.equalTo(Cons.sourceLabelHeight)
        }

        self.swipeView.snp.makeConstraints { make in
            make.bottom.equalTo(self.sourceLabelContainer.snp.bottom).offset(Cons.sourceLabelBottomMargin)
        }

        bottomMaskView.snp.makeConstraints { make in
            make.left.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(16)
        }

        self.flagIcon.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(2)
            make.right.equalToSuperview()
        }

        self.nameLabel.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(22)
        }

        self.nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    open override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if !Display.pad {
            // iPad 上 cell 有 Drag 能力，关掉 highlighted
            self.setBackViewColor(backgroundColor(highlighted))
        }
    }

    open override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if Display.pad {
            // iPad 上 cell 有选中状态
            self.setBackViewColor(backgroundColor(selected))
        }
    }

    public func backgroundColor(_ highlighted: Bool) -> UIColor {
        var backgroundColor = UIColor.ud.fillHover
        let needShowSelected = self.viewModel.selected

        if Display.pad && needShowSelected {
            backgroundColor = self.selectedColor
        } else {
            backgroundColor = highlighted ? self.highlightColor : UIColor.ud.bgBody
        }
        return backgroundColor
    }

    // 标记这个cell被选中了
    public func markForSelect() {
        guard Display.pad, let flagMessageVM = self.viewModel as? FlagMessageCellViewModel else { return }
        let uniqueId = "message_" + flagMessageVM.message.id
        self.viewModel.dataDependency.setSelected(flagId: uniqueId)
    }

    override public func updateCellContent() {
        super.updateCellContent()
        guard let flagMessageVM = viewModel as? FlagMessageCellViewModel else { return }
        self.nameLabel.text = "\(flagMessageVM.fromChatterDisplayName)："
        self.updateAvatar(flagMessageVM: flagMessageVM)
        self.updateSource(flagMessageVM: flagMessageVM)
        if sourceLabelContainer.superview != nil, riskTip.superview != nil {
            self.updateRiskState()
        }
    }

    private func updateRiskState() {
        if viewModel.isRisk {
            self.sourceLabelContainer.snp.remakeConstraints { make in
                make.top.equalTo(self.riskTip.snp.bottom).offset(Cons.sourceLabelRiskTipPadding)
                make.left.right.equalTo(self.contentWraper)
                make.height.equalTo(Cons.sourceLabelHeight)
            }
            self.riskTip.isHidden = false
        } else {
            self.sourceLabelContainer.snp.remakeConstraints { make in
                make.top.equalTo(self.contentWraper.snp.bottom).offset(Cons.sourceLabelTopMargin)
                make.left.right.equalTo(self.contentWraper)
                make.height.equalTo(Cons.sourceLabelHeight)
            }
            self.riskTip.isHidden = true
        }
    }

    private func updateAvatar(flagMessageVM: FlagMessageCellViewModel) {
        let messageId = flagMessageVM.message.id
        let fromChatter = flagMessageVM.fromChatter
        let chatterAvatarKey = flagMessageVM.message.fromChatter?.avatarKey
        guard !messageId.isEmpty, let avatarKey = chatterAvatarKey, !avatarKey.isEmpty, let identifier = fromChatter?.id else {
            flagAvatarView.image = nil
            return
        }
        flagAvatarView.setAvatarByIdentifier(identifier,
                                             avatarKey: avatarKey,
                                             medalKey: flagMessageVM.message.fromChatter?.medalKey ?? "",
                                             medalFsUnit: "",
                                             scene: .Feed,
                                             options: [.downsampleSize(Cons.downsampleSize)],
                                             backgroundColorWhenError: .clear)
    }

    private func updateSource(flagMessageVM: FlagMessageCellViewModel) {
        sourceLabelContainer.updateSourceLabel(teamName: "", sourceName: flagMessageVM.source)
    }

    func willDisplay() {}
    func didEndDisplay() {}

    public override func layoutSubviews() {
        super.layoutSubviews()
        maskShadowLayer.colors = [UIColor.ud.bgBody.withAlphaComponent(0).cgColor, UIColor.ud.bgBody.withAlphaComponent(1).cgColor]
        maskShadowLayer.frame = bottomMaskView.bounds
        bottomMaskView.isHidden = self.frame.height < Cons.textMaxHeight
        contentWraper.bringSubviewToFront(bottomMaskView)
    }
}

class FlagMessageSourceView: UIView {

    public lazy var sourceLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = FlagMessageCell.Cons.sourceFont
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .left
        return label
    }()

    public lazy var sourceTeamLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = FlagMessageCell.Cons.sourceFont
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .left
        return label
    }()

    public lazy var rightArrowIcon: UIImageView = {
        let image = UDIcon.getIconByKey(.rightOutlined, iconColor: UIColor.ud.textPlaceholder, size: CGSize(width: 10, height: 10))
        let imageView = UIImageView(image: image)
        return imageView
    }()

    public lazy var sourceGroupLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = FlagMessageCell.Cons.sourceFont
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .left
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(sourceLabel)
        addSubview(sourceTeamLabel)
        addSubview(rightArrowIcon)
        addSubview(sourceGroupLabel)
        sourceLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        sourceTeamLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(0)
        }
        rightArrowIcon.snp.makeConstraints { make in
            make.left.equalTo(sourceTeamLabel.snp.right).offset(4)
            make.width.height.equalTo(10)
            make.centerY.equalToSuperview()
        }
        sourceGroupLabel.snp.makeConstraints { make in
            make.left.equalTo(rightArrowIcon.snp.right).offset(4)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(0)
            make.right.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var teamTextWidth = 0.0
    private var groupTextWidth = 0.0
    private var contentWidth = 0.0
    private var showTeamName = false

    func updateSourceLabel(teamName: String, sourceName: String) {
        showTeamName = !teamName.isEmpty
        sourceLabel.isHidden = showTeamName
        sourceTeamLabel.isHidden = !showTeamName
        rightArrowIcon.isHidden = !showTeamName
        sourceGroupLabel.isHidden = !showTeamName
        if teamName.isEmpty {
            sourceLabel.text = sourceName
            return
        }
        sourceTeamLabel.text = teamName
        sourceGroupLabel.text = sourceName
        let rect = CGRect(origin: .zero, size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        teamTextWidth = sourceTeamLabel.textRect(forBounds: rect, limitedToNumberOfLines: 1).width
        groupTextWidth = sourceGroupLabel.textRect(forBounds: rect, limitedToNumberOfLines: 1).width
        contentWidth = 0.0
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if contentWidth != frame.width && showTeamName {
            contentWidth = frame.width
            let totalWidth = contentWidth - 10.0 - 4.0 * 2
            var teamLabelWidth = teamTextWidth
            var groupLabelWidth = groupTextWidth
            if (teamTextWidth + groupTextWidth) > totalWidth {
                teamLabelWidth = teamTextWidth <= totalWidth / 2.0 ? teamTextWidth : max(totalWidth / 2.0, totalWidth - groupTextWidth)
                groupLabelWidth = groupTextWidth <= totalWidth / 2.0 ? groupTextWidth : max(totalWidth / 2.0, totalWidth - teamTextWidth)
            }
            sourceTeamLabel.snp.updateConstraints { make in
                make.width.equalTo(teamLabelWidth)
            }
            sourceGroupLabel.snp.updateConstraints { make in
                make.width.equalTo(groupLabelWidth)
            }
        }
    }

}
