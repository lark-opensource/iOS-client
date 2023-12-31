//
//  MeetTabUpcomingTableViewCell.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UniverseDesignIcon
import UniverseDesignTheme
import UniverseDesignToast
import ByteViewCommon

class MeetTabUpcomingTableViewCell: MeetTabBaseTableViewCell {
    enum DescStyle {
        case long
        case medium
        case short
    }

    private var descStyle: DescStyle = .long {
        didSet {
            extMeetingNumberLabel.attributedText = meetingNumberLabel.attributedText
            extReminderLabel.attributedText = reminderLabel.attributedText
            switch descStyle {
            case .long:
                extStackView.isHidden = true
                if Display.pad {
                    descStackView.separatedSubviews = [timeLabel,
                                                      hasMeetingNumber ? meetingNumberLabel : nil,
                                                      hasReminder ? reminderLabel : nil]
                    extStackView.separatedSubviews = []
                } else {
                    descStackView.separatedSubviews = [hasReminder ? reminderLabel : timeLabel,
                                                      hasMeetingNumber ? meetingNumberLabel : nil]
                    extStackView.separatedSubviews = []
                }

            case .medium:
                if Display.pad {
                    extStackView.isHidden = false
                    descStackView.separatedSubviews = [timeLabel,
                                                      hasMeetingNumber ? meetingNumberLabel : nil]
                    extStackView.separatedSubviews = [hasReminder ? extReminderLabel : nil]
                } else {
                    extStackView.isHidden = true
                    descStackView.separatedSubviews = [hasReminder ? extReminderLabel : timeLabel,
                                                      hasMeetingNumber ? meetingNumberLabel : nil]
                }

            case .short:
                extStackView.isHidden = false
                if Display.pad {
                    descStackView.separatedSubviews = [timeLabel]
                    extStackView.separatedSubviews = [hasMeetingNumber ? extMeetingNumberLabel : nil,
                                                      hasReminder ? extReminderLabel : nil]
                } else {
                    descStackView.separatedSubviews = [hasReminder ? extReminderLabel : timeLabel]
                    extStackView.separatedSubviews = [hasMeetingNumber ? extMeetingNumberLabel : nil]
                }
            }
        }
    }

    var hasMeetingNumber: Bool {
        guard let length = meetingNumberLabel.attributedText?.length else {
            return false
        }
        return length > 0
    }

    var hasReminder: Bool {
        guard let length = reminderLabel.attributedText?.length else {
            return false
        }
        return length > 0
    }

    private var timerDisposeBag: DisposeBag = DisposeBag()

    lazy var meetingNumberLabel: CopyableLabel = {
        let meetingNumberLabel = CopyableLabel()
        meetingNumberLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 750.0), for: .horizontal)
        meetingNumberLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 500.0), for: .horizontal)
        meetingNumberLabel.copyTitle = I18n.View_MV_CopyMeetingID
        meetingNumberLabel.completeTitle = I18n.View_MV_MeetingIDCopied
        meetingNumberLabel.addInteraction(type: .hover)
        meetingNumberLabel.layer.cornerRadius = 2.0
        meetingNumberLabel.clipsToBounds = true
        meetingNumberLabel.delegate = self
        return meetingNumberLabel
    }()

    lazy var reminderLabel: UILabel = {
        let reminderLabel = UILabel(frame: CGRect.zero)
        reminderLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 750.0), for: .horizontal)
        reminderLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 500.0), for: .horizontal)
        return reminderLabel
    }()

    lazy var extMeetingNumberLabel: CopyableLabel = {
        let meetingNumberLabel = CopyableLabel()
        meetingNumberLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 750.0), for: .horizontal)
        meetingNumberLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 500.0), for: .horizontal)
        meetingNumberLabel.copyTitle = I18n.View_MV_CopyMeetingID
        meetingNumberLabel.completeTitle = I18n.View_MV_MeetingIDCopied
        meetingNumberLabel.addInteraction(type: .hover)
        meetingNumberLabel.layer.cornerRadius = 2.0
        meetingNumberLabel.clipsToBounds = true
        meetingNumberLabel.delegate = self
        return meetingNumberLabel
    }()

    lazy var extReminderLabel: UILabel = {
        let reminderLabel = UILabel(frame: CGRect.zero)
        reminderLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 750.0), for: .horizontal)
        reminderLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 500.0), for: .horizontal)
        return reminderLabel
    }()

    var isRegular: Bool {
        MeetTabTraitCollectionManager.shared.isRegular
    }

    var currentTimeText: String = ""

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        descStyle = .long
        if isRegular {
            descStackViewTopConstaint?.update(offset: 2.0)
        } else {
            descStackViewTopConstaint?.update(offset: 4.0)
        }
    }

    override func bindTo(viewModel: MeetTabCellViewModel) {
        guard let viewModel = viewModel as? MeetTabUpcomingCellViewModel else {
            return
        }
        self.viewModel = viewModel

        iconView.config(icon: viewModel.isWebinar ? .webinarOutlined : .videoOutlined,
                        iconColor: UIColor.ud.primaryContentDefault,
                        backgroundViewColor: UIColor.ud.primaryFillSolid01,
                        backgroundViewColorHighlighted: UIColor.ud.primaryFillSolid01)

        configTitle(topic: .init(string: viewModel.topic,
                                 config: .body,
                                 lineBreakMode: .byTruncatingTail,
                                 textColor: .ud.textTitle),
                    callCount: nil,
                    tagType: viewModel.meetingTagType,
                    webinarMeeting: viewModel.isWebinar)

//      同步LM和DM
        if #available(iOS 13.0, *) {
            let correctStyle = UDThemeManager.userInterfaceStyle
            let correctTraitCollection = UITraitCollection(userInterfaceStyle: correctStyle)
            UITraitCollection.current = correctTraitCollection
        }

        let isRegular = isRegular
        let config: VCFontConfig = isRegular ? .tinyAssist : .bodyAssist
        let textColor: UIColor = isRegular ? .ud.textCaption : .ud.textPlaceholder
        timeLabel.attributedText = .init(string: viewModel.timing, config: config, textColor: textColor)
        meetingNumberLabel.attributedText = .init(string: viewModel.meetingNumber, config: config, textColor: textColor)
        [meetingNumberLabel, extMeetingNumberLabel].forEach { $0.tapGesture.isEnabled = isRegular }
        reminderLabel.attributedText = .init(string: viewModel.reminderTiming, config: config, textColor: UIColor.ud.functionWarningContentDefault)
        viewModel.reminderTimingDriver
            .drive(onNext: { [weak self] timing in
                guard let self = self else { return }
                if self.currentTimeText != timing {
                    self.currentTimeText = timing
                    self.reminderLabel.attributedText = .init(string: timing, config: config, textColor: UIColor.ud.functionWarningContentDefault)
                    self.reloadStackViews(tableWidth: nil)
                    self.delegate?.reloadWholeView()
                }
            }).disposed(by: timerDisposeBag)

        updateLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func reloadStackViews(tableWidth: CGFloat?) {
        let spacing: CGFloat = 17.0
        let timeLength: CGFloat = timeLabel.sizeThatFits(CGSize(width: -.greatestFiniteMagnitude, height: 18.0)).width
        let numberLength: CGFloat = meetingNumberLabel.sizeThatFits(CGSize(width: -.greatestFiniteMagnitude, height: 18.0)).width
        let reminderTimingLength: CGFloat
        if !hasReminder {
            reminderTimingLength = 0.0
        } else {
            reminderTimingLength = reminderLabel.sizeThatFits(CGSize(width: -.greatestFiniteMagnitude, height: 18.0)).width
        }
        let length2: CGFloat = timeLength + spacing + numberLength
        let length3: CGFloat = length2 + spacing + reminderTimingLength
        let isRegular: Bool = isRegular
        let containerLenth: CGFloat
        if let tableWidth = tableWidth {
            containerLenth = tableWidth - (isRegular ? 92.0 : 32.0)
        } else {
            containerLenth = containerView.bounds.width
        }

        if containerLenth > length3 {
            descStyle = .long
        } else if containerLenth > length2 {
            descStyle = .medium
        } else {
            descStyle = .short
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        timerDisposeBag = DisposeBag()
        descStyle = .long
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !self.isHidden else { return super.hitTest(point, with: event) }
        let result = super.hitTest(point, with: event)
        let labelPoint = meetingNumberLabel.convert(point, from: self)
        let extLabelPoint = extMeetingNumberLabel.convert(point, from: self)
        if meetingNumberLabel.point(inside: labelPoint, with: event) {
            return meetingNumberLabel
        } else if extMeetingNumberLabel.point(inside: extLabelPoint, with: event) {
            return extMeetingNumberLabel
        } else {
            return result
        }
    }

}

extension MeetTabUpcomingTableViewCell: CopyableLabelDelegate {
    func labelTextDidCopied(_ label: CopyableLabel) {
        guard let viewModel = viewModel as? MeetTabUpcomingCellViewModel else {
            return
        }
        if let text = label.text, viewModel.viewModel.setPasteboardText(text, token: .tabListUpcomingMeetingId),
           let view = label.window {
            let config = UDToastConfig(toastType: .success, text: label.completeTitle, operation: nil)
            UDToast.showToast(with: config, on: view)
        }
        MeetTabTracks.trackMeetTabOperation(.clickUpcomingCopy, with: ["meeting_number": viewModel.instance.meetingNumber])
    }
}
