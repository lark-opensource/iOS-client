//
//  UrgentChatterCollectionHeader.swift
//  LarkUrgent
//
//  Created by JackZhao on 2022/1/10.
//

import Foundation
import UIKit

final class UrgentChatterCollectionHeader: UICollectionReusableView {

    private var lineView: UIView = UIView()

    private var label: UILabel = UILabel()
    private var alertIcon: UIImageView = UIImageView()
    private var alertLabel: UILabel = UILabel()
    static let alertLabelFont = UIFont.systemFont(ofSize: 14)
    static let labelHeight: CGFloat = 22
    static let labelTopPadding: CGFloat = 20
    static let alertLabelTopPadding: CGFloat = 20
    static let lineTopPadding: CGFloat = 20

    override init(frame: CGRect) {
        super.init(frame: .zero)

        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        self.addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview()
            make.top.equalTo(0)
            make.height.equalTo(0.5)
        }

        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle

        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.height.equalTo(22)
            make.top.equalTo(lineView.snp.bottom).offset(16)
        }

        self.addSubview(self.alertIcon)
        self.addSubview(self.alertLabel)
        alertIcon.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16)
            maker.width.height.equalTo(14.5)
            maker.top.equalTo(label.snp.bottom).offset(21)
        }
        alertIcon.image = Resources.urgentAlert

        alertLabel.font = UIFont.systemFont(ofSize: 14)
        alertLabel.textColor = UIColor.ud.textPlaceholder
        alertLabel.numberOfLines = 0
        alertLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(alertIcon.snp.right).offset(8)
            maker.right.equalTo(-16)
            maker.top.equalTo(label.snp.bottom).offset(20)
        }
    }

    func setContent(text: String? = nil,
                    alertText: String? = nil,
                    isShowTopLine: Bool = false) {
        lineView.isHidden = !isShowTopLine
        lineView.snp.updateConstraints { make in
            make.top.equalTo(isShowTopLine ? Self.lineTopPadding : 0)
        }
        if text?.isEmpty == false {
            label.text = text
            label.isHidden = false
            label.snp.updateConstraints { make in
                make.height.equalTo(Self.labelHeight)
                make.top.equalTo(lineView.snp.bottom).offset(Self.labelTopPadding)
            }
        } else {
            label.isHidden = true
            label.snp.updateConstraints { make in
                make.height.equalTo(0)
                make.top.equalTo(lineView.snp.bottom).offset(0)
            }
        }
        if alertText?.isEmpty == false {
            self.alertLabel.isHidden = false
            self.alertIcon.isHidden = false
            alertLabel.text = alertText
            alertLabel.snp.updateConstraints { make in
                make.top.equalTo(label.snp.bottom).offset(Self.alertLabelTopPadding)
            }
        } else {
            self.alertLabel.isHidden = true
            self.alertIcon.isHidden = true
            alertLabel.snp.updateConstraints { make in
                make.top.equalTo(label.snp.bottom).offset(0)
            }
        }
        lineView.isHidden = !isShowTopLine
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
