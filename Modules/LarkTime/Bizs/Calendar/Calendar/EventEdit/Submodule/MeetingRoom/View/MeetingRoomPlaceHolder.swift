//
//  MeetingRoomPlaceHolder.swift
//  Calendar
//
//  Created by zhuheng on 2021/2/9.
//

import UIKit
import UniverseDesignIcon
import Foundation
import RichLabel
import LarkTimeFormatUtils
import LarkActivityIndicatorView

final class MeetingRoomFakeCell: UITableViewCell {}

// 会议室一键调整的Label
final class MeetingRoomAutoJustTimeLabel: LKLabel, LKLabelDelegate {
    let horizontalPadding: CGFloat
    static let lineHeight: CGFloat = 22
    private var tapHandler: () -> Void = { }
    private var tapRange: NSRange?

    init(horizontalPadding: CGFloat) {
        self.horizontalPadding = horizontalPadding
        super.init(frame: .zero)
        backgroundColor = .ud.bgBody
        self.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateInfo(date: Date,
                    timezone: TimeZone,
                    preferredMaxLayoutWidth: CGFloat,
                    tapHandler: @escaping () -> Void,
                    font: UIFont = .systemFont(ofSize: 14)) {
        // 获取原始提示
        let originText = getHeaderText(date: date, font: font, timezone: timezone)
        // 获取“一键调整”
        let tailText = I18n.Calendar_G_AvailabilitySuggestion_ChangeNow_Button
        let attr = NSAttributedString(string: tailText, attributes: [.font: font, .foregroundColor: UIColor.ud.primaryContentDefault])
        var rect = attr.boundingRect(with: CGSize(width: 1000, height: Self.lineHeight), options: .usesLineFragmentOrigin, context: nil)
        rect.size = CGSize(width: rect.size.width, height: Self.lineHeight)
        let tapString = generateAttmentAttributedStringWithText(attr,
                                                                font: font,
                                                                size: rect.size,
                                                                margin: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        )
        // 添加“一键调整”
        originText.append(tapString)
        let tapRange = NSRange(location: originText.length - 1, length: 1)
        self.updateText(originText,
                        preferredMaxLayoutWidth: preferredMaxLayoutWidth,
                        tapHandler: tapHandler,
                        tapRange: tapRange)

        // 获取头部文本内容
        func getHeaderText(date: Date, font: UIFont, timezone: TimeZone) -> NSMutableAttributedString {
            let customOptions = Options(
                timeZone: timezone,
                timeFormatType: .long,
                datePrecisionType: .day
            )
            let style = NSMutableParagraphStyle()
            style.minimumLineHeight = Self.lineHeight
            style.maximumLineHeight = Self.lineHeight
            let dateDesc = TimeFormatUtils.formatDate(from: date, with: customOptions)
            let toast = I18n.Calendar_G_AvailabilitySuggestion_Tip(eventEndTime: dateDesc)
            let originText = NSMutableAttributedString(string: toast, attributes: [.foregroundColor: UIColor.ud.textPlaceholder, .paragraphStyle: style, .font: font])
            return originText
        }

        // 生成LKAsyncAttachment的富文本
        func generateAttmentAttributedStringWithText(_ attr: NSAttributedString,
                                                     font: UIFont,
                                                     size: CGSize,
                                                     margin: UIEdgeInsets = .zero) -> NSAttributedString {
            let attachment = LKAsyncAttachment(
                viewProvider: {
                    let label = UILabel()
                    label.attributedText = attr
                    return label
                },
                size: size
            )
            attachment.fontAscent = font.ascender
            attachment.fontDescent = font.descender
            attachment.size = size
            attachment.margin = margin
            return NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                      attributes: [LKAttachmentAttributeName: attachment])

        }
    }

    func updateText(_ text: NSAttributedString,
                    preferredMaxLayoutWidth: CGFloat,
                    tapHandler: @escaping () -> Void,
                    tapRange: NSRange) {
        self.attributedText = text
        self.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        self.tapRange = tapRange
        self.tapableRangeList = [tapRange]
        self.tapHandler = tapHandler
    }

    func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        if range == tapRange {
            tapHandler()
            return false
        }
        return true
    }
}

// 固定层级会议室一键调整的cell
final class MeetingRoomAutoJustTimeCell: UITableViewCell {
    static let horizontalPadding: CGFloat = 48
    private var descLabel = MeetingRoomAutoJustTimeLabel(horizontalPadding: MeetingRoomAutoJustTimeCell.horizontalPadding)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(descLabel)
        contentView.backgroundColor = .ud.bgBody
        descLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(Self.horizontalPadding)
            $0.top.bottom.equalToSuperview()
        }
    }

    func updateInfo(date: Date,
                    timezone: TimeZone,
                    preferredMaxLayoutWidth: CGFloat,
                    tapHandler: @escaping () -> Void,
                    font: UIFont = .systemFont(ofSize: 14)) {
        descLabel.updateInfo(date: date,
                             timezone: timezone,
                             preferredMaxLayoutWidth: preferredMaxLayoutWidth,
                             tapHandler: tapHandler)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MeetingRoomEmptyCell: UITableViewCell {
    private var emptyInfoLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = .ud.bgBody
        emptyInfoLabel.text = BundleI18n.Calendar.Calendar_Detail_NoAvailableRoomsFound
        emptyInfoLabel.font = UIFont.cd.regularFont(ofSize: 14)
        emptyInfoLabel.textColor = UIColor.ud.textPlaceholder

        addSubview(emptyInfoLabel)
        emptyInfoLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(48)
            $0.centerY.right.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MeetingRoomRetryCell: UITableViewCell {
    private let warningIcon = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.warningOutlined).ud.withTintColor(UIColor.ud.functionWarningContentDefault))
    private var retryLabel = UILabel()

    var clickHandler: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        addSubview(warningIcon)
        warningIcon.snp.makeConstraints {
            $0.left.equalToSuperview().offset(48)
            $0.width.height.equalTo(16)
            $0.centerY.equalToSuperview()
        }

        retryLabel.text = BundleI18n.Calendar.Calendar_Edit_FindTimeFailed
        addSubview(retryLabel)
        retryLabel.snp.makeConstraints {
            $0.left.equalTo(warningIcon.snp.right).offset(8)
            $0.centerY.right.equalToSuperview()
        }

        let contentTapGesture = UITapGestureRecognizer()
        contentTapGesture.addTarget(self, action: #selector(contentTapped))
        addGestureRecognizer(contentTapGesture)

    }

    @objc
    func contentTapped() {
        self.clickHandler?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MeetingRoomLoadingCell: UITableViewCell {
    private var loadingLabel = UILabel()
    private let loadingIndicator = ActivityIndicatorView(color: UIColor.ud.primaryContentDefault)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(loadingIndicator)
        contentView.backgroundColor = .ud.bgBody
        loadingIndicator.snp.makeConstraints {
            $0.width.height.equalTo(16)
            $0.left.equalToSuperview().offset(48)
            $0.centerY.equalToSuperview()
        }
        loadingIndicator.startAnimating()

        loadingLabel.text = BundleI18n.Calendar.Calendar_Common_LoadingCommon
        loadingLabel.font = UIFont.cd.font(ofSize: 14)
        loadingLabel.textColor = UIColor.ud.N600

        contentView.addSubview(loadingLabel)
        loadingLabel.snp.makeConstraints {
            $0.left.equalTo(loadingIndicator.snp.right).offset(8)
            $0.centerY.right.equalToSuperview()
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
