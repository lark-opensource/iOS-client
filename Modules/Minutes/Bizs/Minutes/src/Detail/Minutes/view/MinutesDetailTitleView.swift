//
//  MinutesDetailTitleView.swift
//  Minutes
//
//  Created by chenlehui on 2021/10/29.
//

import UIKit
import MinutesFoundation
import MinutesNetwork
import RichLabel
import YYText
import LarkTimeFormatUtils
import LarkUIKit

struct ScheduleTimeUtil {
    static func autoDeleteString(with schedulerExecuteDeltaTime: Int?) -> String? {
        if let schedulerExecuteTime = schedulerExecuteDeltaTime {
            let time = TimeInterval(schedulerExecuteTime / 1000)
            let day = Int(time / 60 / 60 / 24)
            if day < 1 {
                let hours = Int(time / 60 / 60)
                if hours >= 1 {
                    return " " + BundleI18n.Minutes.MMWeb_G_DeleteAfterHours(hours) + " "
                } else {
                    let minutes = Int(time / 60)
                    return " " + BundleI18n.Minutes.MMWeb_G_DeleteAfterMinutes(minutes) + " "
                }
            } else if day <= 10 {
                return " " + BundleI18n.Minutes.MMWeb_G_DeleteAfterDays(day) + " "
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
class MinutesDetailTitleView: UIView {
    var headerHeight: CGFloat = 0.0
    var minutesInfo: MinutesInfo?
    
    private lazy var audioIcon: UIImageView = {
        let audioIcon = UIImageView(image: BundleResources.Minutes.minutes_audio)
        audioIcon.isHidden = true
        return audioIcon
    }()
    
    private lazy var titleLabel: YYLabel = {
        let label = YYLabel()
        label.font = UIFont.ud.title3
        label.numberOfLines = Display.pad ? 1 : 0
        label.preferredMaxLayoutWidth = ScreenUtils.sceneScreenSize.width - 32
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.caption1
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 1
        return label
    }()

    var isPad: Bool = false {
        didSet {

        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody

        if !Display.pad {
            addSubview(audioIcon)
            audioIcon.snp.makeConstraints { maker in
                maker.left.equalToSuperview().offset(16)
                maker.top.equalToSuperview().offset(16)
                maker.size.equalTo(44)
            }
        }

        addSubview(titleLabel)
        addSubview(subtitleLabel)
        if Display.pad {
            titleLabel.snp.makeConstraints { maker in
                maker.top.equalToSuperview()
                maker.left.equalToSuperview().offset(16)
                maker.right.equalToSuperview().offset(-16)
                maker.height.equalTo(24)
            }
            subtitleLabel.snp.makeConstraints { maker in
                maker.top.equalTo(titleLabel.snp.bottom).offset(2)
                maker.left.right.equalTo(titleLabel)
            }
        } else {
            titleLabel.snp.makeConstraints { maker in
                maker.top.equalToSuperview().offset(20)
                maker.left.equalToSuperview().offset(16)
                maker.right.equalToSuperview().offset(-16)
            }
            subtitleLabel.snp.makeConstraints { maker in
                maker.top.equalTo(titleLabel.snp.bottom).offset(2)
                maker.left.right.equalTo(titleLabel)
                maker.height.equalTo(18)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reloadData() {
        if let minutesInfo = minutesInfo {
            config(with: minutesInfo)
        }
    }
    
    func config(with info: MinutesInfo) {
        guard let basicInfo = info.basicInfo else {
            return
        }
        minutesInfo = info
        if Display.pad {
            
        } else {
            audioIcon.isHidden = true
            if basicInfo.mediaType == .audio {
                audioIcon.image = BundleResources.Minutes.minutes_audio
            } else if basicInfo.mediaType == .text {
                audioIcon.image = BundleResources.Minutes.minutes_text
            }

            let top = 20
            if basicInfo.mediaType == .audio {
                titleLabel.preferredMaxLayoutWidth = ScreenUtils.sceneScreenSize.width - 72 - 16
                titleLabel.snp.remakeConstraints { maker in
                    maker.top.equalToSuperview().offset(top)
                    maker.left.equalToSuperview().offset(16)
                    maker.right.equalToSuperview().offset(-16)
                }
            } else if basicInfo.mediaType == .text {
                titleLabel.preferredMaxLayoutWidth = ScreenUtils.sceneScreenSize.width - 72 - 16
                titleLabel.snp.remakeConstraints { maker in
                    maker.top.equalToSuperview().offset(top)
                    maker.left.equalToSuperview().offset(16)
                    maker.right.equalToSuperview().offset(-16)
                }
            } else {
                titleLabel.preferredMaxLayoutWidth = ScreenUtils.sceneScreenSize.width - 16 * 2
                titleLabel.snp.remakeConstraints { maker in
                    maker.top.equalToSuperview().offset(top)
                    maker.left.equalToSuperview().offset(16)
                    maker.right.equalToSuperview().offset(-16)
                }
            }
        }
        subtitleLabel.text = DateFormat.getLongLocalizedDate(timeInterval: TimeInterval(basicInfo.startTime))
        
        var color = UIColor.ud.textTitle
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                color = UIColor.ud.textTitle.alwaysDark
            } else {
                color = UIColor.ud.textTitle.alwaysLight
            }
        }

        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
        let titleContent = NSMutableAttributedString(string: basicInfo.topic, attributes: attributes)
        // 必须保证tail和前面的个数或长度相同
        let tailContent = NSMutableAttributedString(string: "...", attributes: attributes)
        let tagSpace = NSAttributedString(string: " ")
        
        if info.newTags?.tagType == 2 {
            var i18nValue = DisplayTagPicker.GetTagValue(info.basicInfo?.displayTag)
            if i18nValue?.isEmpty == true {
                i18nValue = info.basicInfo?.displayTag?.tagValue?.value
            }
            let tagCustom = Self.createTag(text: i18nValue, textColor: UIColor.ud.udtokenTagTextSBlue, backgroundColor: UIColor.ud.udtokenTagBgBlue)
            titleContent.append(tagSpace)
            titleContent.append(tagCustom)
            
            tailContent.append(tagSpace)
            tailContent.append(tagCustom)
        } else if info.newTags?.tagType == 1 {
            let tagExternal = Self.createTag(text: BundleI18n.Minutes.MMWeb_G_ExternalLabel, textColor: UIColor.ud.udtokenTagTextSBlue, backgroundColor: UIColor.ud.udtokenTagBgBlue)
            titleContent.append(tagSpace)
            titleContent.append(tagExternal)
            
            tailContent.append(tagSpace)
            tailContent.append(tagExternal)
        } else if info.newTags?.tagType == 3 {
            let tag = Self.createTag(text: BundleI18n.Minutes.MMWeb_G_Webinar_Tag, textColor: UIColor.ud.udtokenTagTextSBlue, backgroundColor: UIColor.ud.udtokenTagBgBlue)
            titleContent.append(tagSpace)
            titleContent.append(tag)

            tailContent.append(tagSpace)
            tailContent.append(tag)
        }
        
        if basicInfo.isRisk == true {
            let tagRisk = Self.createTag(text: BundleI18n.Minutes.MMWeb_FileSecurity_Risk_Tag,
                                        textColor: UIColor.ud.udtokenTagTextSRed,
                                        backgroundColor: UIColor.ud.udtokenTagBgRed)
            titleContent.append(tagSpace)
            titleContent.append(tagRisk)
            
            tailContent.append(tagSpace)
            tailContent.append(tagRisk)
        }
        
        // 自动删除时间
        if !(basicInfo.schedulerType == .none || ScheduleTimeUtil.autoDeleteString(with: basicInfo.schedulerDeltaExecuteTime) == nil) {
            let tagAutoDelete = Self.createTag(text: ScheduleTimeUtil.autoDeleteString(with: basicInfo.schedulerDeltaExecuteTime),
                                        textColor: UIColor.ud.udtokenTagTextSRed,
                                        backgroundColor: UIColor.ud.udtokenTagBgRed)
            titleContent.append(tagSpace)
            titleContent.append(tagAutoDelete)
            
            tailContent.append(tagSpace)
            tailContent.append(tagAutoDelete)
        }
        titleContent.yy_font = titleLabel.font
        tailContent.yy_font = titleLabel.font
        
        titleLabel.attributedText = titleContent
        titleLabel.truncationToken = tailContent
        
        // 强制更新，外面依赖这个高度
        layoutIfNeeded()
        headerHeight = subtitleLabel.frame.maxY + 12
    }

    static func createTag(text: String?, textColor: UIColor?, backgroundColor: UIColor?) -> NSMutableAttributedString {
        let tagLabel = UILabel()
        tagLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        tagLabel.text = text
        tagLabel.textColor = textColor
        tagLabel.backgroundColor = backgroundColor
        tagLabel.textAlignment = .center
        tagLabel.layer.cornerRadius = 4.0
        tagLabel.layer.masksToBounds = true
        tagLabel.bounds = CGRect(x: 0, y: 0, width: tagLabel.intrinsicContentSize.width + 4, height: tagLabel.intrinsicContentSize.height + 4)

        let tagStr = NSMutableAttributedString.yy_attachmentString(withContent: tagLabel,
                                                                   contentMode: .center,
                                                                   attachmentSize: tagLabel.bounds.size,
                                                                   alignTo: tagLabel.font,
                                                                   alignment: .center)
        return tagStr
    }
}

extension MinutesDetailTitleView {
    private func timeString(from st: Int) -> String {
        let timeInterval = TimeInterval(st / 1000)
        let date = Date(timeIntervalSince1970: timeInterval)
        var timeStr: String = ""
        let currentTimerInterval = Date().timeIntervalSince1970
        if date.mins.isInYesterday {  // 昨天
            timeStr = "\(BundleI18n.Minutes.MMWeb_G_Yesterday) \(self.hourMinuteString(with: date))"
        } else if currentTimerInterval - timeInterval < 60 {  // 小于60秒
            timeStr = BundleI18n.Minutes.MMWeb_G_JustNow
        } else if currentTimerInterval - timeInterval < 60 * 60 {  // 小于60分钟
            let minutes = Int((currentTimerInterval - timeInterval) / 60)
            if minutes == 1 {
                timeStr = BundleI18n.Minutes.MMWeb_G_MinutesAgoSingular(minutes)
            } else {
                timeStr = BundleI18n.Minutes.MMWeb_G_MinutesAgo(minutes)
            }
        } else if currentTimerInterval - timeInterval < 60 * 60 * 24 {  // 小于24小时
            let hours = Int((currentTimerInterval - timeInterval) / 60 / 60)
            if hours == 1 {
                timeStr = BundleI18n.Minutes.MMWeb_G_HoursAgoSingular(hours)
            } else {
                timeStr = BundleI18n.Minutes.MMWeb_G_HoursAgo(hours)
            }
        } else if date.mins.isInCurrentYear {  // 今年
            timeStr = TimeFormatUtils.formatDateTime(from: date, with: Options(timePrecisionType: .minute, dateStatusType: .relative))
        } else {  // 去年
            timeStr = TimeFormatUtils.formatDate(from: date, with: Options(timeFormatType: .long, datePrecisionType: .day))
        }
        return timeStr
    }

    private func hourMinuteString(with date: Date) -> String {
        return date.mins.string(withFormat: "H:mm")
    }

    private func monthDayHourMinuteString(with date: Date) -> String {
        let currentLanguage = Locale.current.languageCode
        if currentLanguage == "zh" || currentLanguage == "ja" {  // 中文、日文
            return date.mins.string(withFormat: "M月d日 H:mm", localIdentifier: "zh")
        } else {
            return date.mins.string(withFormat: "MMMM d, H:mm", localIdentifier: "en")
        }
    }

    private func yearMonthDayString(with date: Date) -> String {
        let currentLanguage = Locale.current.languageCode
        if currentLanguage == "zh" || currentLanguage == "ja" {  // 中文、日文
            return date.mins.string(withFormat: "yyyy年M月d日", localIdentifier: "zh")
        } else { // 英文
            return date.mins.string(withFormat: "MMMM d, yyyy", localIdentifier: "en")
        }
    }
}
