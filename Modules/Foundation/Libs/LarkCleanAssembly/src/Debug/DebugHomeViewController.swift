//
//  DebugHomeViewController.swift
//  LarkCleanAssembly
//
//  Created by 7Up on 2023/7/11.
//

#if !LARK_NO_DEBUG

import UIKit
import Foundation
import SnapKit
import EENavigator
import LarkClean
import LarkAlertController
import RxSwift
import LarkAccountInterface
import LarkContainer
import UniverseDesignDialog

final class DebugHomeViewController: UITableViewController {

    private struct RowTitleItem {
        var title: String
        var onSelect: () -> Void
    }

    private struct RowSwitchItem {
        var title: String
        var value: Bool
        var afterSwitch: () -> Void
    }

    private enum RowItem {
        case title(RowTitleItem)
        case `switch`(RowSwitchItem)
    }

    private struct SectionItem {
        var title: String
        var rows: [RowItem] = []

        mutating func appendTitleRow(title: String, onSelect: @escaping () -> Void) {
            rows.append(.title(.init(title: title, onSelect: onSelect)))
        }

        mutating func appendSectionRow(title: String, value: Bool, afterSwitch: @escaping () -> Void) {
            rows.append(.switch(.init(title: title, value: value, afterSwitch: afterSwitch)))
        }
    }

    private var sectionItems = [SectionItem]()
    private let disposeBag = DisposeBag()

    private func refreshSectionItems() {
        var sections = [SectionItem]()

        let newestCleanContext = {
            @Provider var passport: PassportService
            let userList = passport.userList.map { user in
                return CleanContext.User(userId: user.userID, tenantId: user.tenant.tenantID)
            }
            return CleanContext(userList: userList)
        }()

        var sec0 = SectionItem(title: "查看注册")
        sec0.appendTitleRow(title: "注册的 Index.Path") { [unowned self] in
            let vc = DebugPathViewController(cleanContext: newestCleanContext)
            vc.tip = "注意：没有出现在列表中的路径，表示没有注册到擦除流程中"
            Navigator.shared.push(vc, from: self)
        }
        sec0.appendTitleRow(title: "注册的 Index.Vkey") { [unowned self] in
            Navigator.shared.push(DebugVkeyViewController(cleanContext: newestCleanContext), from: self)
        }
        sec0.appendTitleRow(title: "注册的 Task") { [unowned self] in
            Navigator.shared.push(DebugTaskViewController(), from: self)
        }
        sections.append(sec0)

        var sec1 = SectionItem(title: "模拟开关")
        sec1.appendSectionRow(title: "模拟退登擦除失败", value: DebugSwitches.logoutCleanFail) { [unowned self] in
            DebugSwitches.logoutCleanFail = !DebugSwitches.logoutCleanFail
            self.resetData()
        }
        sec1.appendSectionRow(title: "模拟重试擦除失败", value: DebugSwitches.resumeCleanFail) { [unowned self] in
            DebugSwitches.resumeCleanFail = !DebugSwitches.resumeCleanFail
            self.resetData()
        }
        sec1.appendSectionRow(title: "模拟重置失败", value: DebugSwitches.resumeResetFail) { [unowned self] in
            DebugSwitches.resumeResetFail = !DebugSwitches.resumeResetFail
            self.resetData()
        }
        sec1.appendSectionRow(title: "模拟 RustSdk 擦除失败", value: DebugSwitches.rustCleanFail) { [unowned self] in
            DebugSwitches.rustCleanFail = !DebugSwitches.rustCleanFail
            self.resetData()
        }
        sections.append(sec1)

        if let lastCleanContext = LarkClean.lastCleanContext() {
            var sec = SectionItem(title: "查看最近擦除结果")
            sec.appendTitleRow(title: "Index.Path") { [unowned self] in
                let vc = DebugPathViewController(cleanContext: lastCleanContext)
                vc.tip = "注意：如下列表记录的是上次参与擦除的路径，如果路径仍然存在，则表示擦除失败"
                Navigator.shared.push(vc, from: self)
            }
            sec.appendTitleRow(title: "Index.Vkey") { [unowned self] in
                Navigator.shared.push(DebugVkeyViewController(cleanContext: lastCleanContext), from: self)
            }
            sections.append(sec)
        }

        self.sectionItems = sections
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        resetData()
    }

    private func resetData() {
        refreshSectionItems()
        tableView.reloadData()
    }

    private func rowItem(at indexPath: IndexPath) -> RowItem {
        let (section, row) = (indexPath.section, indexPath.row)
        return sectionItems[section].rows[row]
    }

    public override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionItems.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let headerLabel = UILabel()

        headerLabel.text = sectionItems[section].title
        headerLabel.font = .systemFont(ofSize: 16, weight: .bold)

        headerView.addSubview(headerLabel)

        headerLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.left.equalToSuperview().inset(16)
        }

        return headerView
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionItems[section].rows.count
    }

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let rowItem = rowItem(at: indexPath)
        switch rowItem {
        case .title(let item):
            cell.textLabel?.text = item.title
        case .switch(let item):
            cell.textLabel?.text = item.title
            let sw = UISwitch()
            sw.isOn = item.value
            sw.rx.controlEvent(.valueChanged).subscribe(onNext: { item.afterSwitch() }).disposed(by: disposeBag)
            cell.accessoryView = sw
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let rowItem = rowItem(at: indexPath)
        switch rowItem {
        case .title(let item):
            item.onSelect()
        case .switch(let item):
            item.afterSwitch()
        }
    }
}

/// Used for LarkCleanDev Demo
public func getLarkCleanDebugControllerType() -> UIViewController.Type {
    return DebugHomeViewController.self
}

#endif
