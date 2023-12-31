//
//  MinimumModeTipView .swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/5/10.
//

import UIKit
import Foundation
import LarkUIKit
import EENavigator
import RichLabel
import LarkMessengerInterface
import LarkContainer

protocol MinimumModeTipViewDelegate: AnyObject, UserResolverWrapper {
    func minimumModeTipViewDismiss(_ minimumModeTipView: MinimumModeTipView)
}

final class MinimumModeTipView: UIView, LKLabelDelegate {

    private let label: LKLabel
    private let button: UIButton
    private let labelInset: UIEdgeInsets
    weak var delegate: MinimumModeTipViewDelegate?

    init() {
        self.label = LKLabel()
        self.button = UIButton()
        self.labelInset = UIEdgeInsets(top: 13, left: 17, bottom: 11, right: 26)
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var bounds: CGRect {
        didSet {
            let labelWidth = bounds.size.width - labelInset.left - labelInset.right
            label.preferredMaxLayoutWidth = labelWidth
            label.invalidateIntrinsicContentSize()
        }
    }

    private func setup() {
        let backColor = UIColor.ud.N00
        backgroundColor = backColor
        self.layer.cornerRadius = 4
        self.layer.borderWidth = 1
        let color = UIColor.ud.N900.withAlphaComponent(0.2).cgColor
        self.layer.borderColor = color
        self.layer.shadowColor = color
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 4
        self.layer.shadowOffset = CGSize(width: 0, height: 4)

        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalTo(labelInset)
        }
        label.backgroundColor = backColor
        label.lineSpacing = 3
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.autoDetectLinks = false
        label.delegate = self

        addSubview(button)
        button.setImage(Resources.minimumMode_close, for: .normal)
        button.backgroundColor = backColor
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.snp.makeConstraints { (make) in
            make.size.equalTo(11)
            make.top.equalToSuperview().offset(13)
            make.leading.equalTo(label.snp.trailing).offset(3)
        }

        let text = BundleI18n.LarkFeed.Lark_Legacy_BasicModeTurnOnToast()
        let textLength = text.utf16.count
        let tapText = BundleI18n.LarkFeed.Lark_Legacy_BasicModeTurnOnToastButton
        let tapTextLength = tapText.utf16.count
        label.tapableRangeList = [NSRange(location: textLength, length: tapTextLength)]
        let tex1 = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.N900, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
        let tex2 = NSAttributedString(string: tapText, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.colorfulBlue, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
        tex1.append(tex2)
        label.attributedText = tex1
    }

    @objc
    private func close() {
        if let delegate = self.delegate {
            delegate.minimumModeTipViewDismiss(self)
        }
    }

    public func attributedLabel(_ label: RichLabel.LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        guard let window = self.window, let delegate = self.delegate else {
            assertionFailure("缺少window")
            return true
        }
        delegate.navigator.push(body: MineGeneralSettingBody(), from: window)
        delegate.minimumModeTipViewDismiss(self)
        return true
    }
}
