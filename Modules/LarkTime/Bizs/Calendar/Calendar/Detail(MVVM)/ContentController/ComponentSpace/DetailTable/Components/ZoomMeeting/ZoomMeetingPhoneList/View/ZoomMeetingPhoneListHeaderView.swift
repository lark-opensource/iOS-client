//
//  ZoomMeetingPhoneListHeaderView.swift
//  Calendar
//
//  Created by pluto on 2022/11/10.
//

import UIKit
import Foundation
import UniverseDesignColor

final class ZoomMeetingPhoneListHeaderView: UIView {

    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.text = I18n.Calendar_Edit_DialInSubtitle
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var meetingIDLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var passwordLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineBorderCard
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutInfoLabel()
        layoutmeetingIDLabel()
        layoutPasswordLabel()
        layoutBotomline()
    }

    func layoutInfoLabel() {
        addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
    }

    func layoutmeetingIDLabel () {
        addSubview(meetingIDLabel)
        meetingIDLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(22)
            make.top.equalTo(infoLabel.snp.bottom).offset(12.0)
        }
    }

    func layoutPasswordLabel() {
        addSubview(passwordLabel)
        passwordLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(22)
            make.top.equalTo(meetingIDLabel.snp.bottom).offset(2.0)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    func layoutBotomline() {
        addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configHeaderInfo(meetingID: String, password: String) {
        meetingIDLabel.text = I18n.Calendar_Zoom_MeetIDWith + meetingID
        passwordLabel.snp.updateConstraints { $0.height.equalTo(password.isEmpty ? 0 : 22) }
        passwordLabel.text = I18n.Calendar_Zoom_MeetPasscode + password
    }
}
