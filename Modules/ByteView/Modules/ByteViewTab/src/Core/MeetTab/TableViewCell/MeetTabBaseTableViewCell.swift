//
//  MeetTabBaseTableViewCell.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import RxSwift
import RxCocoa
import Lottie
import UniverseDesignIcon
import UniverseDesignShadow
import UniverseDesignColor
import RichLabel
import SnapKit
import ByteViewCommon
import ByteViewUI

class CircleIconView: UIView {

    private var size: CGFloat {
        MeetTabTraitCollectionManager.shared.isRegular ? 18.0 : 20.0
    }

    private var backgroundView: UIView = UIView()

    private var iconView: UIImageView?
    private var animationView: LOTAnimationView?

    private var icon: UDIconType = .errorFilled
    private var iconColor: UIColor = .ud.primaryOnPrimaryFill
    private var iconColorHighlighted: UIColor = .ud.primaryOnPrimaryFill
    private var backgroundViewColor: UIColor?
    private var backgroundViewColorHighlighted: UIColor?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundView.clipsToBounds = true

        addSubview(backgroundView)

        backgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override var isHidden: Bool {
        get {
            super.isHidden
        }
        set {
            super.isHidden = newValue
            if newValue {
                animationView?.stop()
            } else {
                animationView?.play()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        DispatchQueue.main.async {
            self.backgroundView.layer.cornerRadius = self.bounds.width / 2
        }
    }

    func config(icon: UDIconType,
                iconColor: UIColor,
                iconColorHighlighted: UIColor? = nil,
                backgroundViewColor: UIColor?,
                backgroundViewColorHighlighted: UIColor?) {
        resetIconView()

        self.icon = icon
        self.iconColor = iconColor
        self.iconColorHighlighted = iconColorHighlighted ?? iconColor
        self.backgroundViewColor = backgroundViewColor
        self.backgroundViewColorHighlighted = backgroundViewColorHighlighted

        let iconView = UIImageView()
        backgroundView.addSubview(iconView)
        self.iconView = iconView
        self.updateLayout()
    }

    func config(animationPath: String,
                backgroundViewColor: UIColor?,
                backgroundViewColorHighlighted: UIColor?) {
        resetIconView()

        self.backgroundViewColor = backgroundViewColor
        self.backgroundViewColorHighlighted = backgroundViewColorHighlighted

        let animationView = LOTAnimationView(filePath: animationPath)
        animationView.loopAnimation = true
        animationView.autoReverseAnimation = false
        animationView.contentMode = .scaleAspectFit
        backgroundView.addSubview(animationView)
        animationView.play()
        self.animationView = animationView
        self.updateLayout()
    }

    func updateLayout() {
        iconView?.snp.remakeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(size)
        }
        animationView?.snp.remakeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(size)
        }
    }

    func resetIconView() {
        iconView?.removeFromSuperview()
        animationView?.removeFromSuperview()
    }

    func setHighlighted(_ isHighlighted: Bool) {
        iconView?.image = UDIcon.getIconByKey(icon, iconColor: isHighlighted ? iconColorHighlighted : iconColor, size: CGSize(width: size, height: size))
        backgroundView.backgroundColor = isHighlighted ? backgroundViewColorHighlighted : backgroundViewColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol MeetTabBaseTableViewCellDelegate: AnyObject {
    func reloadWholeView()
}

class MeetTabBaseTableViewCell: UITableViewCell, MeetTabCellConfigurable {

    weak var delegate: MeetTabBaseTableViewCellDelegate?

    var disposeBag = DisposeBag()

    lazy var paddingView: UIView = {
        let paddingView = UIView()
        paddingView.addInteraction(type: .overlayHover(prefersScaledContent: false))
        paddingView.clipsToBounds = true
        paddingView.layer.cornerRadius = 6
        return paddingView
    }()
    lazy var paddingContainerView: UIView = {
        let paddingView = UIView()
        paddingView.clipsToBounds = true
        paddingView.backgroundColor = .ud.bgBody
        return paddingView
    }()

    lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [iconView, containerView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 12
        return stackView
    }()

    lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        return containerView
    }()

    lazy var titleStackView: UIStackView = {
        let titleStackView = UIStackView(arrangedSubviews: [topicLabel, callCountLabel, tagStackView])
        titleStackView.spacing = 6
        titleStackView.axis = .horizontal
        return titleStackView
    }()

    lazy var tagStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [webinarLabel, externalLabel])
        stackView.spacing = 6
        stackView.axis = .horizontal
        return stackView
    }()

    func configTitle(topic: NSAttributedString, callCount: NSAttributedString?, tagType: MeetingTagType, webinarMeeting: Bool) {
        meetingTagType = tagType
        isWebinarMeeting = webinarMeeting

        topicLabel.attributedText = topic
        callCountLabel.isHidden = (callCount == nil)
        webinarLabel.isHidden = !isWebinarMeeting
        externalLabel.isHidden = !meetingTagType.hasTag
        if let tagText = meetingTagType.text {
            externalLabel.attributedText = .init(string: tagText, config: .assist, alignment: .center, lineBreakMode: .byWordWrapping)
        }

        if let callCount = callCount {
            callCountLabel.attributedText = callCount
        }

        if isWebinarMeeting || meetingTagType.hasTag {
            tagStackView.isHidden = false
        } else {
            tagStackView.isHidden = true
        }
    }

    var descStackViewTopConstaint: Constraint?
    lazy var descStackView: LineSeparatedStackView = {
        let stackView = LineSeparatedStackView(separatedSubviews: [timeLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()

    /// 文案过长时使用
    lazy var extStackView: LineSeparatedStackView = {
        let stackView = LineSeparatedStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.isHidden = true
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        return stackView
    }()

    lazy var iconView = CircleIconView()

    lazy var topicParagraphStyle: NSParagraphStyle = {
        let lineHeight: CGFloat = 22
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        return style
    }()


    lazy var topicLabel: UILabel = {
        let topicLabel = UILabel(frame: CGRect.zero)
        topicLabel.backgroundColor = .clear
        topicLabel.font = .systemFont(ofSize: 16)
        topicLabel.numberOfLines = 1
        topicLabel.lineBreakMode = .byTruncatingTail
        topicLabel.setContentHuggingPriority(UILayoutPriority(1000), for: .horizontal)
        topicLabel.setContentCompressionResistancePriority(UILayoutPriority(748), for: .horizontal)
        topicLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        return topicLabel
    }()

    lazy var callCountLabel: UILabel = {
        let callCountLabel = UILabel(frame: CGRect.zero)
        callCountLabel.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        callCountLabel.setContentCompressionResistancePriority(UILayoutPriority(750), for: .horizontal)
        callCountLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        return callCountLabel
    }()

    lazy var externalLabel: UILabel = {
        let externalLabel = PaddingLabel()
        externalLabel.textInsets = UIEdgeInsets(top: 0.0,
                                        left: 4.0,
                                        bottom: 0.0,
                                        right: 4.0)
        externalLabel.isHidden = true
        externalLabel.textColor = UIColor.ud.udtokenTagTextSBlue
        externalLabel.attributedText = .init(string: I18n.View_G_ExternalLabel, config: .assist, alignment: .center)
        externalLabel.layer.cornerRadius = 4.0
        externalLabel.layer.masksToBounds = true
        externalLabel.backgroundColor = UIColor.ud.udtokenTagBgBlue
        externalLabel.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        externalLabel.setContentCompressionResistancePriority(UILayoutPriority(750), for: .horizontal)
        externalLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        return externalLabel
    }()

    lazy var webinarLabel: UILabel = {
        let webinarLabel = PaddingLabel()
        webinarLabel.textInsets = UIEdgeInsets(top: 0.0,
                                        left: 4.0,
                                        bottom: 0.0,
                                        right: 4.0)
        webinarLabel.isHidden = true
        webinarLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        webinarLabel.attributedText = .init(string: I18n.View_G_Webinar, config: .assist, alignment: .center, lineBreakMode: .byWordWrapping, textColor: UIColor.ud.udtokenTagTextSBlue)
        webinarLabel.layer.cornerRadius = 4.0
        webinarLabel.layer.masksToBounds = true
        webinarLabel.backgroundColor = UIColor.ud.udtokenTagBgBlue
        webinarLabel.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        webinarLabel.setContentCompressionResistancePriority(UILayoutPriority(750), for: .horizontal)
        webinarLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        return webinarLabel
    }()

    lazy var timeLabel: UILabel = {
        let timeLabel = UILabel(frame: CGRect.zero)
        timeLabel.setContentHuggingPriority(UILayoutPriority(500.0), for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(UILayoutPriority(750.0), for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        return timeLabel
    }()

    lazy var separatorView: UIView = {
        let view = UIView(frame: .zero)
        view.isHidden = true
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    lazy var leftEdge: UIView = {
        let leftEdge = UIView()
        leftEdge.backgroundColor = .ud.bgContentBase
        return leftEdge
    }()

    lazy var rightEdge: UIView = {
        let rightEdge = UIView()
        rightEdge.backgroundColor = .ud.bgContentBase
        return rightEdge
    }()

    var oldPaddingHidden: Bool?
    var isPressed: Bool = false
    var isWebinarMeeting: Bool = false

    var meetingTagType: MeetingTagType = .none

    var viewModel: MeetTabCellViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .ud.bgContentBase
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(leftEdge)
        contentView.addSubview(rightEdge)
        contentView.addSubview(paddingContainerView)
        paddingContainerView.addSubview(paddingView)

        paddingView.addSubview(contentStackView)
        containerView.addSubview(titleStackView)
        containerView.addSubview(descStackView)
        containerView.addSubview(extStackView)
        paddingContainerView.addSubview(separatorView)

        titleStackView.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview()
            $0.top.equalToSuperview()
            $0.height.greaterThanOrEqualTo(22.0).priority(999)
        }
        descStackView.snp.makeConstraints {
            $0.left.equalTo(titleStackView)
            $0.right.lessThanOrEqualToSuperview()
            descStackViewTopConstaint = $0.top.equalTo(titleStackView.snp.bottom).offset(4.0).priority(.low).constraint
            $0.height.equalTo(20.0).priority(.low)
            $0.bottom.equalTo(extStackView.snp.top)
        }
        extStackView.snp.makeConstraints {
            $0.top.equalTo(descStackView.snp.bottom)
            $0.left.equalTo(descStackView)
            $0.height.lessThanOrEqualTo(descStackView)
            $0.bottom.equalToSuperview()
        }
        separatorView.snp.makeConstraints {
            $0.left.equalTo(titleStackView)
            $0.right.bottom.equalToSuperview()
            $0.top.equalTo(contentStackView.snp.bottom)
            $0.height.equalTo(MeetTabHistoryDataSource.Layout.separatorHeight).priority(.low)
        }
    }

    func updateLayout() {
        let isRegular = MeetTabTraitCollectionManager.shared.isRegular
        if isRegular {
            updateRegularLayout()
        } else {
            updateCompactLayout()
        }
    }

    func updateRegularLayout() {
        let padding = MeetTabHistoryDataSource.Layout.calculatePadding(bounds: bounds)
        setCellLeftRightShadow(leftEdge)
        setCellLeftRightShadow(rightEdge)
        paddingContainerView.snp.remakeConstraints {
            $0.top.equalToSuperview()
            $0.left.right.equalToSuperview().inset(padding)
            $0.bottom.lessThanOrEqualToSuperview()
        }

        paddingView.snp.remakeConstraints {
            $0.top.equalToSuperview()
            $0.left.right.equalToSuperview().inset(8)
            $0.bottom.lessThanOrEqualToSuperview()
        }

        leftEdge.snp.makeConstraints {
            $0.top.bottom.equalTo(paddingContainerView)
            $0.left.equalTo(paddingContainerView)
            $0.width.equalTo(1)
        }
        rightEdge.snp.makeConstraints {
            $0.top.bottom.equalTo(paddingContainerView)
            $0.right.equalTo(paddingContainerView)
            $0.width.equalTo(1)
        }

        contentStackView.snp.remakeConstraints {
            $0.left.right.equalToSuperview().inset(12.0)
            $0.top.equalToSuperview()
            $0.bottom.equalTo(containerView.snp.bottom).offset(12)
        }

        containerView.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.bottom.equalTo(extStackView.snp.bottom)
        }
        descStackViewTopConstaint?.update(offset: 2.0)
        descStackView.snp.updateConstraints {
            $0.height.equalTo(18).priority(.low)
        }
        iconView.snp.remakeConstraints {
            $0.width.height.equalTo(40.0).priority(.required)
            $0.centerY.equalToSuperview()
        }
    }

    func updateCompactLayout() {
        paddingContainerView.snp.remakeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
        }

        paddingView.snp.remakeConstraints {
            $0.top.equalToSuperview().inset(1)
            if Util.isIpadFullScreen, !MeetTabTraitCollectionManager.shared.isRegular {
                $0.left.right.equalToSuperview().inset(22)
            } else {
                $0.left.right.equalToSuperview().inset(6)
            }
            $0.bottom.lessThanOrEqualToSuperview().inset(1)
        }

        contentStackView.snp.remakeConstraints {
            $0.left.right.equalToSuperview().inset(10.0)
            $0.top.bottom.equalToSuperview()
        }
        containerView.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview().inset(10.0)
        }
        iconView.snp.remakeConstraints {
            $0.width.height.equalTo(48.0).priority(.required)
            $0.centerY.equalToSuperview()
        }
    }

    func showSeparator(_ isShown: Bool) {
        separatorView.isHidden = !isShown
    }

    func bindTo(viewModel: MeetTabCellViewModel) {}

    func reloadStackViews(tableWidth: CGFloat?) {}

    var paddingHighlightedColor: UIColor {
        return .ud.fillHover.withAlphaComponent(0.08)
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        paddingView.backgroundColor = highlighted ? paddingHighlightedColor : .ud.bgBody
        if highlighted {
            isPressed = true
            oldPaddingHidden = separatorView.isHidden
            separatorView.isHidden = true
        } else {
            if isPressed, let oldPaddingHidden = oldPaddingHidden {
                isPressed = false
                separatorView.isHidden = oldPaddingHidden
            }
        }
        iconView.setHighlighted(highlighted)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let convertedPoint = paddingView.convert(point, from: self)
        if paddingView.point(inside: convertedPoint, with: event) {
            return super.hitTest(point, with: event)
        } else {
            return nil
        }
    }

    private func setCellLeftRightShadow(_ view: UIView) {
        let shadowColor = UDColor.getValueByKey(.s2DownColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
        view.layer.ud.setShadowColor(shadowColor)
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowOpacity = 0.25
        view.layer.shadowRadius = 3
        view.layer.shadowPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 1, height: paddingView.bounds.height)).cgPath
    }
}
