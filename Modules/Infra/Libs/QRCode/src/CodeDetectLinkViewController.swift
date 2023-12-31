//
//  QRCodeDetectLinkViewController.swift
//  LarkWeb
//
//  Created by SuPeng on 12/4/18.
//

import Foundation
import UIKit
import LarkUIKit
import RichLabel

open class CodeDetectLinkViewController: BaseUIViewController {
    public var didSelectLinkBlock: ((CodeDetectLinkViewController, URL) -> Void)?

    private let code: String
    private var label: LKLabel?

    public init(code: String) {
        self.code = code
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        reloadLabel()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        reloadLabel()
    }

    private func reloadLabel() {
        // LKLabel这玩意更新preferredMaxLayoutWidth之后不会自动换行，干脆重新生成一个[○･｀Д´･ ○]
        label?.removeFromSuperview()
        label = nil
        let label = LKLabel()
        view.addSubview(label)
        view.backgroundColor = .white
        label.preferredMaxLayoutWidth = view.bounds.width - 16
        label.snp.makeConstraints { (make) in
            make.left.top.equalTo(8)
            make.right.equalToSuperview().offset(-8)
        }
        label.backgroundColor = .white
        label.autoDetectLinks = true
        label.textCheckingDetecotor = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.linkAttributes = [
            NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): UIColor.ud.colorfulBlue.cgColor
        ]
        label.delegate = self
        label.isUserInteractionEnabled = true
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = code
        self.label = label
    }
}

extension CodeDetectLinkViewController: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        didSelectLinkBlock?(self, url)
    }
}
