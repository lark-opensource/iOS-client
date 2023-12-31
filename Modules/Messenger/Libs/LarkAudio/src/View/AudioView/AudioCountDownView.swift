//
//  AudioCountDownView.swift
//  LarkAudio
//
//  Created by 李晨 on 2020/4/7.
//

import Foundation
import UIKit
import SnapKit

final class AudioCountDownView: UIView {

    let countDownLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "DINAlternate-Bold", size: 58)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .center
        return label
    }()

    let alertLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = BundleI18n.LarkAudio.Lark_Chat_AudioRecordTimeLimit
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .center
        return label
    }()

    init() {
        super.init(frame: .zero)
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        self.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.7)
        self.addSubview(self.countDownLabel)
        self.addSubview(self.alertLabel)

        alertLabel.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(12)
        }

        countDownLabel.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(alertLabel.snp.bottom).offset(2)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateCountDownTime(time: TimeInterval) {
        self.countDownLabel.text = "\(Int(time))"
    }
}
