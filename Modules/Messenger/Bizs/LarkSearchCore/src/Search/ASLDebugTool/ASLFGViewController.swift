//
//  ASLFGViewController.swift
//  LarkSearchCore
//
//  Created by sunyihe on 2022/7/18.
//

import UIKit
import Foundation
import RxSwift
import UniverseDesignColor
import UniverseDesignToast
import LarkEMM
import LarkSensitivityControl
import LarkContainer

final class ASLFeatureGatingController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UserResolverWrapper {
    public let userResolver: LarkContainer.UserResolver
    private let tableView = UITableView()

    private var ASLFGCurrentData: [(String, String, Bool)] = []

    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
        updateFGData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViewAttr()

        self.view.addSubview(self.tableView)

        self.tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.tableView.reloadData()
    }

    private func updateFGData() {
        for fg in SearchFeatureGatingKey.allCases {
            ASLFGCurrentData.append((fg.description, fg.rawValue, fg.isUserEnabled(userResolver: self.userResolver)))
        }
        for fg in SearchDisableFGCollection.allCases {
            ASLFGCurrentData.append((fg.description, fg.rawValue, fg.isUserEnabled(userResolver: self.userResolver)))
        }
        for fg in SearchFeatureGatingKey.CommonRecommend.allCases {
            ASLFGCurrentData.append((fg.description, fg.rawValue, fg.isUserEnabled(userResolver: self.userResolver)))
        }
        for fg in AIFeatureGating.allCases {
            ASLFGCurrentData.append((fg.description, fg.rawValue, fg.isUserEnabled(userResolver: self.userResolver)))
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let featureGatingCell = tableView.dequeueReusableCell(
            withIdentifier: "ASLFeatureGatingCell",
            for: indexPath) as? ASLFeatureGatingCell else {
                return UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let currKey = ASLFGCurrentData[indexPath.row]
        featureGatingCell.descriptionLabel.text = currKey.0
        featureGatingCell.FGNameLabel.text = currKey.1
        featureGatingCell.valueLabel.text = "\(currKey.2)"
        return featureGatingCell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = ASLFGCurrentData.count
        return count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil,
              let superview = tableView.superview else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        let config = PasteboardConfig(token: Token("psda_token_avoid_intercept"))
        SCPasteboard.general(config).string = ASLFGCurrentData[indexPath.row].1
        UDToast.showSuccess(with: "复制成功", on: superview)
    }

    func setupViewAttr() {
        view.backgroundColor = UDColor.primaryOnPrimaryFill
        self.title = "AI&Search FG "

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭",
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(closeVC))

        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.tableHeaderView = nil
        self.tableView.tableFooterView = nil
        self.tableView.estimatedRowHeight = 300
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(ASLFeatureGatingCell.self, forCellReuseIdentifier: "ASLFeatureGatingCell")
    }

    @objc
    private func closeVC() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}

final class ASLFeatureGatingCell: UITableViewCell {
    let descriptionLabel = UILabel()
    let FGNameLabel = UILabel()
    let valueLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupViewAttr()

        self.contentView.addSubview(self.valueLabel)
        self.contentView.addSubview(self.descriptionLabel)
        self.contentView.addSubview(self.FGNameLabel)

        self.valueLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(self.contentView.snp.right)
        }
        self.descriptionLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.contentView.snp.top).inset(6)
            make.left.equalTo(self.contentView.snp.left).inset(16)
            make.right.lessThanOrEqualTo(valueLabel.snp.left).offset(-10)
        }
        self.FGNameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.descriptionLabel.snp.bottom).offset(2)
            make.bottom.equalTo(self.contentView.snp.bottom).inset(6)
            make.left.equalTo(self.contentView.snp.left).inset(16)
            make.right.lessThanOrEqualTo(valueLabel.snp.left).offset(-10)
        }
    }

    func setupViewAttr() {
        self.accessoryType = .disclosureIndicator

        self.valueLabel.font = UIFont.systemFont(ofSize: 15)
        self.valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        self.descriptionLabel.font = UIFont.systemFont(ofSize: 15)
        self.descriptionLabel.numberOfLines = 0

        self.FGNameLabel.font = UIFont.systemFont(ofSize: 10)
        self.FGNameLabel.numberOfLines = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
