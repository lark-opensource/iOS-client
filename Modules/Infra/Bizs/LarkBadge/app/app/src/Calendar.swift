//
//  Calendar.swift
//  LarkBadgeDev
//
//  Created by KT on 2019/4/22.
//

import Foundation
import UIKit
import LarkBadge

public class CalendarVC: UIViewController {

    lazy var viewnum2: UIView = {
        let bt1 = UIButton(type: .custom)
        bt1.frame = CGRect(x: 200, y: 360, width: 100, height: 100)
        bt1.backgroundColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
        bt1.addTarget(self, action: #selector(goto3), for: .touchUpInside)
        bt1.badge.observe(for: Path().tab_calendar.doc_more)
        return bt1
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(viewnum2)
    }

    @objc
    fileprivate func goto3() {
        viewnum2.badge.clearBadge()
    }

    deinit {
        print("viewControllerC dealloced")
    }
}
