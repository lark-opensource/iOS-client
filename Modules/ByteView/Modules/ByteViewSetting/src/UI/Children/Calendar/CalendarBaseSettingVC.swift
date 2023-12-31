//
//  CalendarBaseSettingVC.swift
//  ByteViewSetting
//
//  Created by lutingting on 2023/8/31.
//

import Foundation
import ByteViewCommon
import ByteViewTracker
import UniverseDesignColor
import UniverseDesignToast
import ByteViewNetwork
import ByteViewUI
import UniverseDesignIcon

class CalendarBaseSettingVC: SettingViewController {

    // nolint-next-line: magic number
    override var emptyHeaderHeight: CGFloat { 14.5 }
    // nolint-next-line: magic number
    override var emptyFooterHeight: CGFloat { 14 }

    override func viewDidLoad() {
        super.viewDidLoad()

        let bgColor: UIColor = .ud.bgFloat
        self.view.backgroundColor = bgColor
        setNavigationBarBgColor(bgColor)
        // nolint-next-line: magic number
        tableView.estimatedRowHeight = 48
        tableView.backgroundColor = UIColor.ud.bgFloat
        tableView.separatorStyle = .none
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 兜底恢复webinar日程设置页naviBar的背景色
        navigationController?.vc.updateBarStyle(preferredNavigationBarStyle)
    }

    override func createTableView() -> UITableView {
        return BaseTableView(frame: .zero, style: .grouped)
    }

    override func headerContentInsets(isFirst: Bool) -> UIEdgeInsets {
        // nolint-next-line: magic number
        let top: CGFloat = isFirst ? 8 : 22.5
        let contentInsets = UIEdgeInsets(top: top, left: 0, bottom: 4, right: 0)
        return contentInsets
    }

    override func shouldShowSeparator(isHeader: Bool, isFirst: Bool) -> Bool {
        return isHeader && !isFirst
    }
}
