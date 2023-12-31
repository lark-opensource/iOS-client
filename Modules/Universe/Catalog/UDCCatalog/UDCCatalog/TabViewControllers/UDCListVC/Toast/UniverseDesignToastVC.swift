//
//  UniverseDesignToastVC.swift
//  UDCCatalog
//
//  Created by 潘灶烽 on 2020/10/20.
//  Copyright © 2020 潘灶烽. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignToast

class UniverseDesignToastVC: UIViewController {

    var tableView: UITableView = UITableView()
    var normalToastTitleData: [String] = ["常规提示-文字",
                                          "常规提示-文字2行",
                                          "常规提示-成功图标+文字",
                                          "常规提示-成功图标+文字2行",
                                          "常规提示-失败图标+文字",
                                          "常规提示-警告图标+文字",
                                          "常规提示-自定义图标+文字",
                                          "常规提示-loading图标+文字"]
    var operationToastTitleData: [String] = ["可操作提示-文字+操作",
                                             "可操作提示-文字2行+操作",
                                             "可操作提示-loading图标+操作",
                                             "可操作提示-图标+文字+操作",
                                             "可操作提示-图标+文字2行+操作"]
    var configToastTitleData: [String] = ["config常规提示-文字2行",
                                          "config可操作提示-图标+文字2行+操作",
                                          "config可操作提示-文字1行+竖排",
                                          "config可操作提示-图标+文字2行+竖排操作"]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UniverseDesignToast"

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
        self.tableView.separatorStyle = .singleLine
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "toastDemoCell")
        // Do any additional setup after loading the view.
    }

}

extension UniverseDesignToastVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return normalToastTitleData.count
        } else if section == 1 {
            return operationToastTitleData.count
        } else if section == 2 {
            return configToastTitleData.count
        } else if section == 3 {
            return 1
        } else {
            return 1
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "toastDemoCell") {
                cell.textLabel?.text = normalToastTitleData[indexPath.row]
                return cell
            }
        } else if indexPath.section == 1 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "toastDemoCell") {
                cell.textLabel?.text = operationToastTitleData[indexPath.row]
                return cell
            }
        } else if indexPath.section == 2 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "toastDemoCell") {
                cell.textLabel?.text = configToastTitleData[indexPath.row]
                return cell
            }
        } else if indexPath.section == 3 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "toastDemoCell") {
                cell.textLabel?.text = "复杂Toast场景测试"
                return cell
            }
        }
        return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "常规提示"
        } else if section == 1 {
            return "可操作提示"
        } else if section == 2 {
            return "config提示"
        } else if section == 3 {
            return "config提示，带输入框"
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                UDToast.showTips(with: "常规提示-文字", on: self.view, delay: 3)
            } else if indexPath.row == 1 {
                UDToast.showTips(with: "常规提示-文字2行 常规提示-文字2行 常规提示-文字2行", on: self.view, delay: 3)
            } else if indexPath.row == 2 {
                UDToast.showSuccess(with: "常规提示-成功图标+文字", on:self.view)
            } else if indexPath.row == 3 {
                UDToast.showSuccess(with: "常规提示-成功图标+文字2行 常规提示-成功图标+文字2行", on:self.view)
            } else if indexPath.row == 4 {
                UDToast.showFailure(with: "常规提示-失败图标+文字", on:self.view)
            } else if indexPath.row == 5 {
                UDToast.showWarning(with: "常规提示-警告图标+文字", on:self.view)
            } else if indexPath.row == 6 {
                UDToast.showCustom(with: "常规提示-自定义图标+文字", icon: UDIcon.tabCommunityOutlined, on: self.view)
            } else {
                UDToast.showLoading(with: "", on:self.view)
            }
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                UDToast.showTips(with: "可操作提示", operationText: "操作", on: self.view, delay: 3)
            }
            else if indexPath.row == 1 {
                UDToast.showTips(with: "常规提示-文字2行 常规提示-文字2行 常规提示-文字2行 常规提示-文字2行 常规提示-文字2行", operationText: "操作", on: self.view, delay: 3)
            }
            else if indexPath.row == 2 {
                UDToast.showLoading(with: "可操作提示-loading图标+操作", operationText: "操作", on: self.view) { (text) in
                    print("点击了\(text ?? "")")
                }
            }
            else if indexPath.row == 3 {
                UDToast.showSuccess(with: "可操作-图标+文字+操作", operationText: "操作", on: self.view, delay: 3) { (text) in
                    print("点击了\(text ?? "")")
                }
            }
            else if indexPath.row == 4 {
                UDToast.showFailure(with: "可操作-图标+文字2行+操作 可操作-图标+文字2行+操作", operationText: "操作", on: self.view, delay: 3) { (text) in
                    print("点击了\(text ?? "")")
                }
            }
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                var operation = UDToastOperationConfig(text: "操作")
                operation.displayType = .auto
                let config = UDToastConfig(toastType: .info, text: "常规提示-文字2行 常规提示-文字2行 常规提示-文字2行 常规提示-文字2行 常规提示-文字2行", operation: operation)
                UDToast.showToast(with: config, on: self.view, delay: 3)
            }
            else if indexPath.row == 1 {
                let operation = UDToastOperationConfig(text: "操作")
                let config = UDToastConfig(toastType: .warning, text: "config可操作提示-图标+文字2行+操作", operation: operation)
                UDToast.showToast(with: config, on: self.view, delay: 3)
            }
            else if indexPath.row == 2 {
                let operation = UDToastOperationConfig(text: "操作", displayType: .vertical)
                let config = UDToastConfig(toastType: .error, text: "config可操作提示-文字1行+竖排", operation: operation)
                UDToast.showToast(with: config, on: self.view, delay: 3)
            }
            else if indexPath.row == 3 {
                let operation = UDToastOperationConfig(text: "操作", displayType: .vertical)
                let config = UDToastConfig(toastType: .warning, text: "config可操作提示-图标+文字2行+竖排操作", operation: operation)
                UDToast.showToast(with: config, on: self.view, delay: 3)
            }
        }
        else if indexPath.section == 3 {
            let vc = UniverseDesignToastEditVC()
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
