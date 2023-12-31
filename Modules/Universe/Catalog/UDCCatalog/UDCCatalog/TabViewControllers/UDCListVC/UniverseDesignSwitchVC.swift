//
//  UniverseDesignSwitchVC.swift
//  UDCCatalog
//
//  Created by CJ on 2020/11/6.
//  Copyright © 2020 CJ. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignSwitch
import UniverseDesignColor

class UniverseDesignSwitchVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var sectionTitles: [String] = []
    var dataSource: [[(String, UDSwitchUIConfig, SwitchBehaviourType, Bool, Bool)]] = []

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.register(UniverseDesignSwitchCell.self, forCellReuseIdentifier: UniverseDesignSwitchCell.cellIdentifier)
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UniverseDesignSwitchVC"
        view.backgroundColor = UIColor.white
        configDataSource()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    private func configDataSource() {
        sectionTitles = ["默认开关", "自定义开关1  开:green ", "自定义开关2  开:red  关:darkGray"]
        let normalDataSource: [(String, UDSwitchUIConfig, SwitchBehaviourType, Bool, Bool)] = [
            ("默认打开 可点击", UDSwitchUIConfig.defaultConfig, .normal, true, true),
            ("默认打开 禁用", UDSwitchUIConfig.defaultConfig, .normal, false, true),
            ("默认打开 可点击 带loading", UDSwitchUIConfig.defaultConfig, .waitCallback, true, true),
            ("默认关闭 可点击", UDSwitchUIConfig.defaultConfig, .normal, true, false),
            ("默认关闭 禁用", UDSwitchUIConfig.defaultConfig, .normal, false, false),
            ("默认关闭 可点击 带loading", UDSwitchUIConfig.defaultConfig, .waitCallback, true, false),
        ]
        
        let customUIConfig1 = UDSwitchUIConfig(onNormalTheme: UDSwitchUIConfig.ThemeColor(tintColor: UDColor.colorfulGreen, thumbColor: UIColor.white))
        let customDataSource1: [(String, UDSwitchUIConfig, SwitchBehaviourType, Bool, Bool)] = [
            ("默认打开 可点击", customUIConfig1, .normal, true, true),
            ("默认打开 禁用", customUIConfig1, .normal, false, true),
            ("默认打开 可点击 带loading", customUIConfig1, .waitCallback, true, true),
            ("默认关闭 可点击", customUIConfig1, .normal, true, false),
            ("默认关闭 禁用", customUIConfig1, .normal, false, false),
            ("默认关闭 可点击 带loading", customUIConfig1, .waitCallback, true, false),
        ]
        
        let customUIConfig2 = UDSwitchUIConfig(onNormalTheme: UDSwitchUIConfig.ThemeColor(tintColor: UDColor.colorfulRed, thumbColor: UIColor.white), offNormalTheme: UDSwitchUIConfig.ThemeColor(tintColor: UIColor.darkGray, thumbColor: UIColor.white))
        let customDataSource2: [(String, UDSwitchUIConfig, SwitchBehaviourType, Bool, Bool)] = [
            ("默认打开 可点击", customUIConfig2, .normal, true, true),
            ("默认打开 禁用", customUIConfig2, .normal, false, true),
            ("默认打开 可点击 带loading", customUIConfig2, .waitCallback, true, true),
            ("默认关闭 可点击", customUIConfig2, .normal, true, false),
            ("默认关闭 禁用", customUIConfig2, .normal, false, false),
            ("默认关闭 可点击 带loading", customUIConfig2, .waitCallback, true, false),
       ]
        
        dataSource = [normalDataSource, customDataSource1, customDataSource2]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: UniverseDesignSwitchCell.cellIdentifier) as? UniverseDesignSwitchCell {
            let item = dataSource[indexPath.section][indexPath.row]
            cell.titleLabel.text = item.0
            cell.udSwitch.uiConfig = item.1
            cell.udSwitch.behaviourType = item.2
            cell.udSwitch.isEnabled = item.3
            cell.udSwitch.setOn(item.4, animated: false)
            cell.udSwitch.valueWillChanged = { isOn in
                if item.2 == .waitCallback {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        cell.udSwitch.setOn(isOn, animated: true)
                    }
                }
            }
            
            cell.udSwitch.valueChanged = { _ in
            }
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: UniverseDesignSwitchCell.cellIdentifier)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
}


class UniverseDesignSwitchCell: UITableViewCell {
    static let cellIdentifier = "switchDemoCell"
    public let udSwitch = UDSwitch()
    public let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        contentView.addSubview(udSwitch)

        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
        }
        
        udSwitch.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-30)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

