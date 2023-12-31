//
//  UniverseDesignDatePickerVC.swift
//  UDCCatalog
//
//  Created by LiangHongbin on 2020/11/24.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignDatePicker

class UniverseDesignDatePickerVC: UIViewController {
    var tableView: UITableView = UITableView()
    let titles = ["滚轮选择器-基础式",
                  "滚轮选择器-嵌入式",
                  "月历选择器"]
    let dateTypes = [["11月14日 周六 - 上午 - 04 - 00 (5行)",//活动支持
                      "11月14日 周六 - 04 - 00 (5行)",
                      "2020年 - 10月 - 31日 (5行)"],//航班动态、休假申请
                     ["11月14日 周六 - 上午 - 04 - 00",//编辑页
                      "11月14日 周六 - 04 - 00",
                      "上午 - 11 - 25",//我的工作时间
                      "11 - 25",
                      "2020年 - 10月 - 31日(周日)"],//重复性规则
                     ["月历选择器"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UniverseDesignDatePicker"

        tableView = UITableView(frame: view.bounds, style: .plain)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 40
        tableView.separatorStyle = .none
        tableView.register(PickerSampleCell.self, forCellReuseIdentifier: "dateSample")
    }
}

extension UniverseDesignDatePickerVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dateTypes[section].count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titles[section]
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return titles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let sampleCell = tableView.dequeueReusableCell(withIdentifier: "dateSample") as? PickerSampleCell {
            sampleCell.textLabel?.text = dateTypes[indexPath.section][indexPath.row]
            sampleCell.textLabel?.textAlignment = .center
            let calendar = Calendar.current
            let tapCallBack: (() -> Void)?
            if indexPath.section == 0 {
                switch indexPath.row {
                case 0:
                    tapCallBack = { [weak self]  in
                        let config = UDWheelsStyleConfig(mode: .dayHourMinute(), maxDisplayRows: 5, is12Hour: true)
                        let subVC = UDDateWheelPickerViewController(customTitle: "自定义标题", wheelConfig: config)
                        subVC.view.backgroundColor = UIColor.ud.N200.withAlphaComponent(0.8)
                        subVC.modalPresentationStyle = .fullScreen
                        subVC.confirm = { (data) in
                            let result = calendar.dateComponents(in: .current, from: data)
                            print(String(describing: result))
                        }
                        self?.navigationController?.present(subVC, animated: false, completion: nil)
                    }
                case 1:
                    tapCallBack = { [weak self]  in
                        let config = UDWheelsStyleConfig(mode: .dayHourMinute(), maxDisplayRows: 5, is12Hour: false)
                        let subVC = UDDateWheelPickerViewController(customTitle: "自定义标题自定义标题自定义标题自定义标题自定义标题自定义标题", wheelConfig: config)
                        subVC.view.backgroundColor = UIColor.ud.N200.withAlphaComponent(0.8)
                        subVC.modalPresentationStyle = .fullScreen
                        subVC.confirm = { (data) in
                            let result = calendar.dateComponents(in: .current, from: data)
                            print(String(describing: result))
                        }

                        self?.navigationController?.present(subVC, animated: false, completion: nil)
                    }
                case 2:
                    tapCallBack = { [weak self]  in
                        let config = UDWheelsStyleConfig(mode: .yearMonthDay, maxDisplayRows: 5)
                        let subVC = UDDateWheelPickerViewController(customTitle: "自定义标题自定义标题自定义标题自定义标题自定义标题自定义标题", wheelConfig: config)
                        subVC.view.backgroundColor = UIColor.ud.N200.withAlphaComponent(0.8)
                        subVC.modalPresentationStyle = .fullScreen
                        subVC.confirm = { (data) in
                            let result = calendar.dateComponents(in: .current, from: data)
                            print(String(describing: result))
                        }
                        self?.navigationController?.present(subVC, animated: false, completion: nil)
                    }
                default:
                    tapCallBack = nil
                    break
                }
            } else if indexPath.section == 1 {
                switch indexPath.row {
                case 0:
                    tapCallBack = { [weak self]  in
                        let subVC = BasicDatePickerVC()
                        // 默认是3行，可以修改行数
                        let config = UDWheelsStyleConfig(mode: .dayHourMinute(), is12Hour: true)
                        let lowerView = UDDateWheelPickerView(wheelConfig: config)
                        lowerView.dateChanged = { (changedDate) in
                            let result = calendar.dateComponents(in: .current, from: changedDate)
                            print(String(describing: result))
                        }
                        subVC.lowerView = lowerView
                        self?.navigationController?.pushViewController(subVC, animated: true)
                    }
                case 1:
                    tapCallBack = { [weak self]  in
                        let subVC = BasicDatePickerVC()
                        let config = UDWheelsStyleConfig(mode: .dayHourMinute(), is12Hour: false)
                        let lowerView = UDDateWheelPickerView(wheelConfig: config)
                        lowerView.dateChanged = { (changedDate) in
                            let result = calendar.dateComponents(in: .current, from: changedDate)
                            print(String(describing: result))
                        }
                        subVC.lowerView = lowerView
                        self?.navigationController?.pushViewController(subVC, animated: true)
                    }
                case 2:
                    tapCallBack = { [weak self]  in
                        let subVC = BasicDatePickerVC()
                        let config = UDWheelsStyleConfig(mode: .hourMinute, is12Hour: true)
                        let lowerView = UDDateWheelPickerView(wheelConfig: config)
                        lowerView.dateChanged = { (changedDate) in
                            let result = calendar.dateComponents(in: .current, from: changedDate)
                            print(String(describing: result))
                        }
                        subVC.lowerView = lowerView
                        self?.navigationController?.pushViewController(subVC, animated: true)
                    }
                case 3:
                    tapCallBack = { [weak self]  in
                        let subVC = BasicDatePickerVC()
                        let config = UDWheelsStyleConfig(mode: .hourMinute, is12Hour: false)
                        let lowerView = UDDateWheelPickerView(wheelConfig: config)
                        lowerView.dateChanged = { (changedDate) in
                            let result = calendar.dateComponents(in: .current, from: changedDate)
                            print(String(describing: result))
                        }
                        subVC.lowerView = lowerView
                        self?.navigationController?.pushViewController(subVC, animated: true)
                    }
                case 4:
                    tapCallBack = { [weak self]  in
                        let subVC = BasicDatePickerVC()
                        let config = UDWheelsStyleConfig(mode: .yearMonthDayWeek)
                        let lowerView = UDDateWheelPickerView(wheelConfig: config)
                        lowerView.dateChanged = { (changedDate) in
                            let result = calendar.dateComponents(in: .current, from: changedDate)
                            print(String(describing: result))
                        }
                        subVC.lowerView = lowerView
                        self?.navigationController?.pushViewController(subVC, animated: true)
                    }
                default:
                    tapCallBack = nil
                    break
                }
            } else if indexPath.section == 2 {
                tapCallBack = { [weak self]  in
                    let subVC = BasicDatePickerVC()
                    let config = UDCalendarStyleConfig()
                    let upperView = UDDateCalendarPickerView(calendarConfig: config)
                    upperView.delegate = subVC
                    subVC.buttonSwitch = UIButton()
                    subVC.buttonPrev = UIButton()
                    subVC.buttonNext = UIButton()
                    subVC.upperView = upperView
                    subVC.buttonSwitchClick = {
                        upperView.switchCalendarMode()
                    }
                    subVC.buttonPrevClick = {
                        upperView.scrollToPrev()
                    }
                    subVC.buttonNextClick = {
                        upperView.scrollToNext()
                    }
                    self?.navigationController?.pushViewController(subVC, animated: true)
                }
            } else {
                tapCallBack = nil
            }
            sampleCell.tapClosure = tapCallBack
            return sampleCell
        }
        return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
    }
}

// 基础式，该VC仅用于展示
class BasicDatePickerVC: UIViewController, UDDatePickerViewDelegate {
    var lowerView: UIView?
    var upperView: UIView?
    var buttonSwitch: UIButton?
    var buttonPrev: UIButton?
    var buttonNext: UIButton?
    var buttonSwitchClick: (() -> Void)?
    var buttonPrevClick: (() -> Void)?
    var buttonNextClick: (() -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.T300
        let bgview = UIView()
        bgview.backgroundColor = .gray
        bgview.layer.cornerRadius = 8
        bgview.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        self.view.addSubview(bgview)
        bgview.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        if let lowerView = lowerView {
            view.addSubview(lowerView)
            lowerView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
            }
        }

        if let upperView = upperView,
           let buttonSwitch = buttonSwitch,
           let buttonPrev = buttonPrev,
           let buttonNext = buttonNext {
            navigationController?.navigationBar.isTranslucent = false
            view.addSubview(upperView)
            upperView.snp.makeConstraints{ (make) in
                make.left.right.top.equalToSuperview()
            }

            buttonSwitch.layer.cornerRadius = 4
            buttonSwitch.setTitle("单行<->多行", for: .normal)
            buttonSwitch.backgroundColor = UDDatePickerTheme.calendarPickerTodaySelectedBgColor
            buttonSwitch.setTitleColor(UDDatePickerTheme.calendarPickerTodaySelectedTextColor, for: .normal)
            buttonSwitch.addTarget(self, action: #selector(switchAction), for: .touchUpInside)
            view.addSubview(buttonSwitch)
            buttonSwitch.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().offset(-100)
            }
            buttonPrev.layer.cornerRadius = 4
            buttonPrev.setTitle("<-", for: .normal)
            buttonPrev.backgroundColor = UDDatePickerTheme.calendarPickerTodaySelectedBgColor
            buttonPrev.setTitleColor(UDDatePickerTheme.calendarPickerTodaySelectedTextColor, for: .normal)
            buttonPrev.addTarget(self, action: #selector(prevAction), for: .touchUpInside)
            view.addSubview(buttonPrev)
            buttonPrev.snp.makeConstraints { (make) in
                make.centerY.equalTo(buttonSwitch.snp.centerY)
                make.right.equalTo(buttonSwitch.snp.left).offset(-5)
            }
            buttonNext.layer.cornerRadius = 4
            buttonNext.setTitle("->", for: .normal)
            buttonNext.backgroundColor = UDDatePickerTheme.calendarPickerTodaySelectedBgColor
            buttonNext.setTitleColor(UDDatePickerTheme.calendarPickerTodaySelectedTextColor, for: .normal)
            buttonNext.addTarget(self, action: #selector(nextAction), for: .touchUpInside)
            view.addSubview(buttonNext)
            buttonNext.snp.makeConstraints { (make) in
                make.centerY.equalTo(buttonSwitch.snp.centerY)
                make.left.equalTo(buttonSwitch.snp.right).offset(5)
            }
        }
    }

    @objc
    private func switchAction() {
        buttonSwitchClick?()
    }

    @objc
    private func prevAction() {
        buttonPrevClick?()
    }

    @objc
    private func nextAction() {
        buttonNextClick?()
    }

    func dateChanged(_ date: Date, _ sender: UniverseDesignDatePicker.UDDateCalendarPickerView) {
        let result = Calendar.current.dateComponents(in: .current, from: date)
        print(String(describing: result))
    }

    func calendarScrolledTo(_ date: Date) {
        let result = Calendar.current.dateComponents(in: .current, from: date)
        print("scrollToHere:\(result)")
    }
}

class PickerSampleCell: UITableViewCell {
    var tapClosure: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapInCell))
        self.contentView.addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func tapInCell() {
        tapClosure?()
    }
}
