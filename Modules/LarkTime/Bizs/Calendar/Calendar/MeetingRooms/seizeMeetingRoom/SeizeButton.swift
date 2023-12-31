//
//  SeizeButton.swift
//  Calendar
//
//  Created by harry zou on 2019/4/16.
//

import UIKit
import CalendarFoundation
final class SeizeButton: UIButton {

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 50)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setTitle(BundleI18n.Calendar.Calendar_Takeover_TakeoverMain, for: .normal)
        setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        titleLabel?.font = UIFont.cd.mediumFont(ofSize: 16)
        isEnabled = false
        isHighlighted = false
        setBackgroundImage(UIImage.cd.from(color: UIColor.ud.textDisable), for: .disabled)
        setBackgroundImage(UIImage.cd.from(color: UIColor.ud.primaryContentDefault), for: .normal)
        setBackgroundImage(UIImage.cd.from(color: UIColor.ud.primaryContentDefault.withAlphaComponent(0.95)), for: .highlighted)
        layer.cornerRadius = 25
        clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
