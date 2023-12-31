//
//  EnterpriseKeyPadViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2021/10/19.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUI
import ByteViewNetwork
import UniverseDesignToast
import ByteViewTracker

class EnterpriseKeyPadViewController: VMViewController<EnterpriseKeyPadViewModel> {

    lazy var keyPadView: EnterpriseKeyPadView = {
        let keyPadView = EnterpriseKeyPadView()
        keyPadView.phoneNumberLabel.delegate = self
        keyPadView.callButton.addTarget(self, action: #selector(callOut), for: .touchUpInside)
        return keyPadView
    }()

    lazy var backButton: UIButton = {
        let color = UIColor.ud.iconN1
        let highlighedColor = UIColor.ud.N500.dynamicColor
        var icon: UDIconType = Display.pad ? .closeOutlined : .leftOutlined
        let actionButton = UIButton()
        actionButton.setImage(UDIcon.getIconByKey(icon, iconColor: color), for: .normal)
        actionButton.setImage(UDIcon.getIconByKey(icon, iconColor: highlighedColor), for: .highlighted)
        actionButton.addTarget(self, action: #selector(doBack), for: .touchUpInside)
        return actionButton
    }()

    var task: DispatchWorkItem?

    var canSetDesc: Bool = true

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ServerPush.enterprisePhone.inUser(viewModel.userId).addObserver(self) { [weak self] in
            self?.didReceiveEnterprisePhoneNotify($0)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func setupViews() {
        super.setupViews()

        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(10)
            make.size.equalTo(24)
        }

        view.addSubview(keyPadView)
        keyPadView.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func bindViewModel() {
        super.bindViewModel()
        updateQuota()
    }

    func updateQuota() {
        viewModel.checkQuota { [weak self] r in
            DispatchQueue.main.async {
                self?.keyPadView.balanceLabel.isHidden = (r == nil)
                guard let r = r else { return }
                self?.keyPadView.updateBalance(date: r.date, balance: r.availableEnterprisePhoneAmount, department: r.departmentName)
            }
        }
    }

    @objc func callOut() {
        if let phoneNumber = keyPadView.phoneNumberLabel.text, !phoneNumber.isEmpty {
            VCTracker.post(name: .vc_tab_dial_click, params: [.click: "phone"])
            viewModel.callOut(with: phoneNumber, from: self) { [weak self] in
                if case .success = $0 { // 只在成功状态下清空号码
                    self?.resetPhoneNumber()
                    self?.canSetDesc = false
                }
            }
        } else if let lastCalledPhoneNumber = viewModel.lastCalledPhoneNumber {
            keyPadView.phoneNumberLabel.text = lastCalledPhoneNumber
        }
    }

    private func resetPhoneNumber() {
        Util.runInMainThread { [weak self] in
            self?.keyPadView.phoneNumberLabel.text = nil
            self?.keyPadView.descLabel.text = nil
        }
    }
}

extension EnterpriseKeyPadViewController: EnterpriseKeyPadLabelDelegate {
    func label(_ label: EnterpriseKeyPadLabel, willChangeText text: String?) -> String? {
        guard let text = text, text.count <= viewModel.maxTextLength else {
            keyPadView.updatePhoneDesc(province: nil, isp: nil, countryName: nil, ipPhoneLarkUserName: nil)
            return text == nil ? nil : label.text
        }
        task?.cancel()
        canSetDesc = true
        if text.count > 3 {
            let workItem = DispatchWorkItem(block: { [weak self] in
                self?.viewModel.getPhoneAttribute(text) { result in
                    if let self = self, self.canSetDesc {
                        let r = try? result.get()
                        self.keyPadView.updatePhoneDesc(province: r?.province, isp: r?.isp, countryName: self.viewModel.getCountryName(r), ipPhoneLarkUserName: r?.ipPhoneLarkUserName)
                    }
                }
            })
            task = workItem
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + .milliseconds(400), execute: workItem)
        } else {
            keyPadView.updatePhoneDesc(province: nil, isp: nil, countryName: nil, ipPhoneLarkUserName: nil)
        }
        return PhoneNumberUtil.format(text)
    }

    func labelDidCopyText(_ label: EnterpriseKeyPadLabel) {
        if let text = label.text {
            let security = viewModel.viewModel.dependency
            _ = security.setPasteboardText(text, token: SncToken.keypadCopyNumber.rawValue, shouldImmunity: false)
        } else {
            Logger.ui.debug("No valid text can be copied to paste board")
        }
    }

    func labelDidPasteText(_ label: EnterpriseKeyPadLabel) {
        let security = viewModel.viewModel.dependency
        let pasteText = security.getPasteboardText(token: SncToken.keypadCopyNumber.rawValue)
        if let text = PhoneNumberUtil.extractPhoneNumber(from: pasteText)?.substring(to: viewModel.maxTextLength) {
            label.text = text
        } else {
            Logger.ui.debug("Text from paste board is not valid")
        }
    }
}

extension EnterpriseKeyPadViewController {
    func didReceiveEnterprisePhoneNotify(_ message: EnterprisePhoneNotify) {
        Logger.network.debug("Enterprise call push")
        if message.action == .callExceptionToastCallerUnreached {
            showToast(i18nKey: message.callerUnreachedToastData.key)
        }
        if message.action == .callEnd {
            updateQuota()
        }
    }

    func showToast(i18nKey key: String) {
        viewModel.httpClient.i18n.get(key) { [weak self] result in
            guard let self = self else { return }
            if let content = try? result.get() {
                UDToast.showTips(with: content, on: self.view)
            }
        }
    }
}

private extension PhoneNumberUtil {
    static let validPhoneNumberCharacters: [Character] = ["1", "2", "3",
                                                          "4", "5", "6",
                                                          "7", "8", "9",
                                                          "*", "0", "#",
                                                          "+"]

    static func extractPhoneNumber(from string: String?) -> String? {
        guard let string = string else { return nil }
        return format(string.filter { validPhoneNumberCharacters.contains($0) })
    }
}
