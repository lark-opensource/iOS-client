//
//  MeetingCallsCell.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/25.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

extension Notification.Name {
    static let didTapUserNameNotification = Notification.Name(rawValue: "didTapUserNameNotification")
}

class MeetingCallsCell: UITableViewCell {
    let timeLabel = UILabel()
    let titleTextView = UITextView()
    let durationLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {

        contentView.backgroundColor = UIColor.ud.bgFloat

        let textColor = UIColor.ud.textTitle
        timeLabel.textColor = textColor

        // 数字等宽字体
        let fontFeatures = [
            [UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
             UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector]
        ]
        let descriptorWithFeatures = UIFont.systemFont(ofSize: 14).fontDescriptor.addingAttributes([.featureSettings: fontFeatures])
        timeLabel.font = UIFont(descriptor: descriptorWithFeatures, size: 14)
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        contentView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalToSuperview().inset(10)
            make.height.equalTo(20).priority(999)
        }

        titleTextView.backgroundColor = UIColor.ud.bgFloat
        titleTextView.isScrollEnabled = false
        titleTextView.isEditable = false
        // the following 3 lines make UITextView behavior like UILabel
        titleTextView.textContainerInset = .zero
        titleTextView.textContainer.lineFragmentPadding = 0
        titleTextView.layoutManager.usesFontLeading = false
        titleTextView.delegate = self
        contentView.addSubview(titleTextView)
        titleTextView.snp.makeConstraints { (make) in
            make.left.equalTo(timeLabel.snp.right).offset(12)
            make.right.equalToSuperview()
            make.firstBaseline.equalTo(timeLabel)
            make.height.greaterThanOrEqualTo(timeLabel)
        }

        durationLabel.textColor = UIColor.ud.textPlaceholder
        durationLabel.font = .systemFont(ofSize: 14)
        durationLabel.isHidden = true
        contentView.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(titleTextView)
            make.top.equalTo(titleTextView.snp.bottom).offset(2)
            make.bottom.equalToSuperview()
            make.height.equalTo(0)
        }
    }

    func config(with call: HistoryInfo, meetingType: MeetingType, title: CallDescription, meetingInfo: TabHistoryCommonInfo) {
        timeLabel.text = DateUtil.formatTime(call.actionTime.timeIntervalSince1970)
        let config = VCFontConfig.bodyAssist
        let font = UIFont.systemFont(ofSize: config.fontSize, weight: config.fontWeight)
        let style = NSMutableParagraphStyle()
        let lineHeight: CGFloat = config.lineHeight
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        let string = NSMutableAttributedString(string: title.content, attributes: [.paragraphStyle: style,
                                                                                   .font: font,
                                                                                   .foregroundColor: UIColor.ud.textTitle,
                                                                                   .baselineOffset: -1])
        if let range = title.highlightRange, let userID = title.userID {
            string.addAttributes([.link: userID], range: range)
        }
        titleTextView.attributedText = string
        titleTextView.linkTextAttributes = [.foregroundColor: UIColor.ud.textLinkNormal]

        let shouldShowDuration = call.shouldShowDurationLabel(for: meetingType, meetingInfo: meetingInfo)
        durationLabel.isHidden = !shouldShowDuration
        let shouldShowDurationHeight: Bool = shouldShowDuration && meetingInfo.startTime > 0
        durationLabel.snp.updateConstraints { (make) in
            make.height.equalTo(shouldShowDurationHeight ? 20 : 0)
            make.top.equalTo(titleTextView.snp.bottom).offset(shouldShowDurationHeight ? 2 : 0)
        }
        if shouldShowDuration, meetingInfo.startTime > 0, meetingInfo.endTime > 0 {
            durationLabel.text = DateUtil.formatDuration(TimeInterval(meetingInfo.endTime - meetingInfo.startTime))
        }
    }
}

extension MeetingCallsCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let userID = URL.absoluteString
        NotificationCenter.default.post(name: .didTapUserNameNotification, object: nil, userInfo: ["userID": userID])
        return false
    }
}
