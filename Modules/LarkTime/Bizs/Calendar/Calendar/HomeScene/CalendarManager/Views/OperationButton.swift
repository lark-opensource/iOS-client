//
//  OperationButton.swift
//  Calendar
//
//  Created by heng zhu on 2019/3/25.
//

import Foundation
import CalendarFoundation
import UIKit
import SnapKit

final class OperationButton: UIControl, AddBottomLineAble {
    enum ButtonType {
        case deleteMember
        case deleteCalendar
        case unsubscribeCalendar
        case unImportCalendar
        case reauthorizeCalendar
    }

    struct OperationButtonModel {
        let title: String
        let color: UIColor
    }

    static func getData(with type: OperationButton.ButtonType) -> OperationButtonModel {
        switch type {
        case .deleteMember:
            return OperationButtonModel(title: BundleI18n.Calendar.Calendar_Setting_DeleteMember, color: UIColor.ud.functionDangerContentDefault)
        case .deleteCalendar:
            return OperationButtonModel(title: BundleI18n.Calendar.Calendar_Setting_DeleteCalendar, color: UIColor.ud.functionDangerContentDefault)
        case .unsubscribeCalendar:
            return OperationButtonModel(title: BundleI18n.Calendar.Calendar_Setting_UnsubscribeCalendar, color: UIColor.ud.N800)
        case .unImportCalendar:
            return OperationButtonModel(title: BundleI18n.Calendar.Calendar_GoogleCal_CancelImport, color: UIColor.ud.functionDangerContentDefault)
        case .reauthorizeCalendar:
            return OperationButtonModel(title: BundleI18n.Calendar.Calendar_Ex_ReauthorizeButton, color: UIColor.ud.colorfulBlue)
        }
    }

    var label = UILabel()
    init(model: OperationButtonModel) {
        label.text = model.title
        label.textColor = model.color
        label.font = UIFont.cd.regularFont(ofSize: 16)
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        addSubview(label)

        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        self.snp.makeConstraints { (make) in
            make.height.equalTo(52)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
