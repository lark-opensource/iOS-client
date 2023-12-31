//
//  MinutesHomeItemCell.swift
//  Minutes
//
//  Created by chenlehui on 2021/7/20.
//

import UIKit
import Foundation
import Lottie
import Kingfisher
import MinutesFoundation
import YYText
import LarkMedia
import LarkContainer
import LarkTimeFormatUtils
import UniverseDesignIcon
import MinutesNetwork

class MinutesHomeItemCell: UITableViewCell {
    var userResolver: UserResolver?

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.addArrangedSubview(videoCoverImageView)
        videoCoverImageView.snp.makeConstraints { make in
            make.width.equalTo(120)
            make.height.equalTo(68)
        }
        stackView.setCustomSpacing(12, after: videoCoverImageView)
        stackView.addArrangedSubview(rightStackView)
        return stackView
    }()

    private lazy var rightStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.addArrangedSubview(titleView)
        stackView.setCustomSpacing(4, after: titleView)
        stackView.setCustomSpacing(4, after: titleView)
        stackView.addArrangedSubview(subtitleStackView)
        stackView.setCustomSpacing(4, after: subtitleStackView)
        stackView.addArrangedSubview(complainStatusStackView)
        subtitleStackView.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
        return stackView
    }()

    private lazy var complainStatusStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.addArrangedSubview(complainStatusIcon)
        stackView.setCustomSpacing(4, after: complainStatusIcon)
        stackView.addArrangedSubview(complainStatusLabel)
        complainStatusIcon.snp.makeConstraints { make in
            make.width.height.equalTo(14)
        }
        stackView.isHidden = true
        return stackView
    }()

    private lazy var subtitleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.addArrangedSubview(audioRecordingView)
        audioRecordingView.snp.makeConstraints { make in
            make.width.height.equalTo(14)
        }
        stackView.setCustomSpacing(4, after: audioRecordingView)
        stackView.addArrangedSubview(statusImageView)
        statusImageView.snp.makeConstraints { make in
            make.width.height.equalTo(14)
        }
        stackView.setCustomSpacing(4, after: statusImageView)
        stackView.addArrangedSubview(statusLabel)
        stackView.setCustomSpacing(6, after: statusLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(autoDeleteSubtitleStack)

        return stackView
    }()

    private lazy var videoCoverImageView: UIImageView = {
        let imageView: UIImageView = UIImageView(frame: CGRect.zero)
        imageView.layer.cornerRadius = 6.0
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        let maskView = UIImageView(image: BundleResources.Minutes.minutes_home_cell_mask)
        imageView.addSubview(maskView)
        maskView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.height.equalTo(34)
        }

        imageView.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { maker in
            maker.right.equalTo(-8)
            maker.bottom.equalTo(-4)
        }

        imageView.addSubview(audioRecordingTimeLabel)
        audioRecordingTimeLabel.snp.makeConstraints { maker in
            maker.right.equalTo(-8)
            maker.bottom.equalTo(-4)
            maker.height.equalTo(15)
        }
        return imageView
    }()

    var titleContent: NSMutableAttributedString?
    var tailContent: NSMutableAttributedString?

    private lazy var titleView: YYLabel = {
        let label = YYLabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 2
        // 16左右边距，12是中间间距，120是图片大小
        label.preferredMaxLayoutWidth = ScreenUtils.sceneScreenSize.width - 16 * 2 - 120 - 12
        return label
    }()

    private lazy var statusImageView: UIImageView = {
        let imageView: UIImageView = UIImageView(frame: CGRect.zero)
        imageView.isHidden = true
        return imageView
    }()

    private lazy var statusLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 12)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.isHidden = true
        return label
    }()

    // 录音中动画
    private lazy var audioRecordingView: LOTAnimationView = {
        var view: LOTAnimationView = LOTAnimationView()
        if let jsonPath = BundleConfig.MinutesBundle.path(
                forResource: "minutes_audio_home_playing",
                ofType: "json",
                inDirectory: "lottie") {
            view = LOTAnimationView(filePath: jsonPath)
        }
        view.loopAnimation = true
        view.isHidden = true
        return view
    }()

    private lazy var complainStatusIcon: UIImageView = {
        let imageView: UIImageView = UIImageView()
        return imageView
    }()

    private lazy var complainStatusLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 2
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    private lazy var autoDeleteSubtitleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .top
        stack.distribution = .fill
        stack.addArrangedSubview(autoDeleteSubtitlePartBefore)
        stack.addArrangedSubview(autoDeleteSubtitlePartAfter)
        return stack
    }()

    private lazy var autoDeleteSubtitlePartBefore: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = ""
        return label
    }()

    private lazy var autoDeleteSubtitlePartAfter: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    private lazy var durationLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.textAlignment = .right
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.backgroundColor = UIColor.clear
        return label
    }()

    private lazy var audioRecordingTimeLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.isHidden = true
        label.numberOfLines = 1
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.backgroundColor = UIColor.ud.primaryContentDefault
        label.font = UIFont.systemFont(ofSize: 10)
        label.layer.cornerRadius = 4.0
        label.layer.masksToBounds = true
        return label
    }()

    private lazy var imageDownloader: ImageDownloader = {
        let imageDownloader = ImageDownloader(name: "MinutesImageDownloader")
        imageDownloader.sessionConfiguration = MinutesAPI.sessionConfiguration
        return imageDownloader
    }()

    private var spaceType = MinutesSpaceType.home
    private var item: MinutesSpaceListItem?
    private var countForRemote: Int = 0
    private var timer: Timer?

    private var process: Int? {
        didSet {
            guard oldValue != process else {
                return
            }
            if self.item?.objectStatus == .audioRecordUploading, let value = process {
                statusImageView.image = UDIcon.getIconByKey(.upRoundOutlined, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 14, height: 14))
                statusLabel.text = BundleI18n.Minutes.MMWeb_G_Uploading + "\(value)%"
                statusLabel.textColor = UIColor.ud.primaryContentDefault
            }
        }
    }

    private var transProcess: Double? {
        didSet {
            guard oldValue != transProcess, let item = item, let value = transProcess else {
                return
            }
            if item.objectStatus.minutesIsProcessing() {
                statusLabel.text = BundleI18n.Minutes.MMWeb_G_Processing + "\(Int(value))%"
            } else if item.objectStatus == .waitASR {
                statusLabel.text = BundleI18n.Minutes.MMWeb_G_TranscriptionInProgress + "\(Int(value))%"
            }
        }
    }
    var layoutWidth: CGFloat = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(updateUploadProcess(_:)), name: .MinutesAudioDataUploadProcessNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTranscribeProcess(_:)), name: NSNotification.Name.SpaceList.minutesTranscribing, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        statusLabel.isHidden = true
        statusImageView.isHidden = true
        audioRecordingTimeLabel.isHidden = true
        audioRecordingView.isHidden = true
        complainStatusStackView.isHidden = true
        transProcess = 0
        audioRecordingView.stop()
        timer?.invalidate()
        timer = nil
    }

    @objc
    func updateUploadProcess(_ notification: Notification) {
        guard let objectToken = self.item?.objectToken else {
            return
        }
        guard let token = notification.userInfo?["objectToken"] as? String, token == objectToken else {
            return
        }
        guard let process = notification.userInfo?["process"] as? Int else {
            return
        }
        self.process = process
    }

    @objc
    func updateTranscribeProcess(_ notification: Notification) {
        guard let objectToken = self.item?.objectToken else {
            return
        }

        guard let localMinutesTranscribDictData = notification.userInfo?["localMinutesTranscribDict"] as? [String: TranscribeData] else {
            return
        }
        if let info = localMinutesTranscribDictData[objectToken] {
            self.transProcess = min(99, info.current)
        }
    }

    func config(with item: MinutesSpaceListItem, spaceType: MinutesSpaceType, rankType: MinutesRankType, transProcess: Double?) {
        contentView.backgroundColor = UIColor.ud.bgBody
        self.item = item
        self.spaceType = spaceType
        if let transProcess = transProcess {
            self.transProcess = min(99, transProcess)
        }
        let placeholderImage: UIImage
        switch item.mediaType {
        case .audio:
            placeholderImage = BundleResources.Minutes.minutes_feed_list_item_audio_width
        case .text:
            placeholderImage = BundleResources.Minutes.minutes_feed_list_item_text_width
        case .video:
            placeholderImage = BundleResources.Minutes.minutes_feed_list_item_video_width
        default:
            placeholderImage = BundleResources.Minutes.minutes_feed_list_item_audio_width
        }
        videoCoverImageView.kf.setImage(with: URL(string: item.videoCover),
                placeholder: placeholderImage,
                options: [.downloader(imageDownloader)])

        var color = UIColor.ud.textTitle
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                color = UIColor.ud.textTitle.alwaysDark
            } else {
                color = UIColor.ud.textTitle.alwaysLight
            }
        }

        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color]
        let titleContent = NSMutableAttributedString(string: item.topic, attributes: attributes)
        // 必须保证tail和前面的个数或长度相同
        let tailContent = NSMutableAttributedString(string: "...", attributes: attributes)
        let tagSpace = NSAttributedString(string: " ")

        titleView.isHidden = false


        if item.displayTag?.tagType == 2 {
            var i18nValue = DisplayTagPicker.GetTagValue(item.displayTag)
            if i18nValue?.isEmpty == true {
                i18nValue = item.displayTag?.tagValue?.value
            }
            let tagCustom = MinutesDetailTitleView.createTag(text: i18nValue, textColor: UIColor.ud.udtokenTagTextSBlue, backgroundColor: UIColor.ud.udtokenTagBgBlue)
            titleContent.append(tagSpace)
            titleContent.append(tagCustom)

            tailContent.append(tagSpace)
            tailContent.append(tagCustom)
        } else if item.displayTag?.tagType == 1 {
            let tagExternal = MinutesDetailTitleView.createTag(text: BundleI18n.Minutes.MMWeb_G_ExternalLabel, textColor: UIColor.ud.udtokenTagTextSBlue, backgroundColor: UIColor.ud.udtokenTagBgBlue)
            titleContent.append(tagSpace)
            titleContent.append(tagExternal)

            tailContent.append(tagSpace)
            tailContent.append(tagExternal)
        }

        if item.isRisk == true {
            let tagRisk = MinutesDetailTitleView.createTag(text: BundleI18n.Minutes.MMWeb_FileSecurity_Risk_Tag,
                                        textColor: UIColor.ud.udtokenTagTextSRed,
                                        backgroundColor: UIColor.ud.udtokenTagBgRed)
            titleContent.append(tagSpace)
            titleContent.append(tagRisk)

            tailContent.append(tagSpace)
            tailContent.append(tagRisk)
        }

        if !(item.schedulerType == .none || ScheduleTimeUtil.autoDeleteString(with: item.schedulerDeltaExecuteTime) == nil || rankType == .schedulerExecuteTime) {
            let tagAutoDelete = MinutesDetailTitleView.createTag(text: ScheduleTimeUtil.autoDeleteString(with: item.schedulerDeltaExecuteTime)!,
                                        textColor: UIColor.ud.udtokenTagTextSRed,
                                        backgroundColor: UIColor.ud.udtokenTagBgRed)
            titleContent.append(tagSpace)
            titleContent.append(tagAutoDelete)

            tailContent.append(tagSpace)
            tailContent.append(tagAutoDelete)
        }


        titleContent.yy_font = titleView.font
        tailContent.yy_font = titleView.font

        self.titleContent = titleContent
        self.tailContent = tailContent
        titleView.attributedText = titleContent
        titleView.truncationToken = tailContent

        durationLabel.text = formattedDuration(item.duration / 1000)
        subtitleLabel.textColor = UIColor.ud.textPlaceholder

        if rankType == .schedulerExecuteTime {
            autoDeleteSubtitleStack.isHidden = false
            subtitleLabel.isHidden = true
            configAutoDeleteSubtitle(with: item, spaceType: spaceType)
        } else {
            autoDeleteSubtitleStack.isHidden = true
            subtitleLabel.isHidden = false
        }

        if spaceType == .trash {
            configTrashSubtitle(with: item)
        } else {
            configSubtitle(with: item, spaceType: spaceType, rankType: rankType)
        }

        configStatus(with: item)
    }

    private func changePartFontColor(text: String,
                                     color: UIColor) -> NSAttributedString {
        let attributeString = NSMutableAttributedString(string: text)
        do {
            let regexExpression = try NSRegularExpression(pattern: "\\d+", options: NSRegularExpression.Options())
            let result = regexExpression.matches(
                    in: text,
                    options: NSRegularExpression.MatchingOptions(),
                    range: NSMakeRange(0, text.count)
            )
            for item in result {
                attributeString.setAttributes(
                        [.foregroundColor: color],
                        range: item.range
                )
            }
        } catch {
            print("Failed with error: \(error)")
        }
        return attributeString
    }


    private func configAutoDeleteSubtitle(with item: MinutesSpaceListItem, spaceType: MinutesSpaceType) {
        DispatchQueue.global().async {
            if item.schedulerType != .none, let schedulerDeltaExecuteTime = item.schedulerDeltaExecuteTime {
                let time = TimeInterval(schedulerDeltaExecuteTime / 1000)
                let day = Int(time / 60 / 60 / 24)
                if day < 1 {
                    let hours = Int(time / 60 / 60)
                    if hours >= 1 {
                        DispatchQueue.main.async {
                            if spaceType == .trash {
                                self.autoDeleteSubtitlePartAfter.text = BundleI18n.Minutes.MMWeb_G_AfterNumberHour(hours)
                                self.autoDeleteSubtitlePartAfter.textColor = UIColor.ud.functionDangerContentDefault
                            } else {
                                self.autoDeleteSubtitlePartAfter.attributedText = self.changePartFontColor(text: BundleI18n.Minutes.MMWeb_G_AfterNumberHour(hours), color: UIColor.ud.functionDangerContentDefault)
                            }
                        }
                    } else {
                        let minutes = Int(time / 60)
                        DispatchQueue.main.async {
                            if spaceType == .trash {
                                self.autoDeleteSubtitlePartAfter.text = BundleI18n.Minutes.MMWeb_G_AfterNumberMinute(minutes)
                                self.autoDeleteSubtitlePartAfter.textColor = UIColor.ud.functionDangerContentDefault
                            } else {
                                self.autoDeleteSubtitlePartAfter.attributedText = self.changePartFontColor(text: BundleI18n.Minutes.MMWeb_G_AfterNumberMinute(minutes), color: UIColor.ud.functionDangerContentDefault)
                            }
                        }
                    }
                } else if day <= 10 {
                    DispatchQueue.main.async {
                        if spaceType == .trash {
                            self.autoDeleteSubtitlePartAfter.text = BundleI18n.Minutes.MMWeb_G_AfterNumberDays(day)
                            self.autoDeleteSubtitlePartAfter.textColor = UIColor.ud.functionDangerContentDefault
                        } else {
                            self.autoDeleteSubtitlePartAfter.attributedText = self.changePartFontColor(text: BundleI18n.Minutes.MMWeb_G_AfterNumberDays(day), color: UIColor.ud.functionDangerContentDefault)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.autoDeleteSubtitlePartAfter.text = BundleI18n.Minutes.MMWeb_G_AfterNumberDays(day)
                        self.autoDeleteSubtitlePartAfter.textColor = UIColor.ud.textPlaceholder
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.autoDeleteSubtitlePartAfter.text = BundleI18n.Minutes.MMWeb_G_NoSAutoDelete
                    self.autoDeleteSubtitlePartAfter.textColor = UIColor.ud.textPlaceholder
                }
            }
        }
    }

    private func configSubtitle(with item: MinutesSpaceListItem, spaceType: MinutesSpaceType, rankType: MinutesRankType) {
        DispatchQueue.global().async {
            let timeInterval = TimeInterval(item.time / 1000)
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

            var text = ""
            switch spaceType {
            case .home:
                text = "\(item.ownerName ?? "") │ \(timeStr)"
            case .share, .my:
                text = rankType.subtitle(withTime: timeStr)
            case .trash:
                break
            }

            DispatchQueue.main.async {
                self.subtitleLabel.text = text
            }
        }
    }

    private func configTrashSubtitle(with item: MinutesSpaceListItem) {
        let time = TimeInterval(item.time / 1000)
        var timeStr: String = ""
        subtitleLabel.textColor = UIColor.ud.functionDangerContentDefault
        if time < 60 * 60 {
            let min = Int(time / 60)
            if min == 1 {
                timeStr = BundleI18n.Minutes.MMWeb_M_Trash_NumberMinuteRemaining(min)
            } else {
                timeStr = BundleI18n.Minutes.MMWeb_M_Trash_NumberMinutesRemaining(min)
            }
        } else if time < 60 * 60 * 24 {
            let hour = Int(time / 60 / 60)
            if hour == 1 {
                timeStr = BundleI18n.Minutes.MMWeb_M_Trash_NumberHourRemaining(hour)
            } else {
                timeStr = BundleI18n.Minutes.MMWeb_M_Trash_NumberHoursRemaining(hour)
            }
        } else {
            let day = Int(time / 60 / 60 / 24)
            if day == 1 {
                timeStr = BundleI18n.Minutes.MMWeb_M_Trash_NumberDayRemaining(day)
            } else {
                timeStr = BundleI18n.Minutes.MMWeb_M_Trash_NumberDaysRemaining(day)
            }
            if day > 10 {
                subtitleLabel.textColor = UIColor.ud.textPlaceholder
            }
        }
        subtitleLabel.text = timeStr
    }

    private func configStatus(with item: MinutesSpaceListItem) {
        if item.objectStatus == .audioRecording {
            configAudioStatus(with: item)
        } else if item.objectStatus == .audioRecordUploading || item.objectStatus != .complete || item.reviewStatus != .normal {
            configNormalStatus(with: item)
        }
    }

    private func configAudioStatus(with item: MinutesSpaceListItem) {
        statusLabel.isHidden = false
        audioRecordingTimeLabel.isHidden = false
        statusLabel.text = BundleI18n.Minutes.MMWeb_G_Recording
        statusLabel.textColor = UIColor.ud.textCaption
        playAudioView()
        if isCurrentRecording() {
            onAudioRecorderTimeUpdated(MinutesAudioRecorder.shared.recordingTime)
            onAudioRecorderStatusChanged(MinutesAudioRecorder.shared.status)
            MinutesAudioRecorder.shared.listeners.addListener(self)
        } else {
            timer?.invalidate()
            timer = nil
            countForRemote = item.duration / 1000
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                self.audioRecordingTimeLabel.text = " \(self.formattedDuration(Int(self.countForRemote))) "
                self.countForRemote = self.countForRemote + 1
            })
        }
    }

    private func configNormalStatus(with item: MinutesSpaceListItem) {
        statusImageView.isHidden = false
        statusLabel.isHidden = false
        durationLabel.isHidden = false

        if item.reviewStatus == .manualReviewing {
            statusImageView.isHidden = true
            statusLabel.isHidden = true

            complainStatusStackView.isHidden = false
            complainStatusIcon.image = UDIcon.getIconByKey(.timeOutlined, iconColor: UIColor.ud.functionWarningContentDefault, size: CGSize(width: 14, height: 14))
            complainStatusLabel.text = BundleI18n.Minutes.MMWeb_G_AppealSubmitReview // 审核中
            complainStatusLabel.textColor = UIColor.ud.functionWarningContentDefault
        } else if item.reviewStatus == .autoReviewFailed || item.reviewStatus == .complainFailed {
            statusImageView.isHidden = true
            statusLabel.isHidden = true

            complainStatusStackView.isHidden = false
            complainStatusIcon.image = UDIcon.moreCloseOutlined.colorImage(UIColor.ud.functionWarningContentDefault)
            var title = BundleI18n.Minutes.MMWeb_G_RiskyContentNotApprove // 审核不通过
            if item.reviewStatus == .complainFailed {  // 申诉失败
                title = BundleI18n.Minutes.MMWeb_G_RiskyContentDenyApprove
            }
            complainStatusLabel.text = title
            complainStatusLabel.textColor = UIColor.ud.functionDangerContentDefault
        }

        if item.objectStatus == .waitASR {
            statusImageView.image = UDIcon.getIconByKey(.timeOutlined, iconColor: UIColor.ud.functionWarningContentDefault, size: CGSize(width: 14, height: 14))
            let processValue = self.transProcess == nil ? "0%" : "\(Int(self.transProcess!))%"
            statusLabel.text = BundleI18n.Minutes.MMWeb_G_TranscriptionInProgress + processValue
            statusLabel.textColor = UIColor.ud.functionWarningContentDefault
        } else if item.objectStatus.minutesIsProcessing() {
            statusImageView.image = UDIcon.getIconByKey(.timeOutlined, iconColor: UIColor.ud.functionWarningContentDefault, size: CGSize(width: 14, height: 14))
            let processValue = self.transProcess == nil ? "0%" : "\(Int(self.transProcess!))%"
            statusLabel.text = BundleI18n.Minutes.MMWeb_G_Processing + processValue
            statusLabel.textColor = UIColor.ud.functionWarningContentDefault
            if item.objectType != .recording {
                contentView.backgroundColor = UIColor.ud.bgBodyOverlay

                if let str = titleContent {
                    str.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder], range: NSRange(location: 0, length: str.string.count))
                    titleView.attributedText = str
                }
                if let str = tailContent {
                    str.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder], range: NSRange(location: 0, length: str.string.count))
                    titleView.truncationToken = str
                }

                subtitleLabel.textColor = UIColor.ud.textDisable
            }
        } else if item.objectStatus == .failed || item.objectStatus == .fileCorrupted {
            statusImageView.image = UDIcon.getIconByKey(.moreCloseOutlined, iconColor: UIColor.ud.functionDangerContentDefault, size: CGSize(width: 14, height: 14))
            statusLabel.text = BundleI18n.Minutes.MMWeb_G_Failed
            statusLabel.textColor = UIColor.ud.functionDangerContentDefault
        } else if item.objectStatus == .audioRecordUploading {
            statusImageView.image = UDIcon.getIconByKey(.upRoundOutlined, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 14, height: 14))
            let processValue = self.process == nil ? "" : "\(self.process!)%"
            statusLabel.text = BundleI18n.Minutes.MMWeb_G_Uploading + processValue
            statusLabel.textColor = UIColor.ud.primaryContentDefault
        }
    }

    private func playAudioView() {
        if audioRecordingView.isAnimationPlaying {
            return
        }
        audioRecordingView.isHidden = false
        audioRecordingView.play()
    }

    private func onAudioRecorderStatusChanged(_ audioRecorderStatus: MinutesAudioRecorderStatus) {
        guard let someData = self.item else {
            return
        }
        if !isCurrentRecording() {
            return
        }

        switch audioRecorderStatus {
        case .recording:
            playAudioView()
        case .paused:
            playAudioView()
            audioRecordingView.pause()
        case .idle:
            if var item = self.item {
                if item.objectStatus == .audioRecording {
                    item.objectStatus = .audioRecordUploading
                }
                configStatus(with: item)
            }
        }
    }

    private func onAudioRecorderTimeUpdated(_ timeInterval: TimeInterval) {
        if !isCurrentRecording() {
            return
        }

        DispatchQueue.main.async {
            if !self.isCurrentRecording() {
                return
            }
            self.audioRecordingTimeLabel.text = " \(self.formattedDuration(Int(timeInterval))) "
        }
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

    private func isCurrentRecording() -> Bool {
        guard let someData = self.item else {
            return false
        }
        if someData.objectToken != MinutesAudioRecorder.shared.minutes?.objectToken {
            return false
        }
        return true
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

extension MinutesHomeItemCell: MinutesAudioRecorderListener {
    func audioRecorderDidChangeStatus(status: MinutesAudioRecorderStatus) {
        self.onAudioRecorderStatusChanged(status)
    }

    func audioRecorderOpenRecordingSucceed(isForced: Bool) {

    }

    func audioRecorderTryMideaLockfailed(error: LarkMedia.MediaMutexError, isResume: Bool) {

    }

    func audioRecorderTimeUpdate(time: TimeInterval) {
        self.onAudioRecorderTimeUpdated(time)
    }
}

class MinutesHomeInvalidCell: UITableViewCell {

    private lazy var invalidImage: UIImageView = {
        let img = UIImageView()
        img.image = BundleResources.Minutes.minutes_home_invalid
        return img
    }()

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 2
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = BundleI18n.Minutes.MMWeb_NoKeyNoView_Title
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(invalidImage)
        invalidImage.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.width.equalTo(120)
            make.height.equalTo(68)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalTo(-8)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(invalidImage.snp.right).offset(12)
            make.right.equalTo(-16)
            make.centerY.equalTo(invalidImage)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

