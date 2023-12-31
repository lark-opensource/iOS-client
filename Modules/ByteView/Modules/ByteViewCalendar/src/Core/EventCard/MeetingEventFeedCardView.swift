//
//  MeetingEventFeedCardView.swift
//  ByteViewCalendar
//
//  Created by lutingting on 2023/8/2.
//

import Foundation
import RxSwift
import RxCocoa
import CalendarFoundation
import UniverseDesignIcon
import UniverseDesignFont
import ByteViewUI
import ByteViewCommon

final class MeetingEventFeedCardView: UIView, EventFeedCardView {

    let identifier: String = String(describing: type(of: MeetingEventFeedCardView.self))
    private var topicLabelWidth: CGFloat = 0.0
    private let timerDisposeBag: DisposeBag = DisposeBag()
    var refreshView: (() -> Void)?

    private lazy var iconView: UIView = {
        let view = UIView()
        let icon = UDIcon.getIconByKey(.videoFilled, iconColor: .ud.staticWhite, size: CGSize(width: 12, height: 12))
        view.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.05)
        view.layer.cornerRadius = 12
        let imageV = UIImageView(image: icon)

        let iconBG = UIView()
        iconBG.backgroundColor = UIColor.ud.colorfulGreen
        iconBG.layer.cornerRadius = 10

        let label = UILabel()
        label.text = I18n.Lark_FeedEbent_VideoMeeting_Label
        label.textColor = .ud.textCaption
        label.font = .systemFont(ofSize: 12)

        view.addSubview(iconBG)
        view.addSubview(label)
        iconBG.addSubview(imageV)
        imageV.snp.makeConstraints { make in
            make.size.equalTo(12)
            make.center.equalToSuperview()
        }
        iconBG.snp.makeConstraints { make in
            make.size.equalTo(20)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(2)
        }
        label.snp.makeConstraints { make in
            make.left.equalTo(iconBG.snp.right).offset(4)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(8)
        }
        return view
    }()


    private lazy var topicLabel: RichTopicView = {
        let config = RichTopicConfig()
        let view = RichTopicView(config: config)
        view.titleLabel.textColor = .ud.textTitle
        return view
    }()

    private lazy var descView: UIView = {
        let view = UIView()
        view.addSubview(timeLabel)
        view.addSubview(separatedLine)
        view.addSubview(meetingIDLabel)

        timeLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
        }
        separatedLine.snp.makeConstraints { make in
            make.left.equalTo(timeLabel.snp.right).offset(4)
            make.centerY.equalToSuperview()
            make.height.equalTo(12)
            make.width.equalTo(1)
        }
        meetingIDLabel.snp.makeConstraints { make in
            make.left.equalTo(separatedLine.snp.right).offset(4)
            make.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        return view
    }()

    private lazy var statusLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.text = I18n.Lark_Event_EventInProgress_Status
        label.textColor = .ud.udtokenTagTextSGreen
        label.backgroundColor = .ud.udtokenTagBgGreen.withAlphaComponent(0.2)
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.textInsets = .init(top: 0, left: 4, bottom: 0, right: 4)
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let timeLabel = UILabel(frame: CGRect.zero)
        timeLabel.font = UDFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        timeLabel.textColor = .ud.textTitle
        return timeLabel
    }()

    private lazy var separatedLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var meetingIDLabel: UILabel = {
        let meetingIDLabel = UILabel()
        meetingIDLabel.font = .systemFont(ofSize: 14)
        meetingIDLabel.textColor = .ud.textTitle
        return meetingIDLabel
    }()

    private lazy var joinButton: UIButton = {
        let button = VisualButton()
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 1
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitle(I18n.Calendar_VideoMeeting_JoinVideoMeeting, for: .normal)
        button.setTitleColor(.ud.functionSuccessContentDefault, for: .normal)
        button.setTitleColor(.ud.functionSuccessContentPressed, for: .highlighted)
        button.setBorderColor(.ud.functionSuccessContentDefault, for: .normal)
        button.setBorderColor(.ud.functionSuccessContentPressed, for: .highlighted)
        button.addTarget(self, action: #selector(joinMeeting), for: .touchUpInside)
        button.contentEdgeInsets = .init(top: 8, left: 16, bottom: 8, right: 16)
        button.addInteraction(type: .lift)
        return button
    }()

    var cardViewModel: MeetingEventFeedCardViewModel
    var model: EventFeedCardModel

    init(model: MeetingEventFeedCardViewModel) {
        self.cardViewModel = model
        self.model = model
        super.init(frame: .zero)
        setupView()
        bindData()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width - 32
        guard topicLabelWidth != width else { return }
        topicLabelWidth = width
        topicLabel.updateHeight(with: width)
        refreshView?()
    }

    private func setupView() {
        addSubview(iconView)
        addSubview(statusLabel)
        addSubview(topicLabel)
        addSubview(descView)
        addSubview(joinButton)
        iconView.snp.makeConstraints { make in
            make.top.left.equalToSuperview().inset(16)
            make.height.equalTo(24)
        }
        statusLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.height.equalTo(18)
            make.centerY.equalTo(iconView)
        }
        topicLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView)
            make.top.equalTo(iconView.snp.bottom).offset(12)
            make.right.lessThanOrEqualToSuperview().inset(16)
        }
        descView.snp.makeConstraints { make in
            make.left.equalTo(iconView)
            make.top.equalTo(topicLabel.snp.bottom).offset(4)
            make.height.equalTo(22)
        }
        joinButton.snp.makeConstraints { make in
            make.left.equalTo(iconView)
            make.top.equalTo(descView.snp.bottom).offset(14)
            make.height.equalTo(36)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    private func bindData() {
        meetingIDLabel.text = cardViewModel.meetingNumber
        setExternalTag(cardViewModel.meetingTagType)
        cardViewModel.updateTagClosure = { [weak self] tagType in
            self?.setExternalTag(tagType)
        }
        cardViewModel.timingDriver
            .drive(timeLabel.rx.text)
            .disposed(by: timerDisposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setExternalTag(_ meetingTagType: MeetingTagType) {
        Util.runInMainThread {
            switch meetingTagType {
            case .external, .cross, .partner:
                self.topicLabel.externalText = meetingTagType.text ?? I18n.View_G_ExternalLabel
            case .none:
                self.topicLabel.externalText = ""
            }
            self.topicLabel.updateTitle(self.cardViewModel.topic, isExternal: meetingTagType != .none, isWebinar: self.cardViewModel.isWebinar)
        }
    }

    @objc
    func joinMeeting() {
        cardViewModel.joinMeeting()
    }
}
