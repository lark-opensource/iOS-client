//
//  VChatMeetingCardView.swift
//  Action
//
//  Created by Prontera on 2019/6/4.
//

import Foundation
import LarkUIKit
import RxSwift
import SnapKit
import LarkSDKInterface
import LarkModel
import ByteViewUDColor
import UniverseDesignFont
import RichLabel
import UniverseDesignCardHeader
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignToast
import ByteViewCommon
import LarkContainer
import LarkSetting

enum CardViewStyle {
    // 三种UI形态，长中短, Aurora需求去掉
    case longStyle
    case middleStyle
    case shortStyle
}

enum MeetingTagType: Equatable {
    case none
    /// 外部
    case external
    /// 互通
    case cross
    /// 关联租户
    case partner(String)

    var text: String? {
        switch self {
        case .external:
            return I18n.View_G_ExternalLabel
        case .cross:
            return I18n.View_G_ConnectLabel
        case .partner(let relationTag):
            return relationTag
        case .none:
            return nil
        }
    }
}

extension MeetingTagType: CustomStringConvertible {
    var description: String {
        switch self {
        case .partner:
            return "partner"
        default:
            return text ?? ""
        }
    }
}

class VChatMeetingCardView: UIView {
    private let disposeBag = DisposeBag()
    private var internalDisposeBag = DisposeBag()
    var viewModel: VChatMeetingCardViewModelImpl
    private var viewModelDisposeBag = DisposeBag()

    var givenWidth: CGFloat
    var meetingTagType: MeetingTagType = .none
    var meetingDeviceDesc: String?
    var topicAttributeString: NSMutableAttributedString

    private lazy var topicContainerView: UIView = {
        let cardHeader = UIView()
        cardHeader.backgroundColor = UIColor.ud.bgFloat
        return cardHeader
    }()

    private lazy var topicImageView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.videoFilled, iconColor: UIColor.ud.functionSuccessFillDefault, size: CGSize(width: 16, height: 16))
        return view
    }()

    private lazy var topicLabel: LKLabel = {
        let label = LKLabel()
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.lineSpacing = 1
        return label
    }()

    var externalViewWidth: CGFloat{
        let rect = NSString(string: I18n.View_G_ExternalLabel)
            .boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: 18),
                          options: [.usesLineFragmentOrigin, .usesFontLeading],
                          attributes: [.font: UIFont.systemFont(ofSize: 12)],
                          context: nil)
        return rect.size.width + Layout.externalMargin * 2
    }

    private lazy var meetNumberImage: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.infoOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16, height: 16))
        return view
    }()

    private lazy var meetNumberLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var lastTimeLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.udtokenMessageCardTextGreen
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        label.minimumScaleFactor = 0.8
        label.textAlignment = .right
        return label
    }()

    private lazy var participantsContainerView: UIView = { // 改个名字
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()

    private lazy var participantsImage: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey((viewModel.content.isWebinar ?? false) ? .webinarOutlined : .groupOutlined,
                                         iconColor: UIColor.ud.iconN3,
                                         size: CGSize(width: 16, height: 16))
        return view
    }()

    private lazy var participantsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var participantsView: VChatMeetingCardParticipantsPreview = {
        let view = VChatMeetingCardParticipantsPreview()
        view.isAutoResizingEnabled = false
        view.delegate = self
        view.backgroundColor = UIColor.clear
        view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return view
    }()

    private lazy var attendeesCountImage: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.communityTabOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16, height: 16))
        return view
    }()

    private lazy var attendeesCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 1
        return label
    }()

    private lazy var joinedDeviceImage: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.multideviceOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16, height: 16))
        return view
    }()

    private lazy var joinedDeviceLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var joinButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6.0
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.isExclusiveTouch = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return button
    }()

    fileprivate struct Layout {
        static let imageTopMargin: CGFloat = 15.0
        static let imageLeftMargin: CGFloat = 12.0
        static let imageViewSize: CGFloat = 16.0
        static let timeRightMargin: CGFloat = 12.0

        static let topicLeftRightMargin: CGFloat = 8.0
        static let topicTopMargin: CGFloat = 12.5  // 原本为12 12，因为richlabel整体偏高不居中
        static let topicBottomMargin: CGFloat = 11.5

        static let infoLeftMargin: CGFloat = 12.0
        static let infoRightMargin: CGFloat = 12.0
        static let infoInnerMargin: CGFloat = 8.0

        static let numberImageTopMargin: CGFloat = 2.0
        static let numberImageSize: CGFloat = 16.0
        static let participantsViewTopMargin: CGFloat = 8.0
        static let participantsViewRightMargin: CGFloat = 12.0
        static let participantsViewWebianrLeftMargin: CGFloat = 2.0
        static let attendeesTopMargin: CGFloat = 8.0

        static let timeLongWidth: CGFloat = 62.0  // 小时时间
        static let timeShortWidth: CGFloat = 40.0  // 普通时间

        static let meetingNumberTopMargin: CGFloat = 0.0

        static let joinButtonTopMargin: CGFloat = 16.0
        static let joinButtonWebinarTopMargin: CGFloat = 12.0
        static let joinButtonHeight: CGFloat = 36.0
        static let joinButtonLeftRightMargin: CGFloat = 12.0
        static let joinButtonBottomMargin: CGFloat = 12.0

        static let infoLabelHeight: CGFloat = 20.0
        static let participantsViewHeight: CGFloat = 24.0
        static let externalMargin: CGFloat = 4.0
        static let externalFontsize: CGFloat = 12.0

        static let joinedDeviceImageSize: CGFloat = 16.0
        static let joinedDeviceViewTopMargin: CGFloat = 8.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isShowHour: Bool   // 用来处理前后不一致UI刷新

    init(viewModel: VChatMeetingCardViewModelImpl, frame: CGRect) {
        self.viewModel = viewModel
        self.isShowHour = viewModel.computeIsShowHour()
        self.givenWidth = frame.size.width
        self.topicAttributeString = viewModel.buideAttributeTitle(topic: viewModel.content.topic, isEnded: nil, isWebinar: viewModel.content.isWebinar, meetingTagType: viewModel.getMeetingTagType(), meetingSource: viewModel.meetingSource).0

        super.init(frame: frame)

        setUpUI()
        self.bindViewModel(viewModel)
        layoutViews()
    }

    private func setUpUI() {
        backgroundColor = UIColor.ud.bgFloat

        topicContainerView.addSubview(topicImageView)
        topicContainerView.addSubview(topicLabel)
        topicContainerView.addSubview(lastTimeLabel)
        participantsContainerView.addSubview(meetNumberImage)
        participantsContainerView.addSubview(meetNumberLabel)
        participantsContainerView.addSubview(participantsImage)
        participantsContainerView.addSubview(participantsLabel)
        participantsContainerView.addSubview(participantsView)
        participantsContainerView.addSubview(attendeesCountImage)
        participantsContainerView.addSubview(attendeesCountLabel)
        participantsContainerView.addSubview(joinedDeviceImage)
        participantsContainerView.addSubview(joinedDeviceLabel)
        participantsContainerView.addSubview(joinButton)
        addSubview(topicContainerView)
        addSubview(participantsContainerView)
    }

    private func layoutViews() {

        refreshLayout()

        topicContainerView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(topicLabel.snp.bottom).offset(Layout.topicBottomMargin)
        }

        topicImageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Layout.imageTopMargin)
            make.left.equalToSuperview().offset(Layout.imageLeftMargin)
            make.size.equalTo(Layout.imageViewSize)
        }

        participantsContainerView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(topicContainerView.snp.bottom)
        }

        meetNumberImage.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Layout.infoLeftMargin)
            make.top.equalToSuperview().offset(Layout.numberImageTopMargin)
            make.size.equalTo(Layout.numberImageSize)
        }

        participantsImage.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Layout.infoLeftMargin)
            make.centerY.equalTo(participantsView)
            make.size.equalTo(16)
        }
    }

    private func refreshLayout() {
        let topicWidth = viewModel.calculateTopicWidth(width: givenWidth, isShowHour: isShowHour)
        let topicHeight = viewModel.attributeHeight(attributeString: topicAttributeString, width: topicWidth)
        let isWebinar = viewModel.content.isWebinar == true

        [participantsLabel, attendeesCountImage, attendeesCountLabel].forEach { $0.isHidden = !isWebinar }
        participantsImage.image = UDIcon.getIconByKey(isWebinar ? .webinarOutlined : .groupOutlined,
                                                      iconColor: UIColor.ud.iconN3,
                                                      size: CGSize(width: 16, height: 16))
        if isWebinar {
            participantsLabel.snp.remakeConstraints { make in
                make.left.equalTo(participantsImage.snp.right).offset(Layout.infoInnerMargin)
                make.centerY.equalTo(participantsImage)
                make.height.equalTo(Layout.infoLabelHeight)
            }

            participantsView.snp.remakeConstraints { (make) in
                make.left.equalTo(participantsLabel.snp.right).offset(Layout.participantsViewWebianrLeftMargin)
                make.top.equalTo(meetNumberLabel.snp.bottom).offset(Layout.participantsViewTopMargin)
                make.height.equalTo(Layout.participantsViewHeight)
                make.right.lessThanOrEqualToSuperview().offset(-Layout.participantsViewRightMargin)
            }

            attendeesCountImage.snp.remakeConstraints { make in
                make.left.equalTo(participantsImage)
                make.centerY.equalTo(attendeesCountLabel)
                make.size.equalTo(16)
            }

            attendeesCountLabel.snp.remakeConstraints { make in
                make.left.equalTo(attendeesCountImage.snp.right).offset(Layout.infoInnerMargin)
                make.top.equalTo(participantsView.snp.bottom).offset(Layout.attendeesTopMargin)
                make.height.equalTo(Layout.infoLabelHeight)
            }

            joinedDeviceLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(joinedDeviceImage.snp.right).offset(Layout.infoInnerMargin)
                make.top.equalTo(attendeesCountLabel.snp.bottom).offset(Layout.joinedDeviceViewTopMargin)
                make.right.equalToSuperview().inset(Layout.infoRightMargin)
            }
        } else {
            participantsView.snp.remakeConstraints { (make) in
                make.left.equalTo(participantsImage.snp.right).offset(Layout.infoInnerMargin)
                make.top.equalTo(meetNumberLabel.snp.bottom).offset(Layout.participantsViewTopMargin)
                make.height.equalTo(Layout.participantsViewHeight)
            }

            joinedDeviceLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(joinedDeviceImage.snp.right).offset(Layout.infoInnerMargin)
                make.top.equalTo(participantsView.snp.bottom).offset(Layout.joinedDeviceViewTopMargin)
                make.right.equalToSuperview().inset(Layout.infoRightMargin)
            }
        }
        joinedDeviceImage.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(Layout.infoLeftMargin)
            make.top.equalTo(joinedDeviceLabel).offset(3)
            make.size.equalTo(Layout.joinedDeviceImageSize)
        }

        let numberHeight = viewModel.calculateMeetNumberHeight(width: givenWidth, meetNumber: viewModel.meetingNumber)
        meetNumberLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Layout.meetingNumberTopMargin)
            make.right.equalToSuperview().offset(-Layout.infoRightMargin)
            make.left.equalTo(meetNumberImage.snp.right).offset(Layout.infoInnerMargin)
            make.height.equalTo(numberHeight)
        }

        lastTimeLabel.snp.remakeConstraints { (make) in
            make.centerY.equalTo(topicImageView)
            make.right.equalToSuperview().offset(-Layout.timeRightMargin)
            make.size.equalTo(CGSize(width: isShowHour ? Layout.timeLongWidth : Layout.timeShortWidth, height: 20))
        }

        topicLabel.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(Layout.topicTopMargin)
            make.left.equalTo(topicImageView.snp.right).offset(Layout.topicLeftRightMargin)
            make.right.equalTo(lastTimeLabel.snp.left).offset(-Layout.topicLeftRightMargin)
            make.height.equalTo(topicHeight)
        }

        joinButton.snp.remakeConstraints { (make) in
            let topOffset = isWebinar ? Layout.joinButtonWebinarTopMargin : Layout.joinButtonTopMargin
            if joinedDeviceLabel.isHidden {
                if isWebinar {
                    make.top.equalTo(attendeesCountLabel.snp.bottom).offset(topOffset)
                } else {
                    make.top.equalTo(participantsView.snp.bottom).offset(topOffset)
                }
            } else {
                make.top.equalTo(joinedDeviceLabel.snp.bottom).offset(topOffset)
            }
            make.left.equalToSuperview().offset(Layout.joinButtonLeftRightMargin)
            make.right.equalToSuperview().offset(-Layout.joinButtonLeftRightMargin)
            make.height.equalTo(Layout.joinButtonHeight)
        }
    }

    private func updateTopicLabel(by topic: String, status: MeetingCardStatus, meetingTagType: MeetingTagType) {
        let (titleText, outText) = viewModel.buideAttributeTitle(topic: topic,
                                                               isEnded: status == .unknown || status == .end ? true : false,
                                                             isWebinar: viewModel.content.isWebinar,
                                                        meetingTagType: meetingTagType,
                                                         meetingSource: viewModel.meetingSource)
        self.topicAttributeString = titleText
        topicLabel.attributedText = titleText
        topicLabel.outOfRangeText = outText

        let topicWidth = viewModel.calculateTopicWidth(width: givenWidth, isShowHour: isShowHour)
        let topicHeight = viewModel.attributeHeight(attributeString: titleText, width: topicWidth)
        topicLabel.snp.updateConstraints { make in
            make.height.equalTo(topicHeight)
        }
    }

    private func updateViewsColor(status: MeetingCardStatus) {
        var color: UIColor
        var topicImgColor: UIColor
        switch status {
        case .joinable, .full, .joined:
            color = UIColor.ud.udtokenMessageCardTextGreen
            topicImgColor = UIColor.ud.functionSuccessContentDefault
        case .unknown, .end:
            color = UIColor.ud.textPlaceholder
            topicImgColor = UIColor.ud.iconDisabled
        }
        topicImageView.image = UDIcon.getIconByKey(.videoFilled, iconColor: topicImgColor, size: CGSize(width: 16, height: 16))
        lastTimeLabel.textColor = color
    }

    private func updateButtons(by status: MeetingCardStatus, meetingSource: VCMeetingSource) {
        switch status {
        case .joinable:
            joinButton.setTitle(I18n.Lark_View_JoinButton, for: .normal)
            joinButton.setTitleColor(UIColor.ud.functionSuccessContentDefault, for: .normal)
            joinButton.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
            joinButton.setBackgroundColor(UIColor.ud.udtokenBtnSelectedBgSuccessPress, for: .highlighted)
            joinButton.layer.ud.setBorderColor(UIColor.ud.functionSuccessContentDefault)
        case .joined:
            joinButton.setTitle(I18n.Lark_View_JoinedButton, for: .normal)
            joinButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
            joinButton.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
            joinButton.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
            joinButton.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        case .full:
            joinButton.setTitle(I18n.Lark_View_FullButton, for: .normal)
            joinButton.setTitleColor(UIColor.ud.textDisabled, for: .normal)
            joinButton.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
            joinButton.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .highlighted)
            joinButton.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        case .unknown, .end:
            joinButton.setTitle(I18n.Lark_View_EndedButton, for: .normal)
            joinButton.setTitleColor(UIColor.ud.textDisabled, for: .normal)
            joinButton.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
            joinButton.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .highlighted)
            joinButton.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        }
    }

    private func didTapPreviewParticipants() {
        self.viewModel.participantsPreviewTapped()
    }

    private func updateParticipantsView(by previewedParticipants: [VChatPreviewedParticipant], totalCount: Int) {
        participantsView.updateParticipants(previewedParticipants, totalCount: totalCount)
    }

    func updateUI(maxWidth: CGFloat, isShowHour: Bool) {
        self.isShowHour = isShowHour
        self.givenWidth = maxWidth
        refreshLayout()
    }

    func bindViewModel(_ vm: VChatMeetingCardViewModelImpl) {
        guard vm !== self.viewModel else {
            return
        }
        self.viewModelDisposeBag = DisposeBag()
        self.viewModel = vm
        if self.window != nil {
            self.attachViewModel()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window == nil {
            detachViewModel()
        } else {
            attachViewModel()
        }
    }

    private func detachViewModel() {
        self.viewModelDisposeBag = DisposeBag()
    }

    private func attachViewModel() {
        let vm = self.viewModel
        self.viewModelDisposeBag = DisposeBag()
        let meetingSource = vm.meetingSource
        let meetingNumber = vm.meetingNumber

        Observable.combineLatest(vm.topic, vm.joinButtonStatus, vm.meetingTagType)
            .observeOn(MainThreadScheduler.instance)
            .subscribe(onNext: { [weak self] topic, status, meetingTagType in
                guard let self = self else { return }
                self.updateTopicLabel(by: topic, status: status, meetingTagType: meetingTagType)
                self.updateViewsColor(status: status)
                self.updateButtons(by: status, meetingSource: meetingSource)
                Logger.meetingCard.info("\(meetingNumber) update major")
            })
            .disposed(by: self.viewModelDisposeBag)

        meetNumberLabel.attributedText = vm.meetingNumberAttribute(number: vm.meetingNumber)
        meetNumberLabel.lineBreakMode = .byTruncatingTail // 设置 attributedText 的时候，之前设置的 lineBreakMode 会失效
        participantsLabel.text = I18n.View_G_PanelistColon

        vm.meetingTagType
            .asObservable()
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] type in
                guard let self = self else { return }
                if type != self.meetingTagType {
                    self.meetingTagType = type
                    self.viewModel.changeSelfFrame()
                }
            })
            .disposed(by: self.viewModelDisposeBag)

        vm.webinarAttendeeNum.subscribe(onNext: { [weak self] in
            self?.attendeesCountLabel.text = I18n.View_G_AttendeeColon($0)
        }).disposed(by: viewModelDisposeBag)

        vm.meetingDuration
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] duration in
                guard let self = self else {
                    return
                }
                let (time, isShowHourNew) = VChatMeetingCardViewModelImpl.formatMeetingDuration(duration)
                self.lastTimeLabel.text = time
                if !self.isShowHour && isShowHourNew {
                    self.viewModel.changeSelfFrame() // 之前不显示时间现在显示 通知tableview从新计算高度
                }
                self.isShowHour = isShowHourNew
                Logger.meetingCard.info("\(meetingNumber) update meetingDuration")
            })
            .disposed(by: self.viewModelDisposeBag)

        vm.participants
            .map({ slice -> VChatPreviewedParticipantSlice in
                return VChatPreviewedParticipantSlice(participants: Array(slice.participants.prefix(MeetingCardConstant.countOfParticipantsInCell)),
                                                      totalCount: slice.totalCount)
            })
            .distinctUntilChanged(Self.compareVCPreviewedParticipantSlice(lhs:rhs:))
            .subscribe(onNext: { [weak self] slice in
                self?.updateParticipantsView(by: slice.participants,
                                             totalCount: slice.totalCount)
                Logger.meetingCard.info("\(meetingNumber) update participants")
            })
            .disposed(by: self.viewModelDisposeBag)

        vm.joinedDeviceDesc.asObservable()
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] deviceDesc in
                guard let self = self else { return }
                if let deviceDesc = deviceDesc {
                    self.joinedDeviceImage.isHidden = false
                    self.joinedDeviceLabel.isHidden = false
                    self.joinedDeviceLabel.attributedText = self.viewModel.joinedDeviceAttribute(deviceDesc: deviceDesc)
                } else {
                    self.joinedDeviceImage.isHidden = true
                    self.joinedDeviceLabel.isHidden = true
                }
                self.refreshLayout()
                if deviceDesc != self.meetingDeviceDesc {
                    self.meetingDeviceDesc = deviceDesc
                    self.viewModel.changeSelfFrame()
                }
            })
            .disposed(by: self.viewModelDisposeBag)

        self.joinButton.addTarget(self, action: #selector(didClickJoin(_:)), for: .touchUpInside)
    }

    @objc private func didClickJoin(_ sender: UIButton) {
        viewModel.joinMeeting()
    }

    static private func compareVCPreviewedParticipantSlice(lhs: VChatPreviewedParticipantSlice, rhs: VChatPreviewedParticipantSlice) -> Bool {
        return lhs.totalCount == rhs.totalCount && lhs.participants.elementsEqual(rhs.participants) { lhs, rhs in
            lhs.id == rhs.id && lhs.type == rhs.type && lhs.deviceId == rhs.deviceId
        }
    }

    private static func externalWidth(meetingTagText: String) -> CGFloat {
        let rect = NSString(string: meetingTagText)
            .boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: 18),
                          options: [.usesLineFragmentOrigin, .usesFontLeading],
                          attributes: [.font: UIFont.systemFont(ofSize: Layout.externalFontsize, weight: .medium)],
                          context: nil)
        return rect.width + Layout.externalMargin * 2
    }
}

extension VChatMeetingCardView: VChatMeetingCardParticipantsPreviewDelegate {
    func didTapVChatMeetingCardParticipantsPreview(_ participantsView: VChatMeetingCardParticipantsPreview) {
        didTapPreviewParticipants()
    }
}

extension VChatMeetingCardViewModelImpl {
    func calculateSize(maxWidth: CGFloat, topic: String?, meetNumber: String?, meetingTagType: MeetingTagType, meetingSource: VCMeetingSource, isShowHour: Bool, isWebinar: Bool?, joinedDeviceDesc: String?) -> CGSize {
        let topicWidth = calculateTopicWidth(width: maxWidth, isShowHour: isShowHour)
        let topicHeight = attributeHeight(attributeString: buideAttributeTitle(topic: topic, isEnded: nil, isWebinar: isWebinar, meetingTagType: meetingTagType, meetingSource: meetingSource).0, width: topicWidth)

        let numberHeight = calculateMeetNumberHeight(width: maxWidth, meetNumber: meetNumber)
        let joinedDeviceHeight = calculateJoinedDeviceHeight(width: maxWidth, deviceDesc: joinedDeviceDesc)

        var allHeight: CGFloat = Layout.topicTopMargin + CGFloat(topicHeight) + Layout.topicBottomMargin + Layout.meetingNumberTopMargin + numberHeight + Layout.participantsViewTopMargin + Layout.participantsViewHeight
            + (isWebinar == true ? Layout.joinButtonWebinarTopMargin : Layout.joinButtonTopMargin) + Layout.joinButtonHeight + Layout.joinButtonBottomMargin

        if joinedDeviceHeight > 0 {
            allHeight += Layout.joinedDeviceViewTopMargin + joinedDeviceHeight
        }

        if isWebinar == true {
            allHeight += Layout.infoLabelHeight + Layout.attendeesTopMargin
        }
        return CGSize(width: maxWidth, height: allHeight)
    }
}

private extension VChatMeetingCardViewModelImpl {

    typealias Layout = VChatMeetingCardView.Layout

    func formatMeetNumber(with meetNumber: String) -> String {
        if meetNumber.count == 9 {
            let s = meetNumber
            let index1 = s.index(s.startIndex, offsetBy: 3)
            let index2 = s.index(s.endIndex, offsetBy: -3)
            return "\(s[..<index1]) \(s[index1..<index2]) \(s[index2..<s.endIndex])"
        } else {
            return meetNumber
        }
    }

    func meetingNumberAttribute(number: String) -> NSAttributedString {
        let text = "\(I18n.Lark_View_MeetingIdColon)\(formatMeetNumber(with: number))"
        return .init(string: text, config: .bodyAssist, textColor: UIColor.ud.textTitle)
    }

    func calculateMeetNumberHeight(width: CGFloat, meetNumber: String?) -> CGFloat {
        guard let meetNumber = meetNumber else {
            return Layout.infoLabelHeight
        }
        let titleWidth = width - Layout.infoLeftMargin - Layout.numberImageSize - Layout.infoInnerMargin - Layout.infoRightMargin
        let attributeStr = meetingNumberAttribute(number: meetNumber)

        let maxSize = CGSize(width: titleWidth, height: CGFloat.greatestFiniteMagnitude)
        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let boundingRect = attributeStr.boundingRect(with: maxSize, options: options, context: nil)

        var height = Layout.infoLabelHeight
        if boundingRect.height > 21 {
            height = 40
        }
        return height
    }

    func joinedDeviceAttribute(deviceDesc: String) -> NSAttributedString {
        let config = VCFontConfig(fontSize: 14, lineHeight: 22, fontWeight: .regular)
        return .init(string: deviceDesc, config: config, lineBreakMode: .byCharWrapping)
    }

    func calculateJoinedDeviceHeight(width: CGFloat, deviceDesc: String?) -> CGFloat {
        guard let deviceDesc = deviceDesc else {
            return 0.0
        }
        let attributedStr = joinedDeviceAttribute(deviceDesc: deviceDesc)
        let titleWidth = width - Layout.infoLeftMargin - Layout.joinedDeviceImageSize - Layout.infoInnerMargin - Layout.infoRightMargin
        let maxSize = CGSize(width: titleWidth, height: CGFloat.greatestFiniteMagnitude)
        let boundingRect = attributedStr.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, context: nil)
        return boundingRect.height
    }

    func calculateTopicWidth(width: CGFloat, isShowHour: Bool) -> CGFloat {
        let titleWidth = width - Layout.imageLeftMargin - Layout.imageViewSize - Layout.topicLeftRightMargin * 2 - (isShowHour ? Layout.timeLongWidth : Layout.timeShortWidth) - Layout.timeRightMargin
        return titleWidth
    }

    func externalWidth(meetingTagText: String) -> CGFloat {
        let rect = NSString(string: meetingTagText)
            .boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: 18),
                          options: [.usesLineFragmentOrigin, .usesFontLeading],
                          attributes: [.font: UIFont.systemFont(ofSize: Layout.externalFontsize, weight: .medium)],
                          context: nil)
        return rect.width + Layout.externalMargin * 2
    }

    func buideTagView(meetingTagText: String, textColor: UIColor, backgroundColor: UIColor) -> PaddingLabel {
        let tagLabel = PaddingLabel()
        tagLabel.text = meetingTagText
        tagLabel.textAlignment = .center
        tagLabel.textInsets = UIEdgeInsets(top: 0.0, left: Layout.externalMargin, bottom: 0.0, right: Layout.externalMargin)
        tagLabel.font = .systemFont(ofSize: Layout.externalFontsize, weight: .medium)
        tagLabel.textColor = textColor
        tagLabel.backgroundColor = backgroundColor
        tagLabel.layer.cornerRadius = 4
        tagLabel.layer.masksToBounds = true
        return tagLabel
    }

    func buideAttributeTitle(topic: String?,
                             isEnded: Bool?,   // ig不同状态颜色不同，Aurora统一，防止以后还有，暂时保留
                             isWebinar: Bool?,
                             meetingTagType: MeetingTagType,
                             meetingSource: VCMeetingSource?) -> (NSMutableAttributedString, NSMutableAttributedString) {
        guard let topic = topic, let meetingSource = meetingSource else {
            return (NSMutableAttributedString(), NSMutableAttributedString())
        }

        var displayTopic = meetingSource == .cardFromInterview ? I18n.Lark_View_VideoInterviewNameBraces(topic) : topic
        if displayTopic.isEmpty {
            displayTopic = I18n.Lark_View_ServerNoTitle
        }

        let textColor = (isEnded == true ? UIColor.ud.textPlaceholder : UIColor.ud.textTitle)  // title颜色
        let tagTextColor = UIColor.ud.udtokenTagTextSBlue   // tag title颜色
        let tagBGColor = UIColor.ud.udtokenTagBgBlue   // tag 背景颜色

        let font = UIFont.systemFont(ofSize: 16, weight: .medium)
        let attributedString = NSMutableAttributedString(string: displayTopic)

        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 20.0
        style.maximumLineHeight = 20.0
        style.lineSpacing = 0
        style.paragraphSpacing = 0
        style.paragraphSpacingBefore = 0
//        let titleBaselineOffset = (20.0 - font.lineHeight) / 4.0 , .baselineOffset: titleBaselineOffset

        attributedString.addAttributes([.foregroundColor: textColor, .font: font, .paragraphStyle: style], range: NSRange(location: 0, length: NSString(format: "%@", displayTopic).length)) // 不用displayTopic.count 是因为有emoji的时候count不准
        let outOfRangeText = NSMutableAttributedString(string: "...", attributes: [.foregroundColor: textColor,
                                                                                   .font: font,
                                                                                   .backgroundColor: UIColor.clear])

        let showWebinarTag = isWebinar ?? false
        if showWebinarTag {
            let webinarTagText = I18n.View_G_Webinar
            let tagWidth = externalWidth(meetingTagText: webinarTagText)
            let attachment = LKAsyncAttachment(viewProvider: {
                self.buideTagView(meetingTagText: webinarTagText, textColor: tagTextColor, backgroundColor: tagBGColor)
            }, size: CGSize(width: tagWidth, height: 18))
            attachment.verticalAlignment = .middle
            attachment.fontAscent = font.ascender
            attachment.fontDescent = font.descender
            attachment.margin = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)  // 1.4是lklabel有个坑，middle不在居中，top不置顶，且不再维护
            let tagAttr = NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                             attributes: [LKAttachmentAttributeName: attachment])
            attributedString.append(tagAttr)
            outOfRangeText.append(tagAttr)
        }
        if let tagText = meetingTagType.text {
            let tagWidth = externalWidth(meetingTagText: tagText)
            let tagAttachment = LKAsyncAttachment(viewProvider: {
                return self.buideTagView(meetingTagText: tagText, textColor: tagTextColor, backgroundColor: tagBGColor)
            }, size: CGSize(width: tagWidth, height: 18))
            tagAttachment.verticalAlignment = .middle
            tagAttachment.fontAscent = font.ascender
            tagAttachment.fontDescent = font.descender
            tagAttachment.margin = UIEdgeInsets(top: 0, left: showWebinarTag ? 4 : 6, bottom: 0, right: 0)
            let tagAttr = NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                             attributes: [LKAttachmentAttributeName: tagAttachment])
            attributedString.append(tagAttr)
            outOfRangeText.append(tagAttr)
        }

        return (attributedString, outOfRangeText)
    }

    func attributeHeight(attributeString: NSAttributedString, width: CGFloat) -> Int {
        let textParser = LKTextParserImpl()
        textParser.originAttrString = attributeString
        textParser.parse()
        let layoutEngine = LKTextLayoutEngineImpl()
        layoutEngine.attributedText = textParser.renderAttrString
        layoutEngine.preferMaxWidth = width
        let topicSize = layoutEngine.layout(size: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))

        var topicHeight = 22
        // Todo 临时方案，等主端结论
        if topicSize.height > 29 {
            if let fg = try? userResolver.resolve(assert: FeatureGatingService.self),
               fg.staticFeatureGatingValue(with: "core.font.check_font_swizzle") {
                topicHeight = 46
            } else {
                topicHeight = 44
            }
        }
        return topicHeight
    }
}

private extension UIImage {
    /// 图片大小跟随当前字体大小变化
    var autoSize: UIImage {
        let originSize: CGFloat = 14.0
        let rect = CGRect(origin: .zero, size: CGSize(width: originSize.roundAuto(), height: originSize.roundAuto()))
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let render = UIGraphicsImageRenderer(bounds: rect, format: format)
        let newImage = render.image { _ in
            self.draw(in: CGRect(x: 0, y: 0, width: originSize.roundAuto(), height: originSize.roundAuto()))
        }
        return newImage
    }
}

private extension CGFloat {
    func roundAuto() -> CGFloat {
        let currentScale = UDZoom.currentZoom.scale
        return (self * currentScale).rounded()
    }
}

private extension UIButton {
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        setBackgroundImage(UIImage.ud.fromPureColor(color), for: state)
    }
}

private class PaddingLabel: UILabel {
    var textInsets: UIEdgeInsets = .zero
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right, height: size.height + textInsets.top + textInsets.bottom)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
}
