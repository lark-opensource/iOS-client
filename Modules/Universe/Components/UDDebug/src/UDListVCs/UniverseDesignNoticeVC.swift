//
//  UniverseDesignNoticeVC.swift
//  UDCCatalog
//
//  Created by 龙伟炜 on 2020/10/12.
//  Copyright © 2020 龙伟炜. All rights reserved.
//

#if !LARK_NO_DEBUG

import UIKit
import Foundation
import UniverseDesignNotice
import UniverseDesignIcon
import UniverseDesignColor

class UniverseDesignNoticeCell: UITableViewCell {
    let udNoticeView: UDNotice

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let config = UDNoticeUIConfig(type: .info, attributedText: NSAttributedString())
        udNoticeView = UDNotice(config: config)

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(udNoticeView)
        udNoticeView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.width.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateConfig(config: UDNoticeUIConfig) {
        udNoticeView.updateConfigAndRefreshUI(config)
    }
}

class UniverseDesignNoticeVC: UIViewController {
    var tableView: UITableView = UITableView()

    var dataSource: [UDNoticeUIConfig] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UniverseDesignNotice"
        self.view.backgroundColor = UIColor.ud.bgBody
//        addOnList()
        addOnView()
    }

    /// 样式展示
    func addOnList() {
        setupUI()
        loadData()
    }

    /// 普通使用
    func addOnView() {
        /// 手动布局
        var infoConfig = UDNoticeUIConfig(type: .info,
                                          attributedText: NSAttributedString(string: "end This is a text message for a regular prompt, and a text message for a regular prompt start"))
        infoConfig.leadingButtonText = "设置"
        infoConfig.trailingButtonIcon = UDIcon.closeOutlined
        infoConfig.autoScrollable = true
        infoConfig.speed = 30
        infoConfig.direction = .right
        dataSource.append(infoConfig)

        let udNoticeView = UDNotice(config: infoConfig)
        udNoticeView.delegate = self
        let udNoticeViewSize = udNoticeView.sizeThatFits(view.bounds.size)
        udNoticeView.frame = CGRect(x: 0, y: 100,
                                    width: udNoticeViewSize.width, height: udNoticeViewSize.height)
        view.addSubview(udNoticeView)

        /// 自动布局
        var infoConfig1 = UDNoticeUIConfig(type: .info,
                                           attributedText:
                                            NSAttributedString(string: "start This is a text message for a regular prompt, and a text message for a regular prompt end"))
        infoConfig1.leadingButtonText = "取消自动审批设置"
        infoConfig1.trailingButtonIcon = UDIcon.closeOutlined
        infoConfig1.autoScrollable = true
        addNotice(160, infoConfig1)

        let buttonAttributedStr = NSMutableAttributedString(string: "这是一条单行常驻提示的描述文本")
        buttonAttributedStr.addAttributes([NSAttributedString.Key.link: "UDNOTICE://buttonAttr"],
                                          range: NSMakeRange(buttonAttributedStr.length - 2, 2))
        var buttonConfig = UDNoticeUIConfig(type: .info,
                                            attributedText: buttonAttributedStr)
        buttonConfig.leadingButtonText = "操作"
        addNotice(280, buttonConfig)

        let successConfig = UDNoticeUIConfig(type: .success,
                                             attributedText: NSAttributedString(string: "这是一条成功提示的文本信息", attributes: [
                                                .foregroundColor: UIColor.ud.colorfulRed
                                             ]))
        addNotice(350, successConfig)

        let warningConfig = UDNoticeUIConfig(type: .warning,
                                             attributedText: NSAttributedString(string: "这是一条警示提示的文本信息", attributes: [
                                                .foregroundColor: UIColor.ud.colorfulRed
                                             ]))
        addNotice(420, warningConfig)

        var errorConfig = UDNoticeUIConfig(type: .error,
                                           attributedText: NSAttributedString(string: "邮箱容量已满，服务暂停，请及时升级套餐"))
        errorConfig.leadingButtonText = "联系在线客服"
        addNotice(490, errorConfig)
    }

    private func addNotice(_ top: CGFloat, _ config: UDNoticeUIConfig) {
        let udNoticeView = UDNotice(config: config)
        udNoticeView.delegate = self
        view.addSubview(udNoticeView)
        udNoticeView.snp.makeConstraints { (make) in
            make.leading.width.equalToSuperview()
            make.top.equalTo(top)
        }
    }

    func loadData() {
        var infoConfig = UDNoticeUIConfig(type: .info,
                                          attributedText: NSAttributedString(string: "这是一条常规提示的文本信息信息信息"))
        infoConfig.leadingButtonText = "取消自动审批设置"
        infoConfig.trailingButtonIcon = UDIcon.closeOutlined
        dataSource.append(infoConfig)

        var infoConfig1 = UDNoticeUIConfig(type: .info,
                                           attributedText: NSAttributedString(string: "这是一条常规提示的文本信息信息"))
        infoConfig1.leadingButtonText = "设置"
        infoConfig1.trailingButtonIcon = UDIcon.closeOutlined
        dataSource.append(infoConfig1)

        let successConfig = UDNoticeUIConfig(type: .success,
                                             attributedText: NSAttributedString(string: "这是一条成功提示的文本信息", attributes: [
                                                .foregroundColor: UIColor.ud.colorfulRed
                                             ]))
        dataSource.append(successConfig)

        let warningConfig = UDNoticeUIConfig(type: .warning,
                                             attributedText: NSAttributedString(string: "这是一条警示提示的文本信息", attributes: [
                                                .foregroundColor: UIColor.ud.colorfulRed
                                             ]))
        dataSource.append(warningConfig)

        let errorConfig = UDNoticeUIConfig(type: .error,
                                           attributedText: NSAttributedString(string: "这是一条错误提示的文本信息", attributes: [
                                            .foregroundColor: UIColor.ud.colorfulRed
                                         ]))
        dataSource.append(errorConfig)

        let str = "这是一条常驻提示，这是当内容过长时的折行的效果，点击文字链"
        let linkAttributedStr = NSMutableAttributedString(string: str)
        linkAttributedStr.addAttributes([NSAttributedString.Key.link: "UDNOTICE://button1"],
                                    range: NSMakeRange(linkAttributedStr.length - 3, 3))
        linkAttributedStr.addAttributes([NSAttributedString.Key.link: "UDNOTICE://button2"],
                                    range: NSMakeRange(linkAttributedStr.length - 8, 2))
        var linkButtonConfig = UDNoticeUIConfig(backgroundColor: UIColor.ud.primaryColor2,
                                                attributedText: linkAttributedStr)
        linkButtonConfig.leadingIcon = UDIcon.infoColorful
        dataSource.append(linkButtonConfig)

        let linkAttributedStr1 = NSMutableAttributedString(string: str)
        linkAttributedStr1.addAttributes([NSAttributedString.Key.link: "UDNOTICE://button"],
                                    range: NSMakeRange(linkAttributedStr1.length - 3, 3))
        var linkButtonWithCloseConfig = UDNoticeUIConfig(backgroundColor: UIColor.ud.primaryColor2,
                                                         attributedText: linkAttributedStr1)
        linkButtonWithCloseConfig.leadingIcon = UDIcon.infoColorful
        linkButtonWithCloseConfig.trailingButtonIcon = UDIcon.closeOutlined
        dataSource.append(linkButtonWithCloseConfig)

        let str2 = "This permission has been automatically approved due to your Settings."
        let buttonStr2 = "Cancel automatic approval"
        let linkAttributedStr2 = NSMutableAttributedString(string: str2 + buttonStr2)
        linkAttributedStr2.addAttributes([NSAttributedString.Key.link: "UDNOTICE://button2"],
                                         range: NSMakeRange(linkAttributedStr2.length - buttonStr2.count,
                                                            buttonStr2.count))
        var linkButtonConfig2 = UDNoticeUIConfig(backgroundColor: UIColor.ud.primaryColor2,
                                                attributedText: linkAttributedStr2)
        linkButtonConfig2.leadingIcon = UDIcon.infoColorful
        linkButtonConfig2.leadingButtonText = "Cancel automatic approval"
        dataSource.append(linkButtonConfig2)

        var accessoryConfig = UDNoticeUIConfig(type: .info,
                                               attributedText: NSAttributedString(string: "这是一条常驻提示的文本信息文本信息信息信"))
        accessoryConfig.trailingButtonIcon = UDIcon.rightOutlined
        dataSource.append(accessoryConfig)

        let buttonAttributedStr = NSMutableAttributedString(string: "这是一条单行常驻提示的描述文本")
        buttonAttributedStr.addAttributes([NSAttributedString.Key.link: "UDNOTICE://buttonAttr"],
                                          range: NSMakeRange(buttonAttributedStr.length - 2, 2))
        var buttonConfig = UDNoticeUIConfig(type: .info,
                                            attributedText: buttonAttributedStr)
        buttonConfig.leadingButtonText = "操作"
        dataSource.append(buttonConfig)

        tableView.reloadData()

        /// tableview cell未展示完毕时contentView高度未确定无法精准布局j，兼容测试代码↓
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.tableView.reloadData()
        }
    }

    func setupUI() {
        let rightBar = UIBarButtonItem(title: "修改字号",
                                       style: .plain,
                                       target: self,
                                       action: #selector(changeFontSize))

        self.navigationItem.rightBarButtonItem = rightBar

        self.tableView = UITableView(frame: self.view.bounds, style: .plain)
        self.view.addSubview(tableView)
        self.tableView.frame = CGRect(x: 0,
                                      y: 88,
                                      width: self.view.bounds.width,
                                      height: self.view.bounds.height - 88)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 44
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.cellLayoutMarginsFollowReadableWidth = false
        self.tableView.layoutMargins = .zero
        self.tableView.separatorInset = .zero
        self.tableView.register(UniverseDesignNoticeCell.self, forCellReuseIdentifier: "Cell")
    }

    @objc
    func changeFontSize() {
        guard let cells = cells(for: tableView) else { return }
        for cell in cells {
            cell.udNoticeView.font =
                (cell.udNoticeView.font == UIFont.ud.body0 ? UIFont.systemFont(ofSize: 18.0) : UIFont.ud.body0)
            cell.udNoticeView.update()
        }

        tableView.reloadData()
    }

    func cells(for tableView: UITableView?) -> [UniverseDesignNoticeCell]? {
        let sections = tableView?.numberOfSections ?? 0
        var cells: [UniverseDesignNoticeCell] = []
        for section in 0..<sections {
            let rows = tableView?.numberOfRows(inSection: section) ?? 0
            for row in 0..<rows {
                let indexPath = IndexPath(row: row, section: section)
                if let cell = tableView?.cellForRow(at: indexPath),
                    let noticeCell = cell as? UniverseDesignNoticeCell {
                    cells.append(noticeCell)
                }
            }
        }
        return cells
    }
}

extension UniverseDesignNoticeVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
                                                    for: indexPath) as? UniverseDesignNoticeCell {
            cell.updateConfig(config: dataSource[indexPath.row])
            cell.udNoticeView.delegate = self
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

}

extension UniverseDesignNoticeVC: UDNoticeDelegate {
    func handleLeadingButtonEvent(_ button: UIButton) {
        print("handleLeadingButtonEvent: \(button)")
        let alert = UIAlertController(title: nil, message: "handleLeadingButtonEvent", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func handleTrailingButtonEvent(_ button: UIButton) {
        print("handleTrailingButtonEvent: \(button)")
        let alert = UIAlertController(title: nil, message: "handleTrailingButtonEvent", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        print("handleTextButtonEvent: \(URL) \(characterRange)")
        let alert = UIAlertController(title: nil, message: "handleTextButtonEvent", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

#endif
