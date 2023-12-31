//
//  PreviewTopicHeaderView.swift
//  ByteView
//
//  Created by kiri on 2022/5/19.
//

import Foundation
import UIKit
import ByteViewCommon
import ByteViewNetwork

protocol PreviewTopicHeaderViewDelegate: AnyObject {
    func didTapParticipantsInHeaderView(_ view: PreviewTopicHeaderView)
    func didRefreshLayout()
}

/// 会议话题头部区域，topic | participants
final class PreviewTopicHeaderView: PreviewChildView {

    let isLeftToRight: Bool
    let isEditable: Bool
    private let isWebinar: Bool
    private let isJoiningMeeting: Bool
    weak var delegate: PreviewTopicHeaderViewDelegate?

    var textField: PreviewTextField { textView.textField }

    /// 加入已有会议（除number入会）的Topic主题View
    private(set) lazy var topicView: RichTopicView = {
        let config: RichTopicConfig = RichTopicConfig()
        let view = RichTopicView(config: config)
        return view
    }()

    private(set) lazy var textView: PreviewMeetingTextView = {
        let textView = PreviewMeetingTextView()
        return textView
    }()

    private(set) lazy var participantsView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 20
        view.addSubview(participantsTileView)
        participantsTileView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview()
        }
        return view
    }()

    private lazy var participantsTileView: ParticipantsTileView = {
        let view = ParticipantsTileView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()

    var participants: [PreviewParticipant] {
        get { isEditable ? [] : participantsTileView.participants }
        set {
            if !isEditable {
                updateParticipants(participants: newValue)
            }
        }
    }

    init(isLeftToRight: Bool, isEditable: Bool, topic: String, isWebinar: Bool, isJoiningMeeting: Bool) {
        self.isLeftToRight = isLeftToRight
        self.isEditable = isEditable
        self.isWebinar = isWebinar
        self.isJoiningMeeting = isJoiningMeeting
        super.init(frame: .zero)
        setupLayout(topic: topic)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTopicHeight(bounds.width)
        delegate?.didRefreshLayout()
    }

    private func setupLayout(topic: String) {
        let hasParticipantView = !isEditable
        if isEditable {
            addSubview(textView)
            textField.placeHolderLabel.lineBreakMode = isLeftToRight ? .byTruncatingHead : .byTruncatingTail
            textField.underlineColor = isEditable ? UIColor.ud.lineBorderComponent : UIColor.clear
            textField.isEnabled = isEditable
            textField.accessibilityIdentifier = "PreviewMeetingViewController.textView.textField.accessibilityIdentifier"

            textView.snp.makeConstraints { make in
                make.top.centerX.equalToSuperview()
                make.width.greaterThanOrEqualTo(self.placeholderWidth(topic: topic))
                make.width.lessThanOrEqualToSuperview()
                make.height.equalTo(52)
                if !hasParticipantView {
                    make.bottom.equalToSuperview()
                }
            }
        } else {
            addSubview(topicView)
            addSubview(participantsView)
            topicView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.left.right.equalToSuperview()
            }
            participantsView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.lessThanOrEqualToSuperview()
                make.top.equalTo(topicView.snp.bottom).offset(10)
                make.height.equalTo(0)
                make.bottom.equalToSuperview()
            }

            participantsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapParticipants(_:))))
        }
    }

    func setBorderColor(_ color: UIColor) {
        textView.layer.ud.setBorderColor(color)
    }

    private func updateTopicHeight(_ width: CGFloat) {
        if !isEditable {
            topicView.updateHeight(with: getTopicHeight(width: width))
        }
    }

    private func updateParticipants(participants: [PreviewParticipant]) {
        participantsTileView.participants = participants
        let isEmpty = participants.isEmpty
        participantsView.snp.updateConstraints { make in
            make.top.equalTo(topicView.snp.bottom).offset(isEmpty ? 0 : 10)
            make.height.equalTo(isEmpty ? 0 : 40)
        }
    }

    private func placeholderWidth(topic: String) -> CGFloat {
        let font = UIFont.boldSystemFont(ofSize: 24)
        let topicWidth = topic.vc.boundingWidth(height: 32, font: font)
        let width = topicWidth + (isEditable ? 32 : 0)
        return width
    }

    private func getTopicHeight(width: CGFloat) -> CGFloat {
        let lineHeight = topicView.config.titleStyle.lineHeight
        let maxlineHeight = isJoiningMeeting ? 2.0 * lineHeight : 3 * lineHeight
        let height = topicView.getTitleHeight(width: width)
        return height >= maxlineHeight ? maxlineHeight : height
    }

    @objc private func didTapParticipants(_ sender: UITapGestureRecognizer) {
        delegate?.didTapParticipantsInHeaderView(self)
    }
}
