//
//  SafeModeViewController.swift
//  AppContainer
//
//  Created by huoyunjie on 2020/9/11.
//

import Foundation
import UIKit
import UniverseDesignColor
import SnapKit
import UniverseDesignEmpty
import LarkAccountInterface
import LarkFoundation

final class SafeModeViewController: UIViewController {

    var clear: () -> Void

    var label: UILabel = UILabel()
    var button: SafeModeButton = SafeModeButton()
    var messenger: UILabel = UILabel()
    var image: UIImageView = UIImageView()
    var phoneNumber: String = String()

    init(clear: @escaping () -> Void) {
        self.clear = clear
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
        self.title = BundleI18n.LarkSafeMode.Lark_Login_SafeMode
        self.navigationController?.navigationBar.barTintColor = UIColor.ud.bgBase
        self.navigationController?.navigationBar.clipsToBounds = true

        label.text = BundleI18n.LarkSafeMode.Lark_Login_SafeModeDataError
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        self.view.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.height.equalTo(28)
            make.centerY.equalTo(self.view).offset(-62)
            make.centerX.equalTo(self.view)
        }

        image.image = UDEmptyType.error.defaultImage()
        self.view.addSubview(image)
        image.snp.makeConstraints { (make) in
            make.width.height.equalTo(120)
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(label.snp.top).offset(-20)
        }

        messenger.textColor = UIColor.ud.textPlaceholder
        messenger.font = .systemFont(ofSize: 14, weight: .regular)
        messenger.numberOfLines = 0
        messenger.lineBreakMode = .byWordWrapping
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.3
        paragraphStyle.alignment = .center
        messenger.attributedText = NSMutableAttributedString(
            string: BundleI18n.LarkSafeMode.Lark_Login_SafeModeDataErrorDesc,
            attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        view.addSubview(messenger)
        messenger.snp.makeConstraints { (make) in
            make.top.equalTo(label.snp.bottom).offset(10)
            make.left.right.equalTo(self.view).inset(61)
        }

        button.layer.cornerRadius = 4
        button.backgroundColor = UIColor.ud.colorfulBlue
        button.titleLabel?.textColor = UIColor.ud.primaryOnPrimaryFill
        button.setTitle(BundleI18n.LarkSafeMode.Lark_Login_SafeModeStartFixButton, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.addTarget(self, action: #selector(repair), for: .touchUpInside)
        self.view.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.height.equalTo(48)
            make.left.right.equalTo(self.view).inset(16)
            make.bottom.equalTo(self.view).inset(90)
        }
    }

    @objc
    func repair(button: SafeModeButton) {
        if button.currentTitle == BundleI18n.LarkSafeMode.Lark_Login_SafeModeStartFixButton {
            repairing(button: button)
            DispatchQueue.global().async {
                self.clear()
                DispatchQueue.main.async {
                   self.repaired(button: button)
                }
            }
        } else if button.currentTitle == BundleI18n.LarkSafeMode.Lark_Login_SafeModeCloseAppButton {
            exit(0)
        }
    }

    func repairing(button: SafeModeButton) {
        label.text = BundleI18n.LarkSafeMode.Lark_Login_SafeModeDataFixing
        image.image = UDEmptyType.restoring.defaultImage()
        button.setTitle(BundleI18n.LarkSafeMode.Lark_Login_SafeModeDataFixingButton, for: .normal)
        button.showLoading()
    }

    func repaired(button: SafeModeButton) {
        label.text = BundleI18n.LarkSafeMode.Lark_Login_SafeModeFixFinishedDesc
        image.image = UDEmptyType.done.defaultImage()
        button.setTitle(BundleI18n.LarkSafeMode.Lark_Login_SafeModeCloseAppButton, for: .normal)
        // 海外Lark不显示电话号码
        if !AccountServiceAdapter.shared.isFeishuBrand {
            messenger.text = BundleI18n.LarkSafeMode.Lark_Core_SafeModeRepair_IfProblemHappensAgainReDownload_Text()
            + "，"
            +  BundleI18n.LarkSafeMode.Lark_Core_SafeModeRepair_ForFurtherQuestionsContactSupport_Text()
        } else {
            var str: String = BundleI18n.LarkSafeMode.Lark_Core_SafeModeRepair_IfProblemHappensAgainReDownload_Text()
            + "，"
            +  BundleI18n.LarkSafeMode.Lark_Core_SafeModeRepair_ForFurtherQuestionsContactSupportWithPhoneNumber_Text()
            var string: NSAttributedString = str.numberChange(color: UIColor.ud.B600, font: messenger.font)
            messenger.attributedText = string
            messenger.isUserInteractionEnabled = true
            messenger.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
//           str.range(of: #"^400-\d{4}-\d{3}$"#, options: .regularExpression)
            let nsString = NSString(string: str)
            let range = nsString.range(of: "400")
            if range.location != NSNotFound {
                phoneNumber = nsString.substring(with: NSRange(location: range.location, length: 12))
            }
        }

        button.hideLoading()
    }

    @objc
    private func handleTap(recognizer: UITapGestureRecognizer) {
        if phoneNumber.isEmpty {
            return
        }
        let str = phoneNumber.replacingOccurrences(of: "-", with: "", options: [], range: nil)
        let callStr = "telprompt://" + str
        guard let url = URL(string: callStr) else {
            return
        }
        UIApplication.shared.open(url)
    }
}

extension String {
    func numberChange(color: UIColor, font: UIFont, regx: String = "\\d+") -> NSMutableAttributedString {
        let attributeString = NSMutableAttributedString(string: self)
        do {
            // 数字正则表达式
            let regexExpression = try NSRegularExpression(pattern: regx, options: NSRegularExpression.Options())
            let result = regexExpression.matches(in: self, options: NSRegularExpression.MatchingOptions(), range: NSRange(location: 0, length: count))

            for item in result {
                attributeString.setAttributes([.foregroundColor: color, .font: font], range: item.range)
            }
        } catch {
            // print("Failed with error: \(error)")
        }
        return attributeString
    }
}
