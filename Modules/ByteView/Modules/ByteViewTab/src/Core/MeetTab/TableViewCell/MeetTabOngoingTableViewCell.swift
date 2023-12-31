//
//  MeetTabOngoingTableViewCell.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SnapKit
import NSObject_Rx
import UniverseDesignIcon
import UniverseDesignTheme
import ByteViewCommon
import ByteViewUI
import UniverseDesignToast

class MeetTabOngoingTableViewCell: MeetTabBaseTableViewCell {

    private var timerDisposeBag: DisposeBag = DisposeBag()

    lazy var recordingIcon = UIImageView(image: UDIcon.getIconByKey(.videoFilled, iconColor: .ud.colorfulBlue.dynamicColor, size: CGSize(width: 14, height: 14)))
    lazy var larkMinutesIcon = UIImageView(image: UDIcon.getIconByKey(.minutesLogoFilled, iconColor: .ud.vcTokenMeetingIconMinutes, size: CGSize(width: 14, height: 14)))
    lazy var docIcon = UIImageView(image: UDIcon.getIconByKey(.spaceFilled, iconColor: .ud.colorfulBlue.dynamicColor, size: CGSize(width: 14, height: 14)))
    lazy var linkIcon = UIImageView(image: UDIcon.getIconByKey(.likeFilled, iconColor: .ud.colorfulBlue.dynamicColor, size: CGSize(width: 14, height: 14)))

    lazy var iconStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [recordingIcon, larkMinutesIcon, docIcon, linkIcon])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 6
        return stackView
    }()

    lazy var meetingIDLabel: CopyableLabel = {
        let meetingIDLabel = CopyableLabel()
        meetingIDLabel.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        meetingIDLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 500.0), for: .horizontal)
        meetingIDLabel.copyTitle = I18n.View_MV_CopyMeetingID
        meetingIDLabel.completeTitle = I18n.View_MV_MeetingIDCopied
        meetingIDLabel.addInteraction(type: .hover)
        meetingIDLabel.layer.cornerRadius = 2.0
        meetingIDLabel.clipsToBounds = true
        meetingIDLabel.delegate = self
        return meetingIDLabel
    }()

    lazy var joinedDeviceView: JoinedDeviceView = JoinedDeviceView(isRegular: isRegular)

    lazy var joinButton: VisualButton = {
        let joinButton = VisualButton(type: .custom)
        joinButton.layer.borderWidth = 1.0
        joinButton.layer.cornerRadius = 6.0
        joinButton.setBorderColor(.ud.functionSuccessContentDefault, for: .normal)
        joinButton.setBorderColor(.ud.functionSuccessContentDefault, for: .highlighted)
        joinButton.setBorderColor(.ud.lineBorderComponent, for: .disabled)
        joinButton.setBackgroundColor(.ud.udtokenComponentOutlinedBg, for: .normal)
        joinButton.setBackgroundColor(.ud.G200.dynamicColor, for: .highlighted)
        joinButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        joinButton.setContentHuggingPriority(.required, for: .horizontal)
        joinButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        joinButton.clipsToBounds = true
        joinButton.addInteraction(type: .lift)
        return joinButton
    }()

    var timeLabelWidthConstraint: Constraint?
    var iconLinedView: UIView?

    var isRegular: Bool {
        MeetTabTraitCollectionManager.shared.isRegular
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        timeLabel.snp.makeConstraints {
            timeLabelWidthConstraint = $0.width.equalTo(0.0).constraint
        }

        contentStackView.addArrangedSubview(joinButton)
        joinButton.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(60.0)
            $0.height.equalTo(28.0)
        }

        containerView.clipsToBounds = true
        descStackView.snp.remakeConstraints {
            $0.left.equalTo(titleStackView)
            descStackViewTopConstaint = $0.top.equalTo(titleStackView.snp.bottom).offset(4.0).priority(.low).constraint
            $0.height.equalTo(20.0).priority(.low)
            $0.bottom.equalTo(extStackView.snp.top)
            // 与BaseCell异化的部分
            $0.right.lessThanOrEqualToSuperview().priority(.medium)
            $0.bottom.equalToSuperview().priority(.low)
        }
        descStackView.addSeparatedSubview(meetingIDLabel)

        if isRegular {
            descStackView.addSeparatedSubview(joinedDeviceView)
        } else {
            containerView.addSubview(joinedDeviceView)
            joinedDeviceView.snp.makeConstraints { make in
                make.top.equalTo(descStackView.snp.bottom).offset(4)
                make.bottom.equalToSuperview()
                make.left.equalTo(descStackView)
                make.right.lessThanOrEqualToSuperview()
            }
        }

        iconLinedView = descStackView.addSeparatedSubview(iconStackView)
        iconLinedView?.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
        }
        [recordingIcon, larkMinutesIcon, docIcon, linkIcon].forEach {
            $0.snp.makeConstraints { (make) in
                make.width.height.equalTo(14)
            }
        }

        if isRegular {
            descStackViewTopConstaint?.update(offset: 2.0)
        } else {
            descStackViewTopConstaint?.update(offset: 4.0)
        }
    }

    override func bindTo(viewModel: MeetTabCellViewModel) {
        guard let viewModel = viewModel as? MeetTabOngoingCellViewModel else {
            return
        }
        self.viewModel = viewModel

        iconView.config(icon: viewModel.isWebinar ? .webinarFilled : .videoFilled,
                        iconColor: UIColor.ud.functionSuccessFillDefault,
                        iconColorHighlighted: UIColor.ud.functionSuccessFillDefault,
                        backgroundViewColor: UIColor.ud.functionSuccessFillSolid02,
                        backgroundViewColorHighlighted: UIColor.ud.functionSuccessFillSolid02)


//      同步LM合DM
        if #available(iOS 13.0, *) {
            let correctStyle = UDThemeManager.userInterfaceStyle
            let correctTraitCollection = UITraitCollection(userInterfaceStyle: correctStyle)
            UITraitCollection.current = correctTraitCollection
        }

        var callCount: NSAttributedString?
        if viewModel.isAggregated {
            callCount = .init(string: viewModel.callCountText, config: .body, textColor: viewModel.topicColor)
        }
        let topic = NSAttributedString(string: viewModel.topic, config: .body, lineBreakMode: .byTruncatingTail, textColor: viewModel.topicColor)
        configTitle(topic: topic,
                    callCount: callCount,
                    tagType: viewModel.meetingTagType,
                    webinarMeeting: viewModel.isWebinar)

        disposeBag = DisposeBag()
        viewModel.meetingTagTypeRelay.asObservable()
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] tagType in
                self?.configTitle(topic: topic,
                                  callCount: callCount,
                                  tagType: tagType,
                                  webinarMeeting: viewModel.isWebinar)
            })
            .disposed(by: disposeBag)

        timerDisposeBag = DisposeBag()
        let isRegular = isRegular
        let config: VCFontConfig = isRegular ? .tinyAssist : .bodyAssist
        let textColor: UIColor = isRegular ? .ud.textCaption : .ud.textPlaceholder
        viewModel.timingDriver
            .map { .init(string: $0, config: config, textColor: textColor) }
            .drive(timeLabel.rx.attributedText)
            .disposed(by: timerDisposeBag)
        meetingIDLabel.attributedText = .init(string: viewModel.meetingNumber, config: config, textColor: textColor)
        viewModel.timingDriver
            .map { $0.count <= 5 ? (isRegular ? 36 : 40.0) : (isRegular ? 53 : 62.0) }
            .distinctUntilChanged()
            .drive(onNext: { [weak self] in
                self?.timeLabelWidthConstraint?.update(offset: $0)
            }).disposed(by: timerDisposeBag)
        meetingIDLabel.tapGesture.isEnabled = isRegular

        descStackView.removeSeparatedSubview(joinedDeviceView)
        joinedDeviceView.removeFromSuperview()
        if !viewModel.joinedDeviceNames.isEmpty {
            if isRegular {
                if let index = descStackView.separatedSubviews.firstIndex(where: { $0 == iconStackView }) {
                    descStackView.insertSeparatedSubview(joinedDeviceView, at: index)
                } else {
                    descStackView.addSeparatedSubview(joinedDeviceView)
                }
            } else {
                containerView.addSubview(joinedDeviceView)
                joinedDeviceView.snp.makeConstraints { make in
                    make.top.equalTo(descStackView.snp.bottom).offset(4)
                    make.bottom.equalToSuperview()
                    make.left.equalTo(descStackView)
                    make.right.lessThanOrEqualToSuperview()
                }
                // extStackView不会展示，但是Constraints会影响cell的高度计算
                extStackView.snp.removeConstraints()
            }
            joinedDeviceView.updateLayout(isRegular: isRegular)
            joinedDeviceView.updateDeviceNames(viewModel.joinedDeviceNames)
        }

        viewModel.joinButtonTitleDriver.drive(onNext: { [weak self] title in
            self?.joinButton.setAttributedTitle(.init(string: title,
                                                      config: .bodyAssist,
                                                      textColor: .ud.functionSuccessContentDefault), for: .normal)
            self?.joinButton.setAttributedTitle(.init(string: title,
                                                      config: .bodyAssist,
                                                      textColor: .ud.functionSuccessContentDefault), for: .highlighted)
            self?.joinButton.setAttributedTitle(.init(string: title,
                                                      config: .bodyAssist,
                                                      textColor: .ud.textDisabled), for: .disabled)
        }).disposed(by: rx.disposeBag)
        joinButton.rx.action = viewModel.getJoinAction(from: self.currentViewController() ?? UIViewController())
        let isRecordingHidden = viewModel.isIconHidden(with: .record)
        let isLarkMinutesHidden = viewModel.isIconHidden(with: .larkMinutes)
        let isDocHidden = viewModel.isIconHidden(with: .msCcm) && viewModel.isIconHidden(with: .notes)
        let isLinkHidden = viewModel.isIconHidden(with: .msURL)

        recordingIcon.isHidden = isRecordingHidden
        larkMinutesIcon.isHidden = isLarkMinutesHidden
        docIcon.isHidden = isDocHidden
        linkIcon.isHidden = isLinkHidden
        let isIconViewHidden = isRecordingHidden && isLarkMinutesHidden && isDocHidden && isLinkHidden
        descStackView.setSubviewHidden(for: iconLinedView, hidden: isIconViewHidden)

        updateLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        timerDisposeBag = DisposeBag()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !self.isHidden else { return super.hitTest(point, with: event) }
        let labelPoint = meetingIDLabel.convert(point, from: self)
        if meetingIDLabel.point(inside: labelPoint, with: event) {
            return meetingIDLabel
        }
        let buttonPoint = joinButton.convert(point, from: self)
        if joinButton.isInside(buttonPoint) {
            return joinButton
        }
        return super.hitTest(point, with: event)
    }
}

extension MeetTabOngoingTableViewCell: CopyableLabelDelegate {
    func labelTextDidCopied(_ label: CopyableLabel) {
        guard let viewModel = viewModel as? MeetTabOngoingCellViewModel else {
            return
        }
        if let text = label.text, viewModel.viewModel.setPasteboardText(text, token: .tabListMeetingId),
           let view = label.window {
            let config = UDToastConfig(toastType: .success, text: label.completeTitle, operation: nil)
            UDToast.showToast(with: config, on: view)
        }
        MeetTabTracks.trackMeetTabOperation(.clickOngoingCopy, with: ["conference_id": viewModel.vcInfo.meetingID])
    }
}
