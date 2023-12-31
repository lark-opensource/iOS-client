//
//  VideoTimeView.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/5/30.
//

import Foundation
import UIKit

public final class VideoTimeView: UIView {
    private let videoIcon = UIImageView()
    private let timeLabel = UILabel()

    public init() {
        super.init(frame: .zero)

        self.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.7)
        self.layer.cornerRadius = 4

        videoIcon.image = Resources.small_video_icon
        self.addSubview(videoIcon)
        videoIcon.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(4)
            maker.width.height.equalTo(12)
        }

        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        self.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(videoIcon.snp.right).offset(3)
            maker.right.equalToSuperview().offset(-4)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setDuration(_ duration: Int32) {
        // 服务器返回的是毫秒，所以先除以1000
        var time = Int(round(TimeInterval(duration) / 1000))
        let second = time % 60
        time /= 60
        let minute = time % 60
        time /= 60
        let value: String
        if time > 0 {
            value = String(format: "%02d:%02d:%02d", time, minute, second)
        } else {
            value = String(format: "%02d:%02d", minute, second)
        }
        self.timeLabel.text = value
    }
}
