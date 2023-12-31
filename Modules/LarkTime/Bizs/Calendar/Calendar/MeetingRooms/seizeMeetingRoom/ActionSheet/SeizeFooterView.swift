//
//  SeizeFooterView.swift
//  Calendar
//
//  Created by harry zou on 2019/4/18.
//

import UIKit
import LarkActivityIndicatorView
import CalendarFoundation
final class SeizeFooterView: UIView {
    var seizeButtonPressed: (() -> Void)?
    private let loadingIndicator = ActivityIndicatorView()

    private lazy var seizeButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.titleLabel?.textColor = UIColor.ud.primaryOnPrimaryFill
        button.setTitle(BundleI18n.Calendar.Calendar_Takeover_Action, for: .normal)
        button.setBackgroundImage(UIImage.cd.from(color: UIColor.ud.primaryContentDefault), for: .normal)
        button.setBackgroundImage(UIImage.cd.from(color: UIColor.ud.primaryContentDefault.withAlphaComponent(0.95)), for: .highlighted)
        button.addSubview(loadingIndicator)
        loadingIndicator.color = UIColor.ud.primaryOnPrimaryFill
        loadingIndicator.snp.makeConstraints { (make) in
            guard let label = button.titleLabel else { return }
            make.centerY.equalToSuperview()
            make.right.equalTo(label.snp.left).offset(-12)
            make.width.height.equalTo(16)
        }
        return button
    }()

    init() {
        super.init(frame: .zero)
        addSubview(seizeButton)
        seizeButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(6)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-16)
        }
        seizeButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func buttonPressed() {
        seizeButtonPressed?()
        startLoading()
    }
    func startLoading() {
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        seizeButton.setTitle(BundleI18n.Calendar.Calendar_Takeover_Takingover, for: .normal)
    }

    func stopLoading() {
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimating()
        seizeButton.setTitle(BundleI18n.Calendar.Calendar_Takeover_Action, for: .normal)
    }
}
