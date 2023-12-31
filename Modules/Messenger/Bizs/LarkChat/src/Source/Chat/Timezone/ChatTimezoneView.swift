//
//  ChatTimezoneView.swift
//  LarkChat
//
//  Created by 赵家琛 on 2020/2/6.
//

import UIKit
import Foundation
import LarkSDKInterface

final class ChatTimezoneView: TimeZoneView {
    weak var targetVC: UIViewController?

    private let tipLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.ud.bgBody
        let timezoneImageView = UIImageView(image: Resources.timezone)
        self.addSubview(timezoneImageView)
        timezoneImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        self.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(38)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
            make.right.equalToSuperview().inset(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 接口兼容，只会使用chatTimezoneDesc
    func updateTipContent(chatTimezoneDesc: String,
                          chatTimezone: String,
                          myTimezone: String,
                          myTimezoneType: ExternalDisplayTimezoneSettingType,
                          preferredMaxLayoutWidth: CGFloat) {
        let text = chatTimezoneDesc
        guard !text.isEmpty else {
            self.tipLabel.attributedText = nil
            return
        }

        let mutableAttrText: NSMutableAttributedString = NSMutableAttributedString(string: "")
        let frontText = text.components(separatedBy: "{ ").first ?? ""
        guard let partText = text.components(separatedBy: "{ ").last else {
            return
        }
        let timeText = partText.components(separatedBy: " }").first ?? ""
        let rearText = partText.components(separatedBy: " }").last ?? ""
        mutableAttrText.append(
            NSAttributedString(string: frontText,
                               attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0),
                                            NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder]
            )
        )
        mutableAttrText.append(
            NSAttributedString(string: timeText,
                               attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .medium),
                                            NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder]
            )
        )
        mutableAttrText.append(
            NSAttributedString(string: rearText,
                               attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0),
                                            NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder]
            )
        )
        self.tipLabel.attributedText = mutableAttrText
    }
}
