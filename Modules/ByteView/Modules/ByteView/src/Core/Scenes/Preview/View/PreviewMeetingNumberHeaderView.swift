//
//  PreviewTextInputHeaderView.swift
//  ByteView
//
//  Created by kiri on 2022/5/19.
//

import Foundation
import UIKit
import UniverseDesignColor

/// 会议号头部区域，meetingNumberTitle | errorLabel | meetingNumberTextField
final class PreviewMeetingNumberHeaderView: PreviewChildView {

    private(set) lazy var textField: MeetingNumberField = {
        let field = MeetingNumberField(groupWidth: [3], groupKern: 10, maxLength: 9)
        field.underlineColor = UIColor.ud.lineBorderComponent
        field.placeholder = I18n.View_G_SAMeetingIDDetails
        return field
    }()

    private(set) lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.accessibilityLabel = "errorLabel"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = UIColor.ud.functionDangerContentDefault
        label.text = I18n.View_M_InvalidMeetingId
        label.isHidden = true
        return label
    }()

    private var textFieldWidth: CGFloat {
        let width = I18n.View_G_SAMeetingIDDetails.vc.boundingWidth(height: 32, font: UIFont.boldSystemFont(ofSize: 24)) + 32
        return width > 200 ? width : 200
    }

    init() {
        super.init(frame: .zero)
        addSubview(textField)
        addSubview(errorLabel)
        errorLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.height.equalTo(20)
        }
        textField.snp.makeConstraints { (make) in
            make.centerX.top.bottom.equalToSuperview()
            make.top.equalTo(errorLabel.snp.bottom).offset(-4)
            make.height.equalTo(52)
            make.width.equalTo(textFieldWidth)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
