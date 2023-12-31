//
//  UniverseDesignColorPickerVC.swift
//  UDCCatalog
//
//  Created by admin on 2020/11/20.
//  Copyright © 2020 潘灶烽. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColorPicker

class UniverseDesignColorPickerVC: UIViewController {

    var tableView: UITableView = UITableView()
    var titleData: [String] = ["基础Default颜色Panel", "基础Default颜色ActionSheet", "字体颜色ActionSheet", "字体颜色ActionSheet+Custom", "All"]


    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UniverseDesignColorPicker"

        self.tableView = UITableView(frame: self.view.bounds, style: .plain)
        self.view.addSubview(tableView)
        self.tableView.frame.origin.y = 88
        self.tableView.frame = CGRect(x: 0,
                                      y: 88,
                                      width: self.view.bounds.width,
                                      height: self.view.bounds.height - 88)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 68
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "colorPickerDemoCell")
    }
}

extension UniverseDesignColorPickerVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleData.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "colorPickerDemoCell") {
            cell.textLabel?.textColor = UIColor.ud.N00
            cell.textLabel?.text = titleData[indexPath.row]
            if indexPath.row == 0 {
                cell.backgroundColor = UIColor.ud.R800
            } else if indexPath.row == 1 {
                cell.backgroundColor = UIColor.ud.S700
            } else if indexPath.row == 2 {
                cell.backgroundColor = UIColor.ud.B700
            } else if indexPath.row == 3 {
                cell.backgroundColor = UIColor.ud.P400
            } else {
                cell.backgroundColor = UIColor.ud.Y400
            }
            return cell
        }
        return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "ColorPicker"
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                if let config = UniverseDesignColorPickerVC.getBasicColorConfig() {
                    let colorPicker = UniverseDesignColorPickerDetailVC(config: config)
                    self.navigationController?.pushViewController(colorPicker, animated: true)
                }
            } else if indexPath.row == 1 {
                if let config = UniverseDesignColorPickerVC.getBasicColorConfig() {
                    let colorPicker = UDColorPickerActionSheet(config: config, height: 230)
                    self.present(colorPicker, animated: true, completion: nil)
                }
            } else if indexPath.row == 2 {
                if let config = UniverseDesignColorPickerVC.getTextConfig() {
                    let colorPicker = UDColorPickerActionSheet(config: config)
                    self.present(colorPicker, animated: true, completion: nil)
                }
            } else if indexPath.row == 3 {
                let config = UniverseDesignColorPickerVC.getJsonTextConfig()
                if let config = config {
                    let colorPicker = UDColorPickerActionSheet(config: config)
                    self.present(colorPicker, animated: true, completion: nil)
                }
            } else if indexPath.row == 4 {
                let config = UniverseDesignColorPickerVC.getAllConfig()
                if let config = config {
                    let colorPicker = UDColorPickerActionSheet(config: config, height: 450)
                    self.present(colorPicker, animated: true, completion: nil)
                }
            }
        }
    }
}

extension UniverseDesignColorPickerVC {

    private static func getBasicColorModel() -> UDPaletteModel? {
        //基础颜色
        let model = UDColorPickerConfig.defaultModel(category: .basic, title: "选择颜色")
        return model
    }

    private static func getTextModel() -> UDPaletteModel? {
        //文本
        let model = UDColorPickerConfig.defaultModel(category: .text, title: "字体颜色")
        return model
    }

    private static func getBackgroundModel() -> UDPaletteModel? {
        //背景
        let model = UDColorPickerConfig.defaultModel(category: .background, title: "字体背景颜色")
        return model
    }

    private static func getBasicColorConfig() -> UDColorPickerConfig? {

        if let model = UniverseDesignColorPickerVC.getBasicColorModel() {
            let config = UDColorPickerConfig(models: [model])
            return config
        } else {
            return nil
        }
    }

    private static func getTextConfig() -> UDColorPickerConfig? {

        if let model1 = UniverseDesignColorPickerVC.getTextModel(), let model2 = UniverseDesignColorPickerVC.getBackgroundModel() {
            let config = UDColorPickerConfig(models: [model1, model2])
            return config
        } else {
            return nil
        }
    }

    private static func getTextModelByJson() -> UDPaletteModel? {
        let path = Bundle.main.path(forResource: "colorPicker-text-category", ofType: "geojson")
        do {
            let jsonStr = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
            if let jsonData = jsonStr.data(using: .utf8) {
                if let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    if let title = dictionary["title"] as? String, let category = dictionary["category"] as? String, let parameters = dictionary["items"] as? [[String: Any]], let selectedIndex = dictionary["selectedIndex"] as? Int {
                        let model = UniverseDesignColorPickerVC.getPaletteItem(type: category, title: title, params: parameters, selectedIndex: selectedIndex)
                        return model
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }

    private static func getBackgroundModelByJson() -> UDPaletteModel? {
        let path = Bundle.main.path(forResource: "colorPicker-background-category", ofType: "geojson")
        do {
            let jsonStr = try String(contentsOfFile: path!, encoding: String.Encoding.utf8)
            if let jsonData = jsonStr.data(using: .utf8) {
                if let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    if let title = dictionary["title"] as? String, let category = dictionary["category"] as? String, let parameters = dictionary["items"] as? [[String: Any]], let selectedIndex = dictionary["selectedIndex"] as? Int  {
                        let model = UniverseDesignColorPickerVC.getPaletteItem(type: category, title: title, params: parameters, selectedIndex: selectedIndex)
                        return model
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }

    private static func getJsonTextConfig() -> UDColorPickerConfig? {

        if let model1 = UniverseDesignColorPickerVC.getTextModelByJson(), let model2 = UniverseDesignColorPickerVC.getBackgroundModelByJson() {
            let config = UDColorPickerConfig(models: [model1, model2])
            return config
        } else {
            return nil
        }
    }

    private static func getAllConfig() -> UDColorPickerConfig? {

        if let model1 = UniverseDesignColorPickerVC.getBasicColorModel(), let model2 = UniverseDesignColorPickerVC.getTextModel(), let model3 = UniverseDesignColorPickerVC.getBackgroundModel() {
            let config = UDColorPickerConfig(models: [model1, model2, model3])
            return config
        } else {
            return nil
        }
    }
}

extension UniverseDesignColorPickerVC {
    static func getPaletteItem(type: String, title: String, params: [[String: Any]], selectedIndex: Int = 0) -> UDPaletteModel{
        var category:UDPaletteItemsCategory = .basic
        if type == "common" {
            category = .basic
        } else if type == "text" {
            category = .text
        } else if type == "background" {
            category = .background
        }

        let items = UniverseDesignColorPickerVC.makeItems(params)

        return UDPaletteModel.init(category: category, title: title, items: items, selectedIndex: selectedIndex)
    }

    /// 构建 Model 对的 item 列表
    /// - Parameters:
    ///   - params: 每个 Model 对应的字典。包含 Item List
    ///   - category: Model 的分类
    ///   - selected: 当前选中是那个 Item。放在这里能最少地减少遍历次数
    static func makeItems(_ params: [[String: Any]]) -> [UDPaletteItem] {
        return params.compactMap {
            if let colorInfo = $0["value"] as? [String: CGFloat] {
                let color = UIColor(red: (colorInfo["r"] ?? 255.0) / 255.0, green: (colorInfo["g"] ?? 255.0) / 255.0, blue: (colorInfo["b"] ?? 255.0) / 255.0, alpha: colorInfo["a"] ?? 1.0)
                return UDPaletteItem(color: color)
            }
            return nil
        }
    }
}
