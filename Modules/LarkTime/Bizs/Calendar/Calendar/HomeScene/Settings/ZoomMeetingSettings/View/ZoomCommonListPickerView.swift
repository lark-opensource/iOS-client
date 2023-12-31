//
//  ZoomCommonListPickerView.swift
//  Calendar
//
//  Created by pluto on 2022/11/1.
//

import UIKit
import Foundation
import CalendarFoundation
import FigmaKit

// 单选选择器
final class ZoomCommonListPickerView: UIView, UITableViewDelegate, UITableViewDataSource {

    var didSelectCallBack: ((Int) -> Void)?
    private var pickerList: [String] = []

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = 48
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = false
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.allowsMultipleSelection = false
        tableView.register(NormalAlarmTypeCell.self, forCellReuseIdentifier: "Cell")
        tableView.bounces = false
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()

    init(picked: Int, pickerList: [String]) {
        super.init(frame: .zero)
        self.pickerList = pickerList
        layoutTableView()
        setDefaultPicked(picked: picked)
    }

    private func setDefaultPicked(picked: Int) {
        if picked < pickerList.count, picked >= 0 {
            tableView.selectRow(at: IndexPath(row: picked, section: 0), animated: false, scrollPosition: .none)
        }
    }

    private func layoutTableView() {
        self.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: tableView delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.pickerList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? NormalAlarmTypeCell else {
            assertionFailureLog()
            return UITableViewCell()
        }
        let item = self.pickerList[indexPath.row]
        cell.setText(item)
        cell.showBorder(false)
        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let selectedIndex = tableView.indexPathsForSelectedRows else {
            return indexPath
        }
        if selectedIndex.contains(indexPath) && selectedIndex.count > 1 {
            tableView.deselectRow(at: indexPath, animated: false)
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.didSelectCallBack?(indexPath.row)
    }
}
