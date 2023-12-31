//
//  MonthEmptyView.swift
//  Calendar
//
//  Created by zhu chao on 2018/10/25.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import UniverseDesignTheme
import UniverseDesignEmpty

final class MonthEmptyView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        let imgView = UIImageView()
        self.layoutImageView(imgView)
        let addLabel = ActiveLabel()
        self.layoutAddLabel(addLabel, imgView: imgView)
    }

    var createCallBack: (() -> Void)?

    private func layoutImageView(_ imgView: UIImageView) {
        let image = UDEmptyType.noSchedule.defaultImage()
        imgView.image = image
        self.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
            make.centerY.equalToSuperview().multipliedBy(309.0 * 2.0 / 680)
        }
    }

    private func layoutAddLabel(_ label: ActiveLabel, imgView: UIView) {
        let customType = ActiveType.custom(pattern: BundleI18n.Calendar.Calendar_Common_TipToCreate)
        label.enabledTypes = [customType]
        label.textColor = UIColor.ud.N600
        label.text = BundleI18n.Calendar.Calendar_Common_NoEvents + BundleI18n.Calendar.Calendar_Common_TipToCreate
        label.customColor[customType] = UIColor.ud.primaryContentDefault
        label.handleCustomTap(for: customType) { [weak self] _ in
            self?.createCallBack?()
            operationLog(optType: CalendarOperationType.monthAdd.rawValue)
        }
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalTo(imgView.snp.bottom).offset(12)
            make.centerX.equalTo(imgView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
