//
//  AddNewEventButton.swift
//  Calendar
//
//  Created by zhouyuan on 2018/4/8.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import CalendarFoundation
import LarkInteraction
import UniverseDesignIcon
import SnapKit
import FigmaKit
import UniverseDesignShadow
final class AddNewEventButton: UIButton {

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.primaryFillDefault
        let imageView = UIImageView(image: UDIcon.getIconByKey(.addOutlined,
                                                               iconColor: UIColor.ud.primaryOnPrimaryFill,
                                                               size: CGSize(width: 24, height: 24)))

        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }
        if #available(iOS 13.4, *) {
            self.lkPointerStyle = PointerStyle(
                effect: .lift,
                shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                    guard let width = interaction.view?.bounds.width else {
                        return (.zero, 0)
                    }
                    return (CGSize(width: width, height: width), width / 2)
                }))
        }

        // 低端机延迟出现阴影
        ViewPageDowngradeTaskManager.addTask(scene: .addButtonShadow,
                                             way: .delay1s) { [weak self] _ in
            self?.layer.ud.setShadow(type: .s4DownPri)
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
