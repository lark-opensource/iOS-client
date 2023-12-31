//
//  SelectCountryNumberView.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/9/12.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkCore
import LarkSDKInterface

final class SelectCountryNumberView: UIView {
    fileprivate var tableView: UITableView = .init(frame: .zero)
    fileprivate var hotDatasource: [LarkSDKInterface.MobileCode] = []
    fileprivate var allDatasource: [LarkSDKInterface.MobileCode] = []
    var selectAction: ((_ number: String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N00
        self.layer.cornerRadius = 4
        initializeTableView()

        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
        titleLabel.text = BundleI18n.LarkContact.Lark_Legacy_SelectCountryOrArea
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(11)
        }

        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(11)
        }
    }

    func setDatasource(hotDatasource: [LarkSDKInterface.MobileCode], allDatasource: [LarkSDKInterface.MobileCode]) {
        self.hotDatasource = hotDatasource
        self.allDatasource = allDatasource
        self.tableView.reloadData()
    }

    private func initializeTableView() {
        self.tableView = UITableView(frame: .zero, style: .grouped)
        self.tableView.separatorColor = UIColor.ud.N00
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 52
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.layer.cornerRadius = 4
        self.tableView.backgroundColor = UIColor.ud.N00
        self.tableView.sectionFooterHeight = 0
        self.tableView.contentInsetAdjustmentBehavior = .never
        let name = String(describing: SelectCountryNumberCell.self)
        self.tableView.register(SelectCountryNumberCell.self, forCellReuseIdentifier: name)
        self.addSubview(self.tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SelectCountryNumberView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        let data = indexPath.section == 0 ? hotDatasource[indexPath.row] : allDatasource[indexPath.row]
        self.selectAction?(data.code)
    }
}

extension SelectCountryNumberView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.ud.N00

        let topLine = UIView()
        topLine.backgroundColor = UIColor.ud.N300
        headerView.addSubview(topLine)
        topLine.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }

        let headerLabel = UILabel()
        headerLabel.textColor = UIColor.ud.N600
        headerLabel.textAlignment = .left
        headerLabel.font = UIFont.systemFont(ofSize: 11)
        headerLabel.text = (section == 0) ? BundleI18n.LarkContact.Lark_Legacy_PopularCountryOrArea : BundleI18n.LarkContact.Lark_Legacy_AllCountryOrArea
        headerView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
        }

        let bottomLine = UIView()
        bottomLine.backgroundColor = UIColor.ud.N300
        headerView.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { (make) in
            make.top.equalTo(headerLabel.snp.bottom).offset(6)
            make.left.right.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 29
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? hotDatasource.count : allDatasource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let name = String(describing: SelectCountryNumberCell.self)
        let datasource = indexPath.section == 0 ? hotDatasource : allDatasource
        if let cell = tableView.dequeueReusableCell(withIdentifier: name) as? SelectCountryNumberCell {
            cell.set(country: datasource[indexPath.row].displayName, number: datasource[indexPath.row].code)
            if indexPath.row == datasource.count - 1 {
                cell.bottomSeperator.isHidden = true
            }
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }
}
