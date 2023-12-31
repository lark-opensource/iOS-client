//
//  MultilineTextField.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/11/24.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UniverseDesignInput
import UIKit

class MultilineTextFieldVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private var dataSource: [(String?, UDMultilineTextField?)]

    init() {
        self.dataSource = [("普通文本样式", normalTextField),
                           ("数字统计类型", countTextField),
                           ("错误类型", errorTextField),
                           (nil, nil)]
        super.init(nibName: nil, bundle: nil)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints{ make in
            make.left.right.equalToSuperview()
            make.top.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.N100
        tableView.register(MultiInputCell.self, forCellReuseIdentifier: MultiInputCell.id)
        return tableView
    }()

    var isShowBorder = true

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.N100

        let rightBar = UIBarButtonItem(title: "切换边框",
                                       style: .plain,
                                       target: self,
                                       action: #selector(switchBorder))

        self.navigationItem.rightBarButtonItem = rightBar
    }

    private var normalTextField: UDMultilineTextField = {
        let textField = UDMultilineTextField()
        textField.config.isShowBorder = true
        textField.config.backgroundColor = .white
        return textField
    }()

    private var countTextField: UDMultilineTextField = {
        let textField = UDMultilineTextField()
        textField.config.isShowBorder = true
        textField.config.backgroundColor = .white
        textField.config.isShowWordCount = true
        return textField
    }()

    private var errorTextField: UDMultilineTextField = {
        let textField = UDMultilineTextField()
        textField.config.isShowBorder = true
        textField.config.backgroundColor = .white
        textField.config.errorMessege = "错误信息"
        textField.setStatus(.error)
        return textField
    }()

    @objc
    private func switchBorder() {
        isShowBorder = !isShowBorder
        for item in dataSource {
            item.1?.config.isShowBorder = isShowBorder
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MultiInputCell.id, for: indexPath)as! MultiInputCell
        cell.title = dataSource[indexPath.row].0
        cell.config = dataSource[indexPath.row].1?.config ?? nil
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 230
    }
}

class MultiInputCell: UITableViewCell {
    static var id = "tablecell"

    public var title: String? {
        didSet {
            guard let title = title else { return }
            self.titleLabel.text = title
            if title == "普通文本样式" {
                self.textField.input.isScrollEnabled = false
            }
            if title == "错误类型" {
                self.textField.setStatus(.error)
            }
        }
    }

    public var config: UDMultilineTextFieldUIConfig? {
        didSet {
            guard let config = config else { return }
            self.textField.config = config
        }
    }
    private lazy var titleLabel = UILabel()
    private lazy var textField: UDMultilineTextField = UDMultilineTextField()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = UITableViewCell.SelectionStyle.none
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(textField)
        self.contentView.backgroundColor = UIColor.ud.N100
        self.contentView.clipsToBounds = true

        titleLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(16)
        }

        textField.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.left.equalTo(titleLabel.snp.left)
            make.width.equalTo(250)
            make.height.equalTo(150)
        }
    }

    override func prepareForReuse() {
        self.titleLabel.text = nil
        self.textField = UDMultilineTextField()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
