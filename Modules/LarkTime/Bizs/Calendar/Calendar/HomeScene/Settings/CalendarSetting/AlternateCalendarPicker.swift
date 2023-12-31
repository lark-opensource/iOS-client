//
//  AlternateCalendarPicker.swift
//  Calendar
//
//  Created by yantao on 2020/3/3.
//

import Foundation
import CalendarFoundation
import FigmaKit
import UIKit

final class AlternateCalendarPicker: UIView {

    private var doneCallBack: ((AlternateCalendarEnum) -> Void)

    let tableView: UITableView = {
        var tableView = InsetTableView()
        tableView.rowHeight = 48
        tableView.separatorStyle = .none
        tableView.allowsMultipleSelection = true
        tableView.backgroundColor = UIColor.clear
        tableView.contentInset = UIEdgeInsets(top: -18, left: 0, bottom: 0, right: 0)
        return tableView
    }()

    private var alternateCalendars: [AlternateCalendarEnum] = [
        .noneCalendar,
        .chineseLunarCalendar
    ]

    init(alternateCalendar: AlternateCalendarEnum, doneCallBack: @escaping ((AlternateCalendarEnum) -> Void)) {
        self.doneCallBack = doneCallBack
        super.init(frame: .zero)
        setupTableView(tableView)
        self.tableView.allowsMultipleSelection = false
        let index = getSelectedRow(from: alternateCalendar)
        tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
    }

    func getSelectedRow(from alternateCalendar: AlternateCalendarEnum) -> Int {
        for calendar in alternateCalendars.enumerated() {
            if calendar.element == alternateCalendar {
                return calendar.offset
            }
        }
        return 0
    }

    func getAlternateCalendar(from selectedRow: Int) throws -> AlternateCalendarEnum {
        return alternateCalendars[safeIndex: selectedRow] ?? .noneCalendar
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
extension AlternateCalendarPicker: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.alternateCalendars.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? NormalAlarmTypeCell,
            let value = alternateCalendars[safeIndex: indexPath.row] else {
            assertionFailureLog()
            return UITableViewCell()
        }
        if indexPath.row == 0 {
            cell.addCellBottomBorder()
        }
        cell.setText(value.toString())

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
            let alternateCalendar = try getAlternateCalendar(from: indexPath.row)
            self.doneCallBack(alternateCalendar)
        } catch {
            assertionFailureLog(error.localizedDescription)
        }
    }
}
