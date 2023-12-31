//
//  NotificationDiagnosisResultCell.swift
//  UITestDemo
//
//  Created by panbinghua on 2022/3/8.
//

import Foundation
import UIKit
import UniverseDesignIcon
import LarkSettingUI

final class NotificationDiagnosisResultCellProp: NormalCellProp {

    enum ResultType {
        case warning
        case error
    }

    var type: ResultType

    init(title: String,
         detail: String?,
         type: ResultType,
         onClick: ClickHandler?,
         selectionStyle: CellSelectionStyle = .normal,
         separatorLineStyle: CellSeparatorLineStyle = .normal) {
        self.type = type
        let hideArrow = onClick == nil
        super.init(title: title,
                   detail: detail,
                   accessories: hideArrow ? [] : [NormalCellAccessory(.arrow)],
                   cellIdentifier: "NotificationDiagnosisResultCell",
                   separatorLineStyle: separatorLineStyle,
                   selectionStyle: onClick == nil ? .none : selectionStyle,
                   onClick: onClick)
    }
}

final class NotificationDiagnosisResultCell: NormalCell {

    override func update(_ info: CellProp) {
        super.update(info)
        guard let info = info as? NotificationDiagnosisResultCellProp else { return }
        switch info.type {
        case .warning:
            leadingIcon.image = UDIcon.getIconByKey(.warningBlueColorful, size: CGSize(width: 20, height: 20))
        case .error:
            leadingIcon.image = UDIcon.getIconByKey(.warningRedColorful, size: CGSize(width: 20, height: 20))
        }
    }

    lazy var leadingIcon: UIImageView = {
        let view = UIImageView()
        view.snp.makeConstraints {
            $0.width.height.equalTo(20)
        }
        return view
    }()

    override func getLeadingView() -> UIView? {
        return leadingIcon
    }
}
