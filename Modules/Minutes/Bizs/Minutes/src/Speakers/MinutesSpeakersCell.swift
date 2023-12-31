//
//  MinutesSpeakersCell.swift
//  
//
//  Created by ByteDance on 2023/8/29.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import MinutesNetwork
import MinutesFoundation
import YYText

final class MinutesSpeakerInfoView: UIView {
    let backgroundView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
        backgroundView.layer.cornerRadius = MinutesSpeakerSlider.Layout.sliderHeight / 2.0
        backgroundView.layer.masksToBounds = true
        backgroundView.snp.makeConstraints { make in
            make.left.right.centerY.equalToSuperview()
            make.height.equalTo(MinutesSpeakerSlider.Layout.sliderHeight)
        }

        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(gesture)
    }

    var showSpeakerDetail: (() -> Void)?

    @objc func handleTap() {
        showSpeakerDetail?()
    }

    var totalLength: Int = 0
    var timeline: [(startTime: Int, stopTime: Int)] = []

    var rangesViews: [MinutesSpeakerSlider] = []
    var updateProgress: ((_ timelineIdx: Int,_ progress: CGFloat, _ finished: Bool, _ tProgress: CGFloat, _ playTime: CGFloat, _ width: CGFloat) -> Void)?
    var panBegan: ((_ idx: Int) -> Void)?

    func configure(with info: MinutesSpeakerTimelineInfo) {
        rangesViews.forEach { $0.removeFromSuperview() }
        rangesViews.removeAll()

        self.totalLength = info.videoDuration
        self.timeline = info.speakerTimeline

        for (idx, t) in timeline.enumerated() {
            let rangeView = MinutesSpeakerSlider()
            if idx == info.thumbInfo?.index {
                rangeView.thumbViewHidden = !(info.thumbInfo?.show == true)
                if info.thumbInfo?.show == true {
                    rangeView.setProgress(info.thumbInfo?.progress ?? 0.0)
                } else {
                    rangeView.setProgress(0)
                }
            } else {
                rangeView.thumbViewHidden = true
                rangeView.setProgress(0)
            }
            rangeView.timeline = t
            rangeView.seekingToProgress = { [weak self, weak rangeView] (_ progress: CGFloat, _ finished: Bool, _ location: CGFloat) in
                guard let self = self, let rView = rangeView else { return }
                let play = CGFloat(t.startTime) + CGFloat(t.stopTime - t.startTime) * progress
                let width = rView.bounds.width
                self.updateProgress?(idx, progress, finished, (location + rView.frame.minX) / self.bounds.size.width, play, width)

                for other in self.rangesViews where other != rView {
                    other.thumbViewHidden = true
                }
            }
            rangeView.panBegan = { [weak self] in
                self?.panBegan?(idx)
            }

            rangeView.setProgressColor(info.color)
            addSubview(rangeView)
            rangesViews.append(rangeView)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.size.height / 2.0

        var newTimeline: [(startTime: Int, stopTime: Int)] = []
        for (idx, (start, stop)) in timeline.enumerated() {
            let length: CGFloat = CGFloat(stop - start)
            var width: CGFloat = bounds.size.width * length / CGFloat(totalLength)
            width = max(width, MinutesSpeakerSlider.Layout.thumbViewWidth)
            var left: CGFloat = bounds.size.width * CGFloat(start) / CGFloat(totalLength)
            let subview = rangesViews[idx]
            // 右侧时间轴宽度小于 22，补齐宽度为 22，超出部分左移，实际上不太需要，因为model层已经计算好了保证不会超出
            if left + width > bounds.size.width {
                width = 22
                left = bounds.size.width - width
            }
            subview.frame = CGRect(x: left, y: 0, width: width, height: bounds.size.height)
            subview.boldBackgroundColor = !subview.thumbViewHidden
            subview.timeline = (start, stop)
            newTimeline.append((start, stop))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MinutesSpeakersCell: UITableViewCell {
    var summaryHeight: CGFloat = 0.0
    var didTextTappedBlock: ((Phrase?) -> Void)?

    private lazy var speakerIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 12
        imageView.layer.masksToBounds = true
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(tappedAvatar(_:)))
        tap.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tap)
        return imageView
    }()

    private lazy var dictBorder: YYTextBorder = {
        let border = YYTextBorder()
        border.cornerRadius = 6
        border.fillColor = .clear
        border.bottomLineStrokeColor = UIColor.ud.N400
        border.bottomLineStrokeWidth = 1.0
        border.bottomLineType = .dottedLine
        return border
    }()
    
    var openProfileBlock: ((String?) -> Void)?
    var menuOriginalBlock: (() -> Void)?

    @objc func tappedAvatar(_ sender: UITapGestureRecognizer) {
        if info?.participant.userType == .lark {
            openProfileBlock?(info?.participant.userID)
        }
    }

    private lazy var speakerSubIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        imageView.isHidden = true
        
        imageView.layer.borderColor = UIColor.ud.staticWhite.cgColor
        imageView.layer.borderWidth = 1.0
        imageView.layer.cornerRadius = 6
        return imageView
    }()

    private lazy var speakerNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var percentLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    lazy var summaryLabel: YYTextView = {
        let textView = YYTextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.textContainerInset = .zero
        textView.allowSelectionDot = false
        textView.allowShowMagnifierCaret = false
        textView.allowsCopyAttributedString = false
        textView.textTapEndAction = { [weak self] (containerView, text, range, rect) in
            let filter = self?.info?.dPhrases.first(where: {$0.range.intersection(range) != nil })
            self?.didTextTappedBlock?(filter)
        }
        textView.selectionViewBackgroundColor = UIColor.clear
        return textView
    }()

    var updateProgress: ((_ timelineIdx: Int,_ progress: CGFloat, _ finished: Bool, _ tProgress: CGFloat, _ playTime: CGFloat, _ width: CGFloat) -> Void)?
    var panBegan: ((_ idx: Int) -> Void)?

    var showSpeakerDetail: (() -> Void)?

    private lazy var speakerInfoView: MinutesSpeakerInfoView = {
        let speakerInfoView = MinutesSpeakerInfoView()
        speakerInfoView.updateProgress = { [weak self] (idx, progress, finished, tProgress, playTime, width) in
            self?.updateProgress?(idx, progress, finished, tProgress, playTime, width)
        }
        speakerInfoView.panBegan = { [weak self] (idx) in
            self?.panBegan?(idx)
        }
        speakerInfoView.showSpeakerDetail = { [weak self] in
            self?.showSpeakerDetail?()
        }
        return speakerInfoView
    }()

    var isFold: Bool = true {
        didSet {
            summaryLabel.attributedText = isFold ? nil : summaryLabel.attributedText
            summaryLabel.snp.remakeConstraints { make in
                make.top.equalTo(speakerInfoView.snp.bottom)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(isFold ? 0 : summaryHeight)
                make.bottom.equalToSuperview().offset(isFold ? 0 : -6)
            }
            summaryLabel.isHidden = isFold
        }
    }

    func setInfo(_ info: MinutesSpeakerTimelineInfo?, width: CGFloat) {
        self.info = info
        summaryHeight = 0
        guard let info = info else { return }
        speakerIcon.setAvatarImage(with: info.participant.avatarURL)
        if let room = info.participant.roomInfo, let url = URL(string: room.avatarUrl) {
            speakerSubIcon.isHidden = false
            speakerSubIcon.setAvatarImage(with: url)
        } else {
            speakerSubIcon.isHidden = true
        }
        speakerNameLabel.text = info.participant.userName
        let percent = String(format: "%.0f", info.percent)
        percentLabel.text = "\(percent)%"
        speakerInfoView.configure(with: info)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 22
        paragraphStyle.minimumLineHeight = 22

        var content = info.content ?? ""
        if info.summaryStatus == .complete, info.content.isEmpty == true {
            content = BundleI18n.Minutes.MMWeb_G_NoSummaryDidntSpeakMuch_Desc
        }

        let text = NSMutableAttributedString(string: content,
                                  attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .regular),
                                               .foregroundColor: UIColor.ud.textCaption,
                                               .paragraphStyle: paragraphStyle])
        summaryLabel.attributedText = text

        if let text = summaryLabel.attributedText {
            let size = CGSize(width: width - 32, height: CGFloat.greatestFiniteMagnitude)
            let container = YYTextContainer(size: size, insets: .zero)
            let layout = YYTextLayout(container: container, text: text)
            summaryHeight = layout?.textBoundingSize.height ?? 0.0
            summaryLabel.snp.remakeConstraints { make in
                make.top.equalTo(speakerInfoView.snp.bottom)
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.height.equalTo(summaryHeight)
                make.bottom.equalToSuperview().offset(-6)
            }
            speakerNameLabel.text = info.participant.userName
            let percent = String(format: "%.0f", info.percent)
            percentLabel.text = "\(percent)%"
            speakerInfoView.configure(with: info)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.maximumLineHeight = 22
            paragraphStyle.minimumLineHeight = 22

            let content = info.content ?? ""
            let text = NSAttributedString(string: content,
                                      attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .regular),
                                                   .foregroundColor: UIColor.ud.textCaption,
                                                   .paragraphStyle: paragraphStyle])
            summaryLabel.attributedText = text
            if info.isInTranslateMode && info.summaryStatus == .complete && info.isContentEmpty == false {
                summaryLabel.allowLongPressSelectionAlwaysAll = true
                summaryLabel.customMenu = translateMenu()
            } else {
                summaryLabel.allowLongPressSelectionAlwaysAll = false
            }
        }
        summaryLabel.removeMySelectionRects()

        if info.isInTranslateMode == false {
            info.dPhrases.forEach { (phrase) in
                self.summaryLabel.setMySelectionRects(self.dictBorder, range: phrase.range)
            }
        }
    }

    func translateMenu() -> UIMenuController {
        let menuItems = [
            UIMenuItem(title: BundleI18n.Minutes.MMWeb_G_Copy, action: #selector(menuCopy(_:))),
            UIMenuItem(title: BundleI18n.Minutes.MMWeb_G_SeeOriginal, action: #selector(menuSeeOrigin(_:)))]
        let menuController = UIMenuController.shared
        menuController.menuItems = menuItems
        return menuController
    }

    var info: MinutesSpeakerTimelineInfo?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.ud.bgBody
        selectionStyle = .none
        contentView.addSubview(speakerIcon)
        contentView.addSubview(speakerSubIcon)
        contentView.addSubview(speakerNameLabel)
        contentView.addSubview(percentLabel)
        contentView.addSubview(speakerInfoView)
        contentView.addSubview(summaryLabel)

        speakerIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(20)
            make.width.height.equalTo(24)
        }
        speakerSubIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.bottom.equalTo(speakerIcon).offset(2)
            make.width.height.equalTo(12)
        }
        speakerNameLabel.snp.makeConstraints { make in
            make.left.equalTo(speakerIcon.snp.right).offset(8)
            make.right.lessThanOrEqualTo(percentLabel.snp.left).offset(-16)
            make.centerY.equalTo(speakerIcon)
        }
        percentLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(speakerIcon)
        }
        speakerInfoView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(speakerIcon.snp.bottom).offset(1)
            make.height.equalTo(MinutesSpeakerSlider.Layout.thumbViewWidth)
        }
        summaryLabel.snp.makeConstraints { make in
            make.top.equalTo(speakerInfoView.snp.bottom)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-6)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func menuCopy(_ menu: UIMenuController) {
        guard let text = summaryLabel.attributedText?.string else { return }
        Device.pasteboard(token: DeviceToken.pasteboardSummary, text: text)
    }

    @objc func menuSeeOrigin(_ menu: UIMenuController) {
        menuOriginalBlock?()
    }
}

class MinutesSpeakerHeaderView: UIView {
    var text: String? {
        didSet {
            textLabel.text = text
        }
    }

    var foldAction: (() -> Void)?

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.numberOfLines = 1
        textLabel.textColor = .ud.textTitle
        textLabel.font = .systemFont(ofSize: 14)
        textLabel.text = BundleI18n.Minutes.MMWeb_G_ShowSpeakerSummary_Button
        return textLabel
    }()

    lazy var foldButton: UIImageView = {
        let iconView = UIImageView()
        iconView.image = UDIcon.getIconByKey(.downBottomOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 16, height: 16))
        return iconView
    }()

    lazy var feedbackView: MinutesFeedbackView = {
        let view = MinutesFeedbackView(frame: .zero, type: .speakerSummary, likeStatus: .none)
        return view
    }()

    lazy var backgroundButton: ActionControl = {
        let btn = ActionControl(button: ActionButton(type: .custom))
        btn.button.addTarget(self, action: #selector(fold), for: .touchUpInside)
        return btn
    }()

    @objc func fold() {
        foldAction?()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(backgroundButton)
        addSubview(foldButton)
        addSubview(textLabel)
        addSubview(feedbackView)

        foldButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(
            16)
            make.top.equalToSuperview().offset(
            16)
            make.size.equalTo(16)
        }
        feedbackView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(
            17)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(20)
            make.width.equalTo(52)
        }
        textLabel.snp.makeConstraints { make in
            make.left.equalTo(foldButton.snp.right).offset(4)
            make.centerY.equalTo(foldButton)
            make.right.equalTo(feedbackView.snp.left).offset(-16)
        }
        backgroundButton.snp.makeConstraints { make in
            make.left.top.equalTo(foldButton).offset(-3)
            make.bottom.equalTo(foldButton).offset(3)
            make.right.equalTo(textLabel.snp.right).offset(3)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
