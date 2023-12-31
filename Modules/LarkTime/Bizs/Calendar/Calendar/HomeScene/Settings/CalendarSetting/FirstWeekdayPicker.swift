//
//  FirstWeekdayPicker.swift
//  Calendar
//
//  Created by harry zou on 2019/2/15.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkTimeFormatUtils
import FigmaKit

enum DaysOfWeekError: Error {
    case invaildRawValue
}

final class FirstWeekdayPicker: UIView {

    private var doneCallBack: ((DaysOfWeek) -> Void)

    let tableView: UITableView = {
        let tableView = InsetTableView()
        tableView.rowHeight = 48
        tableView.contentInset = UIEdgeInsets(top: -18, left: 0, bottom: 0, right: 0)
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = true
        tableView.backgroundColor = UIColor.clear
        return tableView
    }()

    private var weekdays: [String] = [TimeFormatUtils.weekdayFullString(weekday: 7),
                                       TimeFormatUtils.weekdayFullString(weekday: 1),
                                       TimeFormatUtils.weekdayFullString(weekday: 2)]

    init(firstWeekday: DaysOfWeek, doneCallBack: @escaping ((DaysOfWeek) -> Void)) {
        self.doneCallBack = doneCallBack
        super.init(frame: .zero)
        setupTableView(tableView)
        self.tableView.allowsMultipleSelection = false
        let index = getSelectedRow(from: firstWeekday)
        tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
    }

    func getSelectedRow(from firstWeekday: DaysOfWeek) -> Int {
        return firstWeekday.rawValue % 7
    }

    func getDaysOfWeek(from selectedRow: Int) throws -> DaysOfWeek {
        guard let dayOfWeek = DaysOfWeek(rawValue: (selectedRow + 6) % 7 + 1) else {
            throw DaysOfWeekError.invaildRawValue
        }
        return dayOfWeek
    }

    private func setupTableView(_ tableView: UITableView) {
        tableView.register(NormalAlarmTypeCell.self, forCellReuseIdentifier: "Cell")
        tableView.delegate = self
        tableView.dataSource = self
        self.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension FirstWeekdayPicker: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.weekdays.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? NormalAlarmTypeCell,
            let text = weekdays[safeIndex: indexPath.row] else {
            assertionFailureLog()
            return UITableViewCell()
        }
        cell.setText(text)

        let needHideBottomLine = indexPath.row == weekdays.count - 1
        cell.showBorder(!needHideBottomLine)

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
        do {
            let newFirstWeekday = try getDaysOfWeek(from: indexPath.row)
            self.doneCallBack(newFirstWeekday)
        } catch {
            assertionFailureLog(error.localizedDescription)
        }
    }
}
