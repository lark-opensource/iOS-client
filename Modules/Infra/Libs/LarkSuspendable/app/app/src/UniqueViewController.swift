//
//  UniqueViewController.swift
//  LarkSuspendableDev
//
//  Created by bytedance on 2021/3/14.
//

import Foundation
import UIKit
import LarkSuspendable

class UniqueViewController: UIViewController {

    private var uuid: String

    // 测试协议兼容性
    private var url: URL = URL(string: "www.google.com")!

    private lazy var label: UILabel = {
        let label = UILabel()
        return label
    }()

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "点击弹出键盘"
        textField.backgroundColor = .white
        return textField
    }()

    init(uuid: String = UUID().uuidString) {
        self.uuid = uuid
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        view.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
        }

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBackground)))
        let randomColor = UIColor(
            red: CGFloat.random(in: 0...255) / 255,
            green: CGFloat.random(in: 0...255) / 255,
            blue: CGFloat.random(in: 0...255) / 255,
            alpha: 1
        )
        view.backgroundColor = randomColor
        title = randomColor.hex6
        if SuspendManager.shared.contains(suspendID: suspendID) {
            label.text = "打开自多任务浮窗"
        } else {
            label.text = "打开自正常路径"
        }
    }

    @objc
    private func didTapBackground() {
        view.endEditing(true)
    }
}

extension UniqueViewController: ViewControllerSuspendable {

    var suspendID: String {
        return view.backgroundColor?.hex6 ?? "UniqueVIewController"
    }

    var suspendSourceID: String {
        return uuid
    }

    var suspendTitle: String {
        return "区分来源的VC：\(uuid)"
    }

    var suspendGroup: SuspendGroup {
        return .web
    }

    var suspendURL: String {
        return "//demo/suspend/uniquevc"
    }

    var suspendParams: [String: AnyCodable] {
        return [:]
    }

    var isWarmStartEnabled: Bool {
        return true
    }

    var analyticsTypeName: String {
        "unique"
    }
}
