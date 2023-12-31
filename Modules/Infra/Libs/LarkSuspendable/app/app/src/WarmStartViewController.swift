//
//  WarmStartViewController.swift
//  LarkSuspendableDev
//
//  Created by bytedance on 2021/1/15.
//

import Foundation
import UIKit
import SnapKit
import LarkSuspendable

class WarmStartViewController: UIViewController {

    var text: String {
        didSet {
            textLabel.text = text
        }
    }

    init(text: String) {
        self.text = text
        super.init(nibName: nil, bundle: nil)
        print("\(self) init")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("\(self) deinit")
    }

    private lazy var switchText: UILabel = {
        let label = UILabel()
        label.text = "是否支持侧划收入"
        return label
    }()

    private lazy var interactiveSwitch: UISwitch = {
        let mSwitch = UISwitch()
        mSwitch.isOn = false
        // For on state
        mSwitch.onTintColor = .systemGreen
        // For off state*/
        mSwitch.tintColor = .systemRed
        mSwitch.layer.cornerRadius = mSwitch.frame.height / 2.0
        mSwitch.backgroundColor = .systemRed
        mSwitch.clipsToBounds = true
        return mSwitch
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30)
        return label
    }()

    private lazy var suspendButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(addOrRemoveSuspendWindow), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel.text = text
        view.backgroundColor = .gray
        view.addSubview(switchText)
        view.addSubview(interactiveSwitch)
        interactiveSwitch.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        switchText.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(interactiveSwitch.snp.top).offset(-5)
        }
        view.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-100)
        }
        view.addSubview(suspendButton)
        suspendButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-50)
            make.width.equalTo(150)
            make.height.equalTo(60)
        }
        changeSuspendButtonState()
        title = "\(Unmanaged.passUnretained(self).toOpaque())"
    }

    private func changeSuspendButtonState() {
        if SuspendManager.shared.contains(suspendID: self.suspendID) {
            suspendButton.setTitle(BundleI18n.LarkSuspendable.Lark_Core_CancelFloating, for: .normal)
            suspendButton.backgroundColor = .systemRed
        } else {
            suspendButton.setTitle(BundleI18n.LarkSuspendable.Lark_Core_PutIntoFloating, for: .normal)
            suspendButton.backgroundColor = .systemGreen
        }
    }

    @objc
    private func addOrRemoveSuspendWindow() {
        if !SuspendManager.shared.contains(suspendID: suspendID) {
            SuspendManager.shared.addSuspend(viewController: self) { [weak self] in
                self?.changeSuspendButtonState()
            }
        } else {
            SuspendManager.shared.removeSuspend(viewController: self)
            changeSuspendButtonState()
        }
    }
}

extension WarmStartViewController: ViewControllerSuspendable {

    var suspendID: String {
        return text + suspendURL
    }

    var suspendURL: String {
        return "//demo/suspend/warmstart"
    }

    var suspendParams: [String: AnyCodable] {
        return ["text": AnyCodable(text)]
    }

    var suspendTitle: String {
        return "Warm start: \(text)"
    }

    var suspendIconURL: String? {
        return "https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=2480604110,4008147240&fm=26&gp=0.jpg"
    }

    var suspendGroup: SuspendGroup {
        return .document
    }

    var isInteractive: Bool {
        return interactiveSwitch.isOn
    }

    var isWarmStartEnabled: Bool {
        return true
    }

    var isViewControllerRecoverable: Bool {
        return false
    }

    var analyticsTypeName: String {
        "warm"
    }
}
