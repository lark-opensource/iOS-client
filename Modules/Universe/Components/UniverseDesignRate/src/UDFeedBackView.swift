//
//  UDFeedBackView.swift
//  UniverseDesignRate
//
//  Created by 姚启灏 on 2021/2/28.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignFont
import UniverseDesignColor

public class UDFeedBackView: UIView {
    public enum Status {
        case none
        case left
        case right
    }

    private var leftControl = UDFeedBackControl()
    private var rightControl = UDFeedBackControl()
    private var separatorView = UIView()

    private var status: Status = .none

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(leftControl)
        self.addSubview(rightControl)
        self.addSubview(separatorView)

        leftControl.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
        }

        leftControl.addTarget(self, action: #selector(tapLeftControl), for: .touchUpInside)

        separatorView.backgroundColor = UDColor.N900.withAlphaComponent(0.1)
        separatorView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.width.equalTo(1)
            make.left.equalTo(leftControl.snp.right).offset(72)
            make.right.equalTo(rightControl.snp.left).offset(-72)
        }

        rightControl.snp.makeConstraints { (make) in
            make.top.right.bottom.equalToSuperview()
        }

        rightControl.addTarget(self, action: #selector(tapRightControl), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func tapLeftControl() {
        status = status == .left ? .none : .left
    }

    @objc
    func tapRightControl() {
        status = status == .right ? .none : .right
    }

}

class UDFeedBackControl: UIControl {
    private var feedBackImageView: UIImageView?
    private var feedBackLabel: UILabel?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let feedBackImageView = UIImageView()
        feedBackImageView.contentMode = .center
        let feedBackLabel = UILabel()
        feedBackLabel.textAlignment = .center

        self.feedBackLabel = feedBackLabel
        self.feedBackImageView = feedBackImageView

        self.addSubview(feedBackImageView)
        self.addSubview(feedBackLabel)

        feedBackImageView.snp.makeConstraints { (make) in
            make.height.width.equalTo(44)
            make.left.right.top.equalToSuperview()
        }

        feedBackLabel.snp.makeConstraints { (make) in
            make.top.equalTo(feedBackImageView.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLabel(textColor: UIColor = UDRateColorTheme.rateLabelColor,
                  textFont: UIFont = UDFont.caption1) {
        self.feedBackLabel?.textColor = textColor
        self.feedBackLabel?.font = textFont
    }

    func update(image: UIImage?, text: String) {
        feedBackImageView?.image = image
        feedBackLabel?.text = text
    }
}
