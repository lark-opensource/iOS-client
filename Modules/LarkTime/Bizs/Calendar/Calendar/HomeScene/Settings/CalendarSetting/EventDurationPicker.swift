//
//  EventDurationPicker.swift
//  Calendar
//
//  Created by zc on 2018/5/24.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import CalendarFoundation
import FigmaKit
final class EventDurationPicker: UIView, UITableViewDelegate, UITableViewDataSource {
    var doneCallBack: ((Int) -> Void)?

    let tableView = InsetTableView()

    init(duration: Int) {
        super.init(frame: .zero)
        self.combineDuration(duration)
        commonInit()
        self.tableView.allowsMultipleSelection = false
        if let index = self.defaultDurations.firstIndex(where: { $0 == duration }) {
            tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
        }
    }

    func commonInit() {
        tableView.rowHeight = 48
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = true
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        tableView.register(NormalAlarmTypeCell.self, forCellReuseIdentifier: "Cell")
        self.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.contentInset = UIEdgeInsets(top: -18, left: 0, bottom: 0, right: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func combineDuration(_ duration: Int) {
        guard !self.defaultDurations.contains(duration) else {
            return
        }
        var currentDurations = self.defaultDurations
        currentDurations.append(duration)
        self.defaultDurations = currentDurations.sorted(by: { $0 < $1 })
    }

    private var defaultDurations: [Int] = [15, 30, 45, 60, 90, 120]

    // MARK: tableView delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.defaultDurations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? NormalAlarmTypeCell else {
            assertionFailureLog()
            return UITableViewCell()
        }
        let duration = self.defaultDurations[indexPath.row]
        cell.setText(BundleI18n.Calendar.Calendar_Plural_CommonMins(number: duration))

        if indexPath.row == defaultDurations.count - 1 {
            cell.showBorder(false)
        } else {
            cell.showBorder(true)
        }
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
        self.doneCallBack?(self.defaultDurations[indexPath.row])
    }
}
