//
//  MailDualViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/2/4.
//

import Foundation
import EENavigator
import RxSwift
import LarkLocalizations
import RustPB
import LKCommonsLogging

protocol MailDualViewControllerDelegate: AnyObject {
    func dismiss()
    func jumpToWebView(url: URL)
    func confirmSuccessTips()
}

class MailDualViewController: UIViewController {
    weak var delegate: MailDualViewControllerDelegate?
    private let disposeBag = DisposeBag()
    func didAppearFlag() -> Bool {
        return false
    }
    let contentView = UIView()
    private static let logger = Logger.log(MailHomeController.self, category: "Module.MailDualViewController")

    lazy var backgroundMaskView: UIControl = {
        let mask = UIControl()
        mask.addTarget(self, action: #selector(onMaskClick), for: .touchUpInside)
        mask.backgroundColor = UIColor.ud.bgMask
        return mask
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        view.addSubview(backgroundMaskView)
        backgroundMaskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        view.backgroundColor = .clear
        backgroundMaskView.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
        setupAlertTipView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupAlertTipView() {
        let tipsView = UIView()
        view.addSubview(tipsView)
        tipsView.backgroundColor = UIColor.ud.bgBody
        tipsView.layer.cornerRadius = 4
        tipsView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(302)
            make.height.equalTo(270)
        }
        // title label
        let titleLabel = UILabel()
        tipsView.addSubview(titleLabel)
        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.sizeToFit()
        titleLabel.text = BundleI18n.MailSDK.Mail_Client_AccountRevokedTitle
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(24)
        }
        // desLabel
        let desLabel = UILabel()
        tipsView.addSubview(desLabel)
        desLabel.numberOfLines = 0
        tipsView.addSubview(desLabel)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.alignment = .center
        var desText = BundleI18n.MailSDK.Mail_Client_AssociateSuccessContent()
        desText = BundleI18n.MailSDK.Mail_Client_AdminChangeAccountRelinkGmailDesc
        let tipAttributedString = NSAttributedString(string: desText,
                                                     attributes: [.font: UIFont.systemFont(ofSize: 16),
                                                                .foregroundColor: UIColor.ud.N900,
                                                                .paragraphStyle: paragraphStyle])

        desLabel.attributedText = tipAttributedString
        desLabel.snp.makeConstraints { (make) in
            make.width.equalTo(302 - 40)
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }

        // line
        let line = UIView()
        tipsView.addSubview(line)
        line.backgroundColor = UIColor.ud.N300
        line.snp.makeConstraints { (make) in
            make.top.equalTo(desLabel.snp.bottom).offset(22)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }

        // button
        let button = UIButton()
        button.setTitle(BundleI18n.MailSDK.Mail_Client_GotItButton, for: .normal)
        button.setTitleColor(UIColor.ud.B400, for: .normal)
        button.addTarget(self, action: #selector(onMaskClick), for: .touchUpInside)
        tipsView.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
            make.top.equalTo(line.snp.bottom)
        }

        tipsView.snp.remakeConstraints { (make) in
            make.width.equalTo(302)
            make.bottom.equalTo(line.snp.bottom).offset(52)
            make.center.equalToSuperview()
        }
    }

    @objc
    func onMaskClick() {
        delegate?.dismiss()
        dismiss(animated: true, completion: nil)
        Store.settingData.updateCurrentSettings(.accountRevokeNotifyPopupVisible(false))
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        delegate?.dismiss()
        super.dismiss(animated: flag, completion: completion)
    }
}

final class UsageTipView: UIView {
    let dot: UIView = {
        let dot = UIView()
        dot.layer.cornerRadius = 2
        dot.backgroundColor = .white
        return dot
    }()
    var title: UILabel = {
        let title = UILabel()
        title.numberOfLines = 0
        title.font = UIFont.systemFont(ofSize: 14)
        title.textColor = UIColor.ud.N00
        return title
    }()

    func setTitle(_ text: String) {
        title.text = text
        title.sizeToFit()
        self.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: title.bounds.size.height)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(dot)
        dot.frame = CGRect(x: 2, y: 7, width: 4, height: 4)
        addSubview(title)
        title.frame = CGRect(x: 2 + 13, y: 0, width: frame.size.width - 15, height: frame.size.height)
    }

    func updateColor(color: UIColor) {
        self.dot.backgroundColor = color
        self.title.textColor = color
    }

    func getViewHeight() -> CGFloat {
        return title.bounds.size.height
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
