//
//  SKDebugEnvPickVC.swift
//  SpaceDemo
//
//  Created by chenhuaguan on 2020/8/6.
//  Copyright © 2020 Bytedance. All rights reserved.
//

import Foundation
import LarkUIKit
import SnapKit
import LarkAlertController
import LarkAppConfig
import RxSwift


extension Env {
    var descriptionText: String { "\(type)(\(unit))" }
}

class SKDebugEnvPickVC: BaseUIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    lazy var closeBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("关闭", for: .normal)
        button.setTitleColor(UIColor.ud.N1000, for: .normal)
        button.addTarget(self, action: #selector(clickCloseBtn), for: .touchUpInside)
        return button
    }()

    lazy var confirmBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("确定", for: .normal)
        button.setTitleColor(UIColor.ud.N1000, for: .normal)
        button.addTarget(self, action: #selector(clickConfirmBtn), for: .touchUpInside)
        return button
    }()

    lazy var alertView: UILabel = {
        let alertView = UILabel()
        alertView.text = "当前环境为 \(self.currentDev.descriptionText)\n滚动下方选择器切换环境"
        alertView.textAlignment = .center
        alertView.textColor = UIColor.ud.N1000
        alertView.numberOfLines = 0
        return alertView
    }()

    let disposeBag = DisposeBag()

    lazy var envPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()

    private let dataSource = [Env.TypeEnum.allCases.map({ "\($0)" }), Env.allUnits]
    private let currentDev = ConfigurationManager.shared.env
    private let complete: (Env) -> Void

    init(complete: @escaping (Env) -> Void) {
        self.complete = complete
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)

        self.view.addSubview(self.closeBtn)
        self.closeBtn.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(64)
            make.left.equalToSuperview().offset(44)
        }

        self.view.addSubview(self.confirmBtn)
        self.confirmBtn.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(64)
            make.right.equalToSuperview().offset(-44)
        }

        self.view.addSubview(self.alertView)
        self.alertView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(closeBtn.snp.bottom).offset(20)
        }

        self.view.addSubview(self.envPickerView)
        self.envPickerView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(alertView.snp.bottom).offset(44)
            make.height.equalToSuperview().multipliedBy(0.5)
        }

        if let index = Env.TypeEnum.allCases.firstIndex(of: currentDev.type) {
            self.envPickerView.selectRow(index, inComponent: 0, animated: false)
        }
        if let index = Env.allUnits.firstIndex(of: currentDev.unit) {
            self.envPickerView.selectRow(index, inComponent: 1, animated: false)
        }
    }

    @objc
    func clickCloseBtn() {
        self.dismiss(animated: false, completion: nil)
    }

    @objc
    func clickConfirmBtn() {
        let type = Env.TypeEnum.allCases[envPickerView.selectedRow(inComponent: 0)]
        let unit = Env.allUnits[envPickerView.selectedRow(inComponent: 1)]
        let env = Env(type: type, unit: unit)
        let alertController = LarkAlertController()
        alertController.setTitle(text: "切换\(env.descriptionText)环境")
        alertController.setContent(text: "即将退出程序请重启")
        alertController.addSecondaryButton(text: "取消")
        alertController.addPrimaryButton(text: "确定", dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.complete(env)
        })
        DispatchQueue.main.async {
            if self.currentDev != env {
                self.present(alertController, animated: true)
            } else {
                self.dismiss(animated: false, completion: nil)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSource[component].count
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let currentItem: String
        if component == 0 {
            currentItem = "\(currentDev.type)"
        } else {
            currentItem = currentDev.unit
        }
        let item = dataSource[component][row]
        let textColor = item == currentItem ? UIColor.red : UIColor.ud.N1000
        return NSAttributedString(string: item,
            attributes: [
                NSAttributedString.Key.foregroundColor: textColor
        ])
    }
}

class DebugEnvCell: UITableViewCell {
    let titleLabel: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textAlignment = .center

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
