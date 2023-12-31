//
//  NotificationDiagnosisCell.swift
//  UITestDemo
//
//  Created by panbinghua on 2022/3/7.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import LarkSettingUI

final class NotificationDiagnosisCellProp: BaseNormalCellProp {

    enum DiagnosisType {
        case waiting
        case loading
        case ok
        case warning
    }

    var type: DiagnosisType

    init(title: String,
         type: DiagnosisType,
         isDisabled: Bool = false) {
        self.type = type
        super.init(title: title,
                   cellIdentifier: "NotificationDiagnosisCell",
                   separatorLineStyle: .none,
                   selectionStyle: .none)
    }
}

final class NotificationDiagnosisCell: BaseNormalCell {

    override func update(_ info: CellProp) {
        super.update(info)
        guard let info = info as? NotificationDiagnosisCellProp else { return }
        removeRotateAnimation(trailingIcon)
        switch info.type {
        case .waiting:
            trailingIcon.image = UDIcon.getIconByKey(.maybeFilled,
                                                     iconColor: UIColor.ud.iconDisabled,
                                                     size: CGSize(width: 20, height: 20))
        case .ok:
            trailingIcon.image = UDIcon.getIconByKey(.succeedColorful, size: CGSize(width: 20, height: 20))
        case .warning:
            trailingIcon.image = UDIcon.getIconByKey(.warningRedColorful, size: CGSize(width: 20, height: 20))
        case .loading:
            trailingIcon.image = UDIcon.getIconByKey(.loadingOutlined,
                                                     iconColor: UIColor.ud.B400,
                                                     size: CGSize(width: 20, height: 20))
            addRoateAnimation(trailingIcon)
        }
    }

    lazy var trailingIcon: UIImageView = {
        let view = UIImageView()
        view.snp.makeConstraints {
            $0.width.height.equalTo(20)
        }
        return view
    }()

    override func getTrailingView() -> UIView? {
        return trailingIcon
    }

    private func removeRotateAnimation(_ view: UIView) {
        view.layer.removeAllAnimations()
    }

    private func addRoateAnimation(_ view: UIView) {
        guard view.layer.animation(forKey: "rotate") == nil else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.duration = 0.8
        animation.fillMode = .forwards
        animation.repeatCount = .infinity
        animation.values = [0, Double.pi * 2]
        animation.keyTimes = [NSNumber(value: 0.0), NSNumber(value: 1.0)]
        animation.isRemovedOnCompletion = false

        view.layer.add(animation, forKey: "rotate")
    }
}
