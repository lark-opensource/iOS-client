//
//  UniverseDesignDialogVC.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/10/16.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UniverseDesignDialog
import UIKit
import UniverseDesignInput

class UniverseDesignDialogCell: UITableViewCell {
    lazy var title: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let title = UILabel(frame: CGRect(x: 20, y: 20, width: 300, height: 30))
        self.title = title

        self.contentView.addSubview(title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String) {
        self.title.text = title
    }
}

struct UDDialogData {
    var description: String
    var title: String?
    var content: String?
    var contentView: UIView?
    var normalCount: Int
    var secondaryCount: Int
    var destructiveCount: Int
    var style: UDDialogButtonLayoutStyle
    var text: String?

    init(description: String,
         title: String? = nil,
         content: String? = nil,
         contentView: UIView? = nil,
         normalCount: Int = 1,
         secondaryCount: Int = 0,
         destructiveCount: Int = 0,
         style: UDDialogButtonLayoutStyle = .normal,
         text: String? = nil
    ) {
        self.description = description
        self.title = title
        self.content = content
        self.contentView = contentView
        self.normalCount = normalCount
        self.secondaryCount = secondaryCount
        self.destructiveCount = destructiveCount
        self.style = style
        self.text = text
    }
}

class UniverseDesignDialogVC: UIViewController {
    var tableView: UITableView = UITableView()

    var dialog: UDDialog?

    var textField: UDTextField?

    lazy var dataSource: [UDDialogData] = [UDDialogData(description: "仅有标题", title: "仅有标题"),
                                      UDDialogData(description: "仅有内容", content: "仅有内容"),
                                      UDDialogData(description: "普通文字样式",
                                                   title: "标题",
                                                   content: "内容"),
                                      UDDialogData(description: "两列button",
                                                   title: "标题",
                                                   content: "内容",
                                                   normalCount: 2),
                                      UDDialogData(description: "两行button",
                                                   title: "标题",
                                                   content: "内容",
                                                   normalCount: 2,
                                                   style: .vertical),
                                      UDDialogData(description: "超过两个都为竖式布局",
                                                   title: "标题",
                                                   content: "内容",
                                                   normalCount: 1,
                                                   secondaryCount: 1,
                                                   destructiveCount: 1,
                                                   style: .vertical),
                                      UDDialogData(description: "自定义内容",
                                                   title: "标题",
                                                   contentView: {
                                                        let content = UIView()
                                                        return content
                                                    }()),
                                      UDDialogData(description: "输入框",
                                                   title: "标题",
                                                   contentView: {
        let content = UDTextField(config: UDTextFieldUIConfig(isShowBorder: true,
                                                              isShowTitle: false,
                                                              clearButtonMode: .always,
                                                              backgroundColor:  UIColor.ud.N900.withAlphaComponent(0.05),
                                                              borderColor: .gray,
                                                              textColor: UIColor.ud.N900,
                                                              placeholderColor: UIColor.ud.textPlaceholder))
        self.textField = content
        content.config.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        content.input.text = "go to setting"
        let wrapperView = UIView()
        wrapperView.addSubview(content)
        content.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(44)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        wrapperView.snp.makeConstraints { (make) in
            make.width.equalTo(303)
        }
        return wrapperView
    }(),
                                                   normalCount: 2)]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UniverseDesignDialog"

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
        self.tableView.register(UniverseDesignDialogCell.self, forCellReuseIdentifier: "cell")
    }
}

extension UniverseDesignDialogVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = dataSource[indexPath.row]

        var config = UDDialogUIConfig()
        config.style = item.style
        let dialog = UDDialog(config: config)

        if let title = item.title {
            dialog.setTitle(text: title)
        }

        if let content = item.content {
            dialog.setContent(text: content)
        }

        if let contentView = item.contentView {
            dialog.setContent(view: contentView)
        }

        for count in 0..<item.normalCount {
            if count == 1 && indexPath.row == 7 {
                let textfiled = item.contentView?.subviews[0] as? UDTextField
                dialog.addPrimaryButton(text: textfiled?.text ?? "")
            } else {
                dialog.addPrimaryButton(text: "确认\(count + 1)")
            }

        }

        for count in 0..<item.secondaryCount {
            dialog.addSecondaryButton(text: "次要操作\(count + 1)")
        }

        for count in 0..<item.destructiveCount {
            dialog.addDestructiveButton(text: "销毁\(count + 1)")
        }

        self.dialog = dialog
        self.present(dialog, animated: true, completion: {
            self.textField?.becomeFirstResponder()
        })
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? UniverseDesignDialogCell {
            cell.setTitle(dataSource[indexPath.row].description)
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }
}
