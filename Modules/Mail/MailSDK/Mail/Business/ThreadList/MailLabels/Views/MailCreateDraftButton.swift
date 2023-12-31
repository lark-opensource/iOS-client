//
//  MailCreateDraftButton.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/9/24.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignShadow
import LarkInteraction

protocol MailCreateDraftButtonDelegate: AnyObject {
    func createNewMail()
}

class MailCreateDraftButton: UIButton {
    weak var delegate: MailCreateDraftButtonDelegate?

    private var addIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.addOutlined.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.ud.primaryOnPrimaryFill
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 48 / 2.0
//        setImage(UDIcon.addOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
//        imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
//        imageView?.tintColor = UIColor.ud.primaryOnPrimaryFill
        addSubview(addIcon)
        backgroundColor = UIColor.ud.primaryFillDefault
        layer.ud.setShadow(type: .s4DownPri)
        addTarget(self, action: #selector(createNewMail), for: .touchUpInside)
        accessibilityIdentifier = MailAccessibilityIdentifierKey.BtnHomeFABKey
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                    effect: .lift
                )
            )
            addLKInteraction(pointer)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        addIcon.frame = CGRect(x: 12, y: 12, width: 24, height: 24)
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.ud.primaryFillPressed : UIColor.ud.primaryFillDefault
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func createNewMail() {
        delegate?.createNewMail()
    }
}
