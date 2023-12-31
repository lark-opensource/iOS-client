//
//  CalendarAccessRoleViewController.swift
//  Calendar
//
//  Created by heng zhu on 2019/3/22.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import SnapKit

extension CalendarAccessRoleViewController: CalendarAccessViewDelegate {
    func didSelect(index: Int) {
        func confirmAccess(access: CalendarAccess) {
            self.selectAccess(access)
            self.navigationController?.popViewController(animated: true)
        }
        let access = datasource[index].accessRole
        if access == .publicCalendar {
            EventAlert.showPublishCalendarMemberAlert(controller: self) {
                confirmAccess(access: access)
            }
        } else {
            confirmAccess(access: access)
        }
    }
}

final class CalendarAccessRoleViewController: CalendarController {
    private let accessView: CalendarAccessView
    let selectAccess: (_ access: CalendarAccess) -> Void
    let datasource: [CalendarAccessData]
    init(access: CalendarAccess, selectAccess: @escaping (_ access: CalendarAccess) -> Void) {
        self.selectAccess = selectAccess
        let privacyData = CalendarAccessData(title: BundleI18n.Calendar.Calendar_SubscribeCalendar_Private,
                                             subTitle: BundleI18n.Calendar.Calendar_Setting_PrivatesDescription,
                                             accessRole: .privacy)
        let freeBusyData = CalendarAccessData(title: BundleI18n.Calendar.Calendar_Setting_ShowOnlyFreeBusy,
                                              subTitle: BundleI18n.Calendar.Calendar_Setting_ShowOnlyFreeBusyDescription, accessRole: .freeBusy)
        let publicData = CalendarAccessData(title: BundleI18n.Calendar.Calendar_Edit_Public, subTitle: BundleI18n.Calendar.Calendar_Setting_PublicDescription, accessRole: .publicCalendar)
        datasource = [privacyData, freeBusyData, publicData]
        accessView = CalendarAccessView(dataSource: datasource, selectIndex: access.rawValue, withBottomBorder: true)
        super.init(nibName: nil, bundle: nil)
        accessView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.Calendar.Calendar_Setting_Permissions
        view.backgroundColor = UIColor.ud.bgBase
        addBackItem()

        view.addSubview(accessView)
        accessView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
        }
    }
}
