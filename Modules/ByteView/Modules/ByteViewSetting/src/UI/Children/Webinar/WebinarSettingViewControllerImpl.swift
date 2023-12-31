//
//  WebinarSettingViewControllerImpl.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/15.
//

import Foundation
import ByteViewNetwork
import ByteViewUI

public enum WebinarSettingError: Error, LocalizedError, CustomStringConvertible {
    case hostCount
    case interpreterNotFull

    public var description: String {
        switch self {
        case .hostCount:
            return I18n.View_G_AddTenHostsMax
        case .interpreterNotFull:
            return I18n.Calendar_Edit_InterpretLangNoAdd_Toast
        }
    }

    public var errorDescription: String? {
        description
    }
}

public protocol WebinarSettingViewController: UIViewController {
    func saveWebinarSettings() -> Result<CalendarSettings, WebinarSettingError>
}

final class WebinarSettingViewControllerImpl: CalendarBaseSettingVC, WebinarSettingViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0))
    }

    func saveWebinarSettings() -> Result<ByteViewNetwork.CalendarSettings, WebinarSettingError> {
        if let vm = self.viewModel as? WebinarSettingViewModel {
            return vm.save()
        } else {
            fatalError("WebinarSettingViewController's viewModel is incorrect")
        }
    }
}
