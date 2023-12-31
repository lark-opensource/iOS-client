//
//  NoMoreFeedPostFooter.swift
//  Moment
//
//  Created by zc09v on 2021/1/28.
//

import Foundation
import UIKit
import LarkUIKit
import RichLabel

protocol NoMoreFeedPostFooterDelegate: AnyObject {
    func attributedLabel(didSelectText text: String, didSelectRange range: NSRange) -> Bool
}

final class NoMoreFeedPostFooter: UIView, LKLabelDelegate {

    weak var delegate: NoMoreFeedPostFooterDelegate?
    override var frame: CGRect {
        didSet {
            if Display.pad {
                super.frame = MomentsViewAdapterViewController.computeCellFrame(originFrame: frame)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear

        let tapText = BundleI18n.Moment.Moments_NoMorePostsToShowRefresh_Button
        let text = BundleI18n.Moment.Moments_NoMorePostsToShow_Text(tapText)
        let tapRange = (text as NSString).range(of: tapText)
        let textAttr = NSMutableAttributedString(string: text,
                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.N500,
                                                          NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)])
        textAttr.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.colorfulBlue], range: tapRange)
        let label = LKLabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = UIColor.clear
        label.attributedText = textAttr
        label.tapableRangeList = [tapRange]
        label.delegate = self
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        self.lu.addTopBorder()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func attributedLabel(_ label: RichLabel.LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        return self.delegate?.attributedLabel(didSelectText: text, didSelectRange: range) ?? false
    }
}
