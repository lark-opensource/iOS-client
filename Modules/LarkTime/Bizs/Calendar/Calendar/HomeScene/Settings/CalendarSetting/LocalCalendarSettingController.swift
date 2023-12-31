//
//  LocalCalendarSettingController.swift
//  Calendar
//
//  Created by jiayi zou on 2018/9/18.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation

protocol LocalCalendarSettingControllerItem {
    var title: String { get }
    var isSelected: Bool { get set }
    var sourceIdentifier: String { get }
}

struct LocalCalendarSettingControllerItemImpl: LocalCalendarSettingControllerItem {
    var title: String

    var isSelected: Bool

    var sourceIdentifier: String
}

open class LocalCalendarSettingController: CalendarController {
    typealias Status = LocalCalendarManager.LocalCalendarAuthorizationStatus

    private var authStatus: Status

    var datasource: [LocalCalendarSettingControllerItem] = []
    private let tableView = UITableView()
    init() {
        self.authStatus = LocalCalendarManager.isLocalCalendarAccessable()
        super.init(nibName: nil, bundle: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        datasource = LocalCalendarManager.getVisibiltyItems(scenarioToken: .localCalendarSettingView)
        self.addBackItem()
        self.title = BundleI18n.Calendar.Calendar_Setting_LocalCalendars
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(LocalCalSettingCell.self, forCellReuseIdentifier: "LocalCalSettingCell")
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(12)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        tableView.backgroundColor = UIColor.ud.bgBase
    }

    required public init?(coder aDecoder: NSCoder) {
        self.authStatus = LocalCalendarManager.isLocalCalendarAccessable()
        super.init(coder: aDecoder)
        // fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    private func changeStatus(for index: Int, newStatus: Bool) {
        self.datasource[index].isSelected = newStatus
        LocalCalendarManager.localCalVisibiltyPublish.onNext(self.datasource)
        self.tableView.reloadData()
    }
}

extension LocalCalendarSettingController: UITableViewDelegate, UITableViewDataSource {
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.count
    }

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = LocalCalSettingCell()
        cell.selectionStyle = .none
        cell.selectionStatusChanged = { [weak self] (newValue) in
            self?.changeStatus(for: indexPath.row, newStatus: newValue)
        }
        cell.setModel(model: datasource[indexPath.row])
        return cell
    }
}

private final class LocalCalSettingCell: UITableViewCell {
    var selectionStatusChanged: ((Bool) -> Void)?
    private(set) var model: LocalCalendarSettingControllerItem?
    let content = LocalCalSettingContent()
    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(content)
        content.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        content.switcher.addTarget(self, action: #selector(switchStatusChanged), for: .valueChanged)
    }

    func setModel(model: LocalCalendarSettingControllerItem) {
        self.model = model
        self.content.titleLable.text = model.title
        self.content.switcher.isOn = model.isSelected
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func switchStatusChanged() {
        let status = content.switcher.isOn
        self.selectionStatusChanged?(status)
        if status == true {
            CalendarTracer.shareInstance.subscribeLocalCalendar(1)
        }
        CalendarTracer.shared.accountManagerClick(clickParam: "local", target: "none", isOpen: status == true)
    }
}

private final class LocalCalSettingContent: UIView {

    let titleLable = UILabel.cd.textLabel()

    let switcher = UISwitch.blueSwitch()

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        self.addSwitcher()
        self.addTitleLabel()
        let bottomLine = self.addBottomBorder()
        bottomLine.snp.makeConstraints { (make) in
            make.left.equalTo(titleLable)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addTitleLabel() {
        self.addSubview(titleLable)
        titleLable.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(NewEventViewUIStyle.Margin.leftMargin)
            make.right.lessThanOrEqualTo(switcher.snp.left).offset(-6).priority(.high)
        }
    }

    private func addSwitcher() {
        self.addSubview(switcher)
        switcher.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
    }
}
