//
//  MailFilterTypeTipsView.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/10/25.
//

import Foundation
import UIKit
import SnapKit

protocol MailFilterTypeTipsViewDelegate: AnyObject {
    func didClickFilterTypeTips()
}

extension MailFilterTypeTipsViewDelegate {
    func didClickFilterTypeTips() {}
}

class MailFilterTypeTipsView: UIView {
    weak var delegate: MailFilterTypeTipsViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        self.alpha = 0.0
        self.transform = CGAffineTransform(scaleX: 0.88, y: 0.96)
        UIView.animate(
            withDuration: 0.25,
            delay: 0.08,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 5,
            options: .curveEaseOut,
            animations: {
                self.alpha = 1.0
                self.transform = .identity
            },
            completion: nil
        )
    }

    func setupViews() {
        addSubview(titleLabel)
        addSubview(separator)
        backgroundColor = UIColor.ud.bgBodyOverlay

        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        separator.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(1)
            make.bottom.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(onClickTips))
        self.addGestureRecognizer(tap)
        self.isUserInteractionEnabled = true

        titleLabel.text = BundleI18n.MailSDK.Mail_Label_FilterUnreadEmailsToast
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: MailThreadListConst.filterViewHeight)
    }

    @objc
    func onClickTips() {
        delegate?.didClickFilterTypeTips()
    }

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textCaption
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        titleLabel.numberOfLines = 1
        return titleLabel
    }()
    lazy var separator: UIView = {
        let separator = UIView()
        separator.backgroundColor = UIColor.ud.bgBody
        separator.isHidden = true
        return separator
    }()
}
