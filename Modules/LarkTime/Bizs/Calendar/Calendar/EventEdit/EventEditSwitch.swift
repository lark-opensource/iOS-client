//
//  EventEditSwitch.swift
//  Calendar
//
//  Created by zhuheng on 2021/4/9.
//

import UIKit
import Foundation
import SnapKit
import RxCocoa
import RxSwift

final class EventEditSwitch: EventEditCellLikeView {
    var rxIsOn: RxCocoa.ControlProperty<Bool> { switching.rx.isOn }

    private let switching = UISwitch()
    init(isOn: Bool, descText: String) {
        super.init(frame: .zero)

        backgroundColor = UIColor.ud.bgFloat
        icon = .none

        switching.isOn = isOn
        switching.onTintColor = UIColor.ud.primaryContentDefault
        addSubview(switching)
        switching.snp.makeConstraints {
            $0.right.equalToSuperview().inset(EventBasicCellLikeView.Style.rightInset)
            $0.centerY.equalToSuperview()
        }
        content = .title(.init(text: descText))
        backgroundColors = EventEditUIStyle.Color.cellBackgrounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
