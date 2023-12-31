//
//  VCFeedOngoingMeetingCell.swift
//  ByteViewMessenger
//
//  Created by lutingting on 2022/9/19.
//

import Foundation
import RxSwift
import RxCocoa
import SnapKit
import NSObject_Rx
import UniverseDesignTheme
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignToast
import RichLabel
import ByteViewCommon
import LarkOpenFeed

class VCFeedOngoingMeetingCell: UITableViewCell {
    static let cellIdentifier = String(describing: VCFeedOngoingMeetingCell.self)
    private static let token = "LARK-PSDA-feed_copy_meeting_id"

    lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [iconView, containerView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 10
        return stackView
    }()

    lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        return containerView
    }()

    lazy var titleStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [topicLabel, externalView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 4.0
        return stackView
    }()

    lazy var descStackView: LineSeparatedStackView = {
        let stackView = LineSeparatedStackView(separatedSubviews: [timeLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
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


    lazy var topicLabel: LKLabel = {
        let topicLabel = LKLabel(frame: CGRect.zero)
        topicLabel.backgroundColor = .clear
        topicLabel.font = .systemFont(ofSize: 16)
        topicLabel.numberOfLines = 1
        topicLabel.lineBreakMode = .byWordWrapping
        topicLabel.setContentHuggingPriority(UILayoutPriority(750.0), for: .horizontal)
        topicLabel.setContentCompressionResistancePriority(UILayoutPriority(500.0), for: .horizontal)
        topicLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        return topicLabel
    }()

    lazy var externalView: UILabel = {
        let flagView = UILabel(frame: .zero)
        flagView.isHidden = true
        flagView.textColor = UIColor.ud.udtokenTagTextSBlue
        flagView.attributedText = .init(string: I18n.View_G_ExternalLabel, config: .assist, alignment: .center, lineBreakMode: .byWordWrapping)
        flagView.layer.cornerRadius = 4.0
        flagView.layer.masksToBounds = true
        flagView.backgroundColor = UIColor.ud.udtokenTagBgBlue
        flagView.setContentHuggingPriority(UILayoutPriority(999.0), for: .horizontal)
        flagView.setContentCompressionResistancePriority(UILayoutPriority(999.0), for: .horizontal)
        flagView.setContentCompressionResistancePriority(.required, for: .vertical)
        return flagView
    }()

    lazy var timeLabel: UILabel = {
        let timeLabel = UILabel(frame: CGRect.zero)
        timeLabel.setContentHuggingPriority(UILayoutPriority(500.0), for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(UILayoutPriority(750.0), for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        return timeLabel
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

    private var timerDisposeBag: DisposeBag = DisposeBag()
    private var disposeBag: DisposeBag = DisposeBag()

    lazy var meetingIDLabel: CopyableLabel = {
        let meetingIDLabel = CopyableLabel()
        meetingIDLabel.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        meetingIDLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 500.0), for: .horizontal)
        meetingIDLabel.copyTitle = I18n.View_MV_CopyMeetingID
        meetingIDLabel.completeTitle = I18n.View_MV_MeetingIDCopied
        meetingIDLabel.addInteraction(type: .hover)
        meetingIDLabel.layer.cornerRadius = 2.0
        meetingIDLabel.clipsToBounds = true
        meetingIDLabel.delegate = self
        return meetingIDLabel
    }()

    lazy var joinButton: VisualButton = {
        let joinButton = VisualButton(type: .custom)
        joinButton.layer.borderWidth = 1.0
        joinButton.layer.cornerRadius = 6.0
        joinButton.setBorderColor(.ud.G600, for: .normal)
        joinButton.setBorderColor(.ud.G600, for: .highlighted)
        joinButton.setBorderColor(.ud.lineBorderComponent, for: .disabled)
        joinButton.setBackgroundColor(.ud.G200, for: .highlighted)
        joinButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        joinButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        joinButton.clipsToBounds = true
        joinButton.addInteraction(type: .lift)
        return joinButton
    }()

    var timeLabelWidthConstraint: Constraint?

    var reloadBlock: (() -> Void)?
    var oldPaddingHidden: Bool?
    var isPressed: Bool = false
    var meetingTagType: MeetingTagType = .none {
        didSet {
            guard meetingTagType != oldValue else { return }
            self.updateExternalView()
        }
    }

    var paddingHighlightedColor: UIColor {
        return .ud.fillHover.withAlphaComponent(0.08)
    }

    var topicText: String!

    var viewModel: VCFeedOngoingMeetingCellViewModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(contentStackView)
        containerView.addSubview(titleStackView)
        containerView.addSubview(descStackView)

        titleStackView.snp.makeConstraints {
            $0.left.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview()
            $0.top.equalToSuperview()
            $0.height.equalTo(22.0).priority(999)
        }
        descStackView.snp.makeConstraints {
            $0.left.equalTo(titleStackView)
            $0.right.lessThanOrEqualToSuperview()
            $0.top.equalTo(titleStackView.snp.bottom).offset(4.0)
            $0.height.equalTo(20.0)
            $0.bottom.equalToSuperview()
        }

        var size = externalView.sizeThatFits(.zero)
        size = CGSize(width: size.width + 7, height: size.height)
        externalView.snp.makeConstraints {
            $0.width.equalTo(size.width)
            $0.height.equalTo(size.height).priority(999)
        }

        timeLabel.snp.makeConstraints {
            timeLabelWidthConstraint = $0.width.equalTo(0.0).constraint
        }

        contentStackView.addArrangedSubview(joinButton)
        joinButton.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(60.0)
            $0.height.equalTo(28.0)
        }

        descStackView.addSeparatedSubview(meetingIDLabel)

        iconView.config(icon: .videoFilled,
                        iconColor: UIColor.ud.functionSuccessContentDefault,
                        iconColorHighlighted: UIColor.ud.functionSuccessContentDefault,
                        backgroundViewColor: UIColor.ud.functionSuccessFillSolid02,
                        backgroundViewColorHighlighted: UIColor.ud.functionSuccessFillSolid02)
        iconView.setHighlighted(false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reloadBlock = nil
        viewModel = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        //LKLabel只有属性字符串赋值操作才触发UI刷新，所以text重新赋值一下，刷新LM和DM下的字体颜色
        topicLabel.text = topicText
    }

    func updateLayout() {
        contentStackView.snp.remakeConstraints {
            $0.left.right.equalToSuperview().inset(16.0)
            $0.top.bottom.equalToSuperview().inset(12.0)
        }
        containerView.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview().inset(1)
        }
        iconView.snp.remakeConstraints {
            $0.width.height.equalTo(48.0).priority(.required)
            $0.centerY.equalToSuperview()
        }
    }


    func bindTo(viewModel: EventItem?) {
        guard let viewModel = viewModel as? VCFeedOngoingMeetingCellViewModel else {
            return
        }
        self.viewModel = viewModel
        meetingTagType = viewModel.meetingTagType

        disposeBag = DisposeBag()
        viewModel.meetingTagTypeRelay.asObservable()
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] tagType in
                self?.meetingTagType = tagType
            })
            .disposed(by: disposeBag)

//      同步LM合DM
        if #available(iOS 13.0, *) {
            let correctStyle = UDThemeManager.userInterfaceStyle
            let correctTraitCollection = UITraitCollection(userInterfaceStyle: correctStyle)
            UITraitCollection.current = correctTraitCollection
        }

        topicLabel.textColor = viewModel.topicColor
        let topicAttribute: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16), .paragraphStyle: topicParagraphStyle, .foregroundColor: viewModel.topicColor]
        topicLabel.outOfRangeText = NSAttributedString(string: "\u{2026}", attributes: topicAttribute)

        topicLabel.text = viewModel.topic
        topicText = viewModel.topic
        topicLabel.font = .systemFont(ofSize: 16)
        timerDisposeBag = DisposeBag()
        let config: VCFontConfig = .bodyAssist
        let textColor: UIColor = .ud.textPlaceholder
        viewModel.timingDriver
            .map { .init(string: $0, config: config, textColor: textColor) }
            .drive(timeLabel.rx.attributedText)
            .disposed(by: timerDisposeBag)
        meetingIDLabel.attributedText = .init(string: viewModel.meetingNumber, config: config, textColor: textColor)
        viewModel.timingDriver
            .map { $0.count <= 5 ? 40.0 : 62.0 }
            .distinctUntilChanged()
            .drive(onNext: { [weak self] in
                self?.timeLabelWidthConstraint?.update(offset: $0)
            }).disposed(by: timerDisposeBag)
        meetingIDLabel.tapGesture.isEnabled = traitCollection.isRegular
        viewModel.joinButtonTitleDriver.drive(onNext: { [weak self] title in
            self?.joinButton.setAttributedTitle(.init(string: title,
                                                      config: .bodyAssist,
                                                      textColor: .ud.G600), for: .normal)
            self?.joinButton.setAttributedTitle(.init(string: title,
                                                      config: .bodyAssist,
                                                      textColor: .ud.G600), for: .highlighted)
            self?.joinButton.setAttributedTitle(.init(string: title,
                                                      config: .bodyAssist,
                                                      textColor: .ud.textDisabled), for: .disabled)
        }).disposed(by: rx.disposeBag)
        joinButton.rx.action = viewModel.joinAction
    }

    private func updateExternalView() {
        if let tagText = meetingTagType.text {
            externalView.isHidden = false
            externalView.attributedText = .init(string: tagText, config: .assist, alignment: .center, lineBreakMode: .byWordWrapping)

            var size = externalView.sizeThatFits(.zero)
            size = CGSize(width: size.width + 7, height: size.height)
            externalView.snp.remakeConstraints {
                $0.width.equalTo(size.width)
                $0.height.equalTo(size.height).priority(999)
            }
        } else {
            externalView.isHidden = true
        }
    }

    func reloadStackViews(tableWidth: CGFloat?) {}
}

extension VCFeedOngoingMeetingCell: CopyableLabelDelegate {
    func labelTextDidCopied(_ label: CopyableLabel) {
        if ClipboardSncWrapper.set(text: label.text, with: Self.token) {
            let config = UDToastConfig(toastType: .success, text: label.completeTitle, operation: nil)
            if let view = label.window {
                UDToast.showToast(with: config, on: view)
            }
        }
    }
}

extension VCFeedOngoingMeetingCell: EventItemCell {
    var item: EventItem? {
        get {
            viewModel
        }
        set {
            bindTo(viewModel: newValue)
        }
    }
}

fileprivate extension UIButton {
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        vc.setBackgroundColor(color, for: state)
    }
}
