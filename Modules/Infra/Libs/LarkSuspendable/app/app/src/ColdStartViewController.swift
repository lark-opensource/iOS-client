//
//  ColdStartViewController.swift
//  LarkSuspendableDev
//
//  Created by bytedance on 2021/1/13.
//

import Foundation
import UIKit
import SnapKit
import LarkSuspendable

class ColdStartViewController: UIViewController {

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

    private lazy var interactiveSwitchText: UILabel = {
        let label = UILabel()
        label.text = "是否支持侧划收入"
        return label
    }()

    private lazy var autoCloseSwitch: UISwitch = {
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

    private lazy var autoCloseSwitchText: UILabel = {
        let label = UILabel()
        label.text = "收入后自动关闭"
        return label
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
        view.backgroundColor = .lightGray
        view.addSubview(interactiveSwitch)
        view.addSubview(interactiveSwitchText)
        interactiveSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().offset(-80)
        }
        interactiveSwitchText.snp.makeConstraints { make in
            make.centerY.equalTo(interactiveSwitch)
            make.left.equalTo(interactiveSwitch.snp.right).offset(10)
        }
        view.addSubview(autoCloseSwitch)
        view.addSubview(autoCloseSwitchText)
        autoCloseSwitch.snp.makeConstraints { make in
            make.top.equalTo(interactiveSwitch.snp.bottom).offset(10)
            make.centerX.equalToSuperview().offset(-80)
        }
        autoCloseSwitchText.snp.makeConstraints { make in
            make.centerY.equalTo(autoCloseSwitch)
            make.left.equalTo(autoCloseSwitch.snp.right).offset(10)
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
        if !SuspendManager.shared.contains(suspendID: self.suspendID) {
            SuspendManager.shared.addSuspend(
                viewController: self,
                shouldClose: autoCloseSwitch.isOn
            ) { [weak self] in
                self?.changeSuspendButtonState()
            }
        } else {
            SuspendManager.shared.removeSuspend(viewController: self)
            changeSuspendButtonState()
        }
    }
}

extension ColdStartViewController: ViewControllerSuspendable {

    var suspendID: String {
        return text + suspendURL
    }

    var suspendURL: String {
        return "//demo/suspend/coldstart"
    }

    var suspendParams: [String: AnyCodable] {
        return ["text": AnyCodable(text)]
    }

    var suspendTitle: String {
        return "Cold start: \(text)"
    }

    var suspendIconURL: String? {
        return "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fwww.divestit.com.au%2Fwp-content%2Fuploads%2F2014%2F05%2FGoogle-Drive-icon.png&refer=http%3A%2F%2Fwww.divestit.com.au&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1625023032&t=a75cf7a74b6f25e46d39366c9cd5b952"
    }

    var suspendGroup: SuspendGroup {
        return .document
    }

    var isWarmStartEnabled: Bool {
        return false
    }

    var isInteractive: Bool {
        return interactiveSwitch.isOn
    }

    var isViewControllerRecoverable: Bool {
        return false
    }

    var analyticsTypeName: String {
        "cold"
    }
}
