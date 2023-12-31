//
//  MeetingFileTableViewCell.swift
//  MeetingDetail
//
//  Created by chenyizhuo on 2021/1/19.
//

import UIKit
import UniverseDesignIcon
import RichLabel
import ByteViewCommon
import ByteViewUI

class MeetingFileTableViewCell: UITableViewCell {

    private lazy var containerView: UIButton = {
        let containerView = UIButton()
        containerView.isExclusiveTouch = true
        containerView.isEnabled = true
        containerView.layer.borderWidth = 1
        containerView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true

        containerView.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .normal)
        containerView.setBackgroundColor(.ud.udtokenBtnSeBgNeutralPressed, for: .highlighted)
        containerView.addTarget(self, action: #selector(didTapContainerButton), for: .touchUpInside)
        return containerView
    }()

    private lazy var icon: UIImageView = UIImageView()

    private lazy var titleLabel: LKLabel = {
        let titleLabel = LKLabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.backgroundColor = .clear
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.isUserInteractionEnabled = false
        return titleLabel
    }()

    private lazy var ownerLabel: UILabel = {
        let ownerLabel = UILabel()
        ownerLabel.textColor = UIColor.ud.textCaption
        ownerLabel.font = UIFont.systemFont(ofSize: 12)
        ownerLabel.isUserInteractionEnabled = false
        return ownerLabel
    }()

    private lazy var forwardButton: UIButton = {
        var forwardButton = VisualButton()
        forwardButton.extendEdge = UIEdgeInsets(top: -23, left: -16, bottom: -23, right: -16)
        forwardButton.addTarget(self, action: #selector(didTapForwardButton), for: .touchUpInside)
        forwardButton.setImage(UDIcon.getIconByKey(.shareOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 20, height: 20)), for: .normal)
        return forwardButton
    }()

    private var guideView: GuideView?

    private lazy var previewView: FilePreviewView = {
        let previewView = FilePreviewView(frame: .zero)
        previewView.iconDimension = 24.0
        previewView.isHidden = true
        return previewView
    }()

    lazy var separatorLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        line.isHidden = true
        return line
    }()

    var tapAction: (() -> Void)?
    var forwardAction: (() -> Void)?
    var collectionAction: (() -> Void)?

    var horizontalOffset: CGFloat = 0

    private lazy var titleParagraphStyle: NSParagraphStyle = {
        let lineHeight: CGFloat = 22
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        return style
    }()

    private lazy var generatingTag: PaddingLabel = {
        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 0.0,
                                        left: 4.0,
                                        bottom: 0.0,
                                        right: 4.0)
        label.backgroundColor = UIColor.ud.udtokenTagBgOrange
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.attributedText = .init(string: I18n.View_G_GeneratingTag, config: .assist, textColor: UIColor.ud.udtokenTagTextSOrange)
        label.isHidden = true
        return label
    }()

    private lazy var titleAttribute: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16), .paragraphStyle: titleParagraphStyle, .foregroundColor: UIColor.ud.textTitle]

    private lazy var collectionButton: MinutesCollectionButton = {
        let button = MinutesCollectionButton()
        button.addTarget(self, action: #selector(didTapCollectionButton), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private lazy var bgView: UIButton = {
        let bgView = UIButton()
        bgView.isExclusiveTouch = true
        bgView.isEnabled = true
        bgView.layer.cornerRadius = 6
        bgView.clipsToBounds = true

        bgView.setBackgroundColor(.clear, for: .normal)
        bgView.setBackgroundColor(.ud.fillHover, for: .highlighted)
        bgView.addTarget(self, action: #selector(didTapContainerButton), for: .touchUpInside)
        bgView.isHidden = true
        return bgView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        collectionButton.isHidden = true
    }

    private func setupViews() {

        backgroundColor = UIColor.ud.bgFloat
        selectedBackgroundView?.backgroundColor = .clear

        contentView.addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(8)
        }

        contentView.addSubview(containerView)

        containerView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(12)
            make.bottom.equalToSuperview()
        }

        contentView.addSubview(collectionButton)
        collectionButton.snp.makeConstraints { make in
            make.left.equalTo(containerView)
            make.right.lessThanOrEqualTo(containerView)
            make.bottom.equalTo(-6)
            make.height.equalTo(28)
        }

        contentView.addSubview(separatorLine)
        separatorLine.snp.makeConstraints { make in
            make.left.equalTo(128)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        containerView.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview().inset(16)
            make.width.equalTo(32)
            make.height.equalTo(32).priority(999)
        }

        icon.addSubview(previewView)
        previewView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.addSubview(forwardButton)
        forwardButton.snp.makeConstraints { make in
            make.right.centerY.equalTo(containerView)
            make.width.height.equalTo(20)
        }

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.isUserInteractionEnabled = false
        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.equalTo(icon.snp.right).offset(12)
            make.right.equalTo(-36)
            make.centerY.equalToSuperview()
        }

        let titleStackContainer = UIView()
        let titleStackView = UIStackView()
        titleStackView.axis = .horizontal
        titleStackView.spacing = 4
        titleStackView.alignment = .center
        titleStackView.distribution = .equalSpacing
        titleStackContainer.addSubview(titleStackView)
        titleStackView.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview()
        }
        stackView.addArrangedSubview(titleStackContainer)
        titleStackView.isUserInteractionEnabled = false

        titleStackView.addArrangedSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(22)
        }

        titleStackView.addArrangedSubview(generatingTag)

        stackView.addArrangedSubview(ownerLabel)
        ownerLabel.snp.makeConstraints { (make) in
            make.height.equalTo(18)
        }
    }

    func configRecordingCellStyle(with model: MeetingDetailFile, accessToken: String) {
        previewView.isHidden = !model.isRecordingFile
        previewView.previewIconView.image = nil
        previewView.showShadow = false
        previewView.showBadge = model.isMinutes
        previewView.previewBadgeView.text = "\(model.breakoutMinutesCount)"
        previewView.previewBadgeView.showLabel = model.isMinutesCollection
        previewView.previewBadgeView.iconView.image = UDIcon.getIconByKey(.tabMinutesColorful, iconColor: UIColor.ud.staticWhite)
        icon.image = nil
        collectionButton.isHidden = !model.isMinutesCollection
        if model.isMinutes {
            if model.isActive, !model.isLocked, let coverUrl = model.coverUrl {
                let image = BundleResources.ByteViewTab.MinutesPreview.BG.Generating
                previewView.vc.setImage(url: coverUrl, accessToken: accessToken, placeholder: image)
            } else {
                previewView.showShadow = true
                previewView.image = BundleResources.ByteViewTab.MinutesPreview.BG.Generating
                if model.isLocked {
                    previewView.previewIconView.image = UDIcon.getIconByKey(.lockOutlined, iconColor: UIColor.ud.staticWhite)
                } else if !model.isActive {
                    previewView.previewIconView.image = UDIcon.getIconByKey(.timeOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill)
                }
            }
        } else { // record
            previewView.image = BundleResources.ByteViewTab.MinutesPreview.BG.Video
            if model.isActive {
                previewView.previewIconView.image = BundleResources.ByteViewTab.MinutesPreview.fileVideoColorful
            } else {
                previewView.previewIconView.image = UDIcon.getIconByKey(.timeOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill)
            }
        }

        containerView.setBackgroundColor(.clear, for: .highlighted)
        containerView.layer.borderWidth = 0
        let bottomOffset = model.isMinutesCollection ? -30 : 0
        containerView.snp.remakeConstraints {
            $0.top.equalToSuperview()
            $0.left.right.equalToSuperview().inset(horizontalOffset)
            $0.bottom.equalTo(bottomOffset)
        }

        icon.snp.remakeConstraints {
            $0.left.centerY.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(6).priority(999)
            $0.width.equalTo(100)
            $0.height.equalTo(56)
        }
    }

    func config(with model: MeetingDetailFile, viewModel: MeetTabViewModel) {
        selectionStyle = .none
        if model.isRecordingFile {
            configRecordingCellStyle(with: model, accessToken: viewModel.account.accessToken)
            titleLabel.textColor = UIColor.ud.textTitle
            titleLabel.text = model.title
        } else {
            icon.image = model.icon
            if let docsIconDependency = model.docsIconDependency, let url = model.url {
                docsIconDependency.getDocsIconImageAsync(url: url) { image in
                    DispatchQueue.main.async {
                        self.icon.image = image
                    }
                }
            }
            icon.alpha = model.isActive ? 1.0 : 0.5
            titleLabel.textColor = model.isActive ? UIColor.ud.textTitle : UIColor.ud.textDisabled
            titleLabel.text = model.title.isEmpty == false ? model.title : I18n.View_VM_UntitledDocument
        }
        generatingTag.isHidden = model.isActive
        titleLabel.outOfRangeText = NSAttributedString(string: "\u{2026}", attributes: titleAttribute)
        ownerLabel.isHidden = model.desc == nil
        ownerLabel.textColor = model.isActive ? UIColor.ud.textCaption : UIColor.ud.textDisabled
        model.desc? { [weak self] desc in
            self?.ownerLabel.isHidden = desc.isEmpty
            self?.ownerLabel.text = desc
        }
        if model.canForward && model.isActive && model.isMinutes {
            forwardButton.isHidden = false
            if model.shouldShowOnboarding {
                DispatchQueue.main.async {
                    self.showMinutesOnboardingIfNeeded(refView: self.forwardButton, viewModel: viewModel)
                }
            }
        } else {
            forwardButton.isHidden = true
        }
    }

    func configCollectionMinutes(with model: MeetingDetailFile, viewModel: MinutesCollcetionViewModel) {
        horizontalOffset = 16
        config(with: model, viewModel: viewModel.meetingDetail.tabViewModel)
        let isShowDuration = model.isActive && !model.isLocked
        previewView.showBadge = !isShowDuration
        previewView.durationLabel.isHidden = !isShowDuration
        previewView.durationLabel.text = formattedDuration(Int(model.minutesDuration / 1000))
        containerView.isEnabled = false
        containerView.setBackgroundColor(.clear, for: .normal)
        containerView.setBackgroundColor(.clear, for: .highlighted)
        bgView.isHidden = false
    }

    private func formattedDuration(_ duration: Int) -> String {
        let hours: Int = duration / 3600
        let hoursString: String = hours > 9 ? "\(hours)" : "0\(hours)"

        let minutes = duration % 3600 / 60
        let minutesString = minutes > 9 ? "\(minutes)" : "0\(minutes)"

        let seconds = duration % 3600 % 60
        let secondsString = seconds > 9 ? "\(seconds)" : "0\(seconds)"

        if hours == 0 {
            return "\(minutesString):\(secondsString)"
        } else {
            return "\(hoursString):\(minutesString):\(secondsString)"
        }
    }

    @objc
    private func didTapContainerButton() {
        tapAction?()
    }

    @objc
    private func didTapForwardButton() {
        forwardAction?()
    }

    @objc
    private func didTapCollectionButton() {
        collectionAction?()
    }
}

extension MeetingFileTableViewCell {
    func showMinutesOnboardingIfNeeded(refView: UIView, viewModel: MeetTabViewModel) {
        //  判断是否展示onboarding
        guard viewModel.shouldShowGuide(.clickQuickShareMinute) else {
            return
        }
        guard let view = viewController()?.view else { return }
        let guideView = self.guideView ?? GuideView(frame: view.bounds)
        self.guideView = guideView
        if guideView.superview == nil {
            view.addSubview(guideView)
            guideView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        guideView.setStyle(.plain(content: I18n.View_G_ClickQuickShareMinute_Onboarding),
                           on: .top,
                           of: refView,
                           distance: 8)
        guideView.sureAction = { [weak self, weak viewModel] _ in
            viewModel?.didShowGuide(.clickQuickShareMinute)
            self?.guideView?.removeFromSuperview()
            self?.guideView = nil
        }
    }

    func viewController() -> UIViewController? {
        var responder = self.next
        while responder != nil {
            if responder is UIViewController {
                return responder as? UIViewController
            }
            responder = responder?.next
        }
        return nil
    }
}
