//
//  BlankController.swift
//  CalendarDemo
//
//  Created by zhu chao on 2018/8/9.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import SnapKit
import Calendar
import RxSwift
import RxCocoa
import EEKeyValue
import LarkUIKit
import EENavigator
import LarkDebug
import LarkContainer
import UniverseDesignColor
final class BlankController: CalendarController {
    @InjectedLazy var interface: CalendarInterface

    let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        let button = UIButton()
        button.backgroundColor = .red
        view.addSubview(button)
        button.snp.makeConstraints {
            $0.size.equalTo(100)
            $0.center.equalToSuperview()
        }

        button.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            let controller = self.interface
                .applinkEventDetailController(key: "a985dc27-64f5-4062-8744-6e8895da432f",
                                              calendarId: "6910011996105719810",
                                              source: "",
                                              token: "",
                                              originalTime: 0,
                                              startTime: 1625481000,
                                              endTime: nil,
                                              isFromAPNS: false)
            let nav = LkNavigationController(rootViewController: controller)
            if Display.pad {
                Navigator.shared.present(nav, from: self, prepare: { $0.modalPresentationStyle = .formSheet })
                return
            }
            Navigator.shared.present(nav, from: self, prepare: { $0.modalPresentationStyle = .fullScreen })
        }).disposed(by: disposeBag)
        return
    }

}
