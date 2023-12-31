//
//  MeetingCollectionHeader.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/7.
//

import Foundation
import ByteViewNetwork
import UniverseDesignColor
import ByteViewCommon
import UIKit

class MeetingCollectionHeader: UIView {

    var containerView = UIView()

    var titleIcon = UIImageView()
    var titleLabel = UILabel()

    lazy var titleStackView = UIStackView(arrangedSubviews: [titleIcon, titleLabel])

    lazy var contentStackView = UIStackView(arrangedSubviews: [calendarInfoLabel, line1, timeInfoLabel, line2, totalCountLabel])

    var calendarInfoLabel = UILabel()
    var timeInfoLabel = UILabel()
    var totalCountLabel = UILabel()

    var line1 = UIView()
    var line2 = UIView()
    let userId: String

    init(userId: String) {
        self.userId = userId
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        backgroundColor = .clear

        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)

        calendarInfoLabel.setContentHuggingPriority(.required, for: .horizontal)
        calendarInfoLabel.setContentHuggingPriority(.required, for: .vertical)
        calendarInfoLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        timeInfoLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeInfoLabel.setContentHuggingPriority(.required, for: .vertical)

        totalCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        totalCountLabel.setContentHuggingPriority(.required, for: .vertical)

        titleStackView.spacing = 8.0
        titleStackView.axis = .horizontal
        titleStackView.alignment = .center
        titleStackView.distribution = .equalSpacing

        addSubview(containerView)
        containerView.addSubview(titleStackView)
        containerView.addSubview(contentStackView)

        containerView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16.0)
            $0.top.bottom.equalToSuperview()
        }

        titleIcon.snp.makeConstraints {
            $0.width.height.equalTo(24.0)
        }

        [line1, line2].forEach {
            $0.backgroundColor = UIColor.ud.lineBorderComponent
            $0.snp.makeConstraints {
                $0.width.equalTo(1.0)
                $0.height.equalTo(12.0)
            }
        }
        updateLayout()
    }

    func calculateHeight() -> CGFloat {
        var height: CGFloat
        if traitCollection.isRegular {
            height = 108.0
        } else {
            height = 228.0
        }
        let newSize = titleLabel.sizeThatFits(CGSize(width: containerView.bounds.width, height: .greatestFiniteMagnitude))
        if newSize.height > titleLabel.font.lineHeight * 1.5 {
            height += 28.0
        }
        [calendarInfoLabel, timeInfoLabel, totalCountLabel].forEach {
            let s = $0.sizeThatFits(CGSize(width: containerView.bounds.width, height: .greatestFiniteMagnitude))
            if s.height > $0.font.lineHeight * 1.5 {
                height += 20.0
            }
        }
        return height
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    func updateLayout() {
        if traitCollection.isRegular {
            [titleLabel, calendarInfoLabel, totalCountLabel, timeInfoLabel].forEach {
                $0.numberOfLines = 1
                $0.lineBreakMode = .byTruncatingTail
            }

            contentStackView.spacing = 8.0
            contentStackView.axis = .horizontal
            contentStackView.alignment = .center
            contentStackView.distribution = .equalSpacing

            titleIcon.isHidden = false
            line1.isHidden = false || calendarInfoLabel.isHidden
            line2.isHidden = false || timeInfoLabel.isHidden

            titleStackView.snp.remakeConstraints {
                $0.left.equalToSuperview().inset(48.0)
                $0.right.lessThanOrEqualToSuperview().inset(48.0)
                $0.top.equalToSuperview().inset(32.0)
            }
            contentStackView.snp.remakeConstraints {
                $0.left.equalToSuperview().inset(48.0)
                $0.right.lessThanOrEqualToSuperview().inset(48.0)
                $0.top.equalTo(titleStackView.snp.bottom).offset(6.0)
                $0.height.greaterThanOrEqualTo(22.0)
            }
            [calendarInfoLabel, timeInfoLabel, totalCountLabel].forEach {
                $0.snp.remakeConstraints {
                    $0.height.equalToSuperview()
                }
            }
        } else {
            [titleLabel, calendarInfoLabel, totalCountLabel, timeInfoLabel].forEach {
                $0.numberOfLines = 2
                $0.lineBreakMode = .byWordWrapping
            }

            contentStackView.spacing = 4.0
            contentStackView.axis = .vertical
            contentStackView.alignment = .fill
            contentStackView.distribution = .fill

            titleIcon.isHidden = true
            line1.isHidden = true
            line2.isHidden = true

            titleStackView.snp.remakeConstraints {
                $0.left.right.equalToSuperview()
                $0.top.equalToSuperview().inset(104.0)
            }
            contentStackView.snp.remakeConstraints {
                $0.left.right.equalTo(titleStackView)
                $0.top.equalTo(titleStackView.snp.bottom).offset(8.0)
            }
            [calendarInfoLabel, timeInfoLabel, totalCountLabel].forEach {
                $0.snp.removeConstraints()
            }
        }
    }

    func bindViewModel(_ collection: CollectionInfo) {
        titleIcon.image = collection.collectionType == .ai ? BundleResources.ByteViewTab.Collection.collectionAI : BundleResources.ByteViewTab.Collection.collectionCalendar
        let typeTextColor: UIColor = collection.collectionType == .ai ? UIColor.ud.functionWarningContentDefault : UIColor.ud.textLinkHover
        let attrText = NSMutableAttributedString(attributedString: .init(string: collection.titleContent,
                                                                         config: .h2,
                                                                         alignment: .left,
                                                                         lineBreakMode: .byWordWrapping,
                                                                         textColor: UIColor.ud.textTitle))
        if collection.collectionType.typeContent.count <= collection.titleContent.count {
            attrText.addAttribute(NSAttributedString.Key.foregroundColor, value: typeTextColor, range: NSRange(location: 0, length: collection.collectionType.typeContent.count))
        }
        titleLabel.attributedText = attrText

        var calendarText = ""
        if collection.collectionType == .ai {
            calendarText = I18n.View_G_CollectLatestMeetings_Text(collection.collectionTitle)
        } else {
            calendarText = DateUtil.formatRRuleString(rrule: collection.calendarEventRrule, userId: userId)
        }
        if calendarText.isEmpty {
            calendarInfoLabel.isHidden = true
        } else {
            calendarInfoLabel.isHidden = false
            calendarInfoLabel.attributedText = .init(string: calendarText,
                                                     config: .bodyAssist,
                                                     alignment: .left,
                                                     lineBreakMode: .byWordWrapping,
                                                     textColor: UIColor.ud.textCaption)
        }

        if let vcInfo = collection.items.first {
            let timeStr = DateUtil.formatDateTime(TimeInterval(vcInfo.sortTime), isRelative: true)
            timeInfoLabel.attributedText = .init(string: "\(I18n.View_G_LatestMeetTime)\(timeStr)",
                                                     config: .bodyAssist,
                                                     alignment: .left,
                                                     lineBreakMode: .byWordWrapping,
                                                     textColor: UIColor.ud.textCaption)
            timeInfoLabel.isHidden = false
        } else {
            timeInfoLabel.isHidden = true
        }

        totalCountLabel.attributedText = .init(string: I18n.View_G_NumberMeetings(collection.totalCount),
                                                 config: .bodyAssist,
                                                 alignment: .left,
                                                 lineBreakMode: .byWordWrapping,
                                                 textColor: UIColor.ud.textCaption)
    }
}
