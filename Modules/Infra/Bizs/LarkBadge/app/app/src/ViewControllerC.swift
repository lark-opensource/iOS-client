//
//  ViewControllerC.swift
//  BadgeDemo
//
//  Created by 康涛 on 2019/3/27.
//  Copyright © 2019 康涛. All rights reserved.
//

import Foundation
import UIKit
import LarkBadge

public class ViewControllerC: UIViewController {

    lazy var viewdot: UIButton = {
        let bt1 = UIButton(type: .custom)
        bt1.frame = CGRect(x: 200, y: 100, width: 100, height: 100)
        bt1.backgroundColor = #colorLiteral(red: 0.1921568662, green: 0.007843137719, blue: 0.09019608051, alpha: 1)
        bt1.addTarget(self, action: #selector(goto), for: .touchUpInside)

        bt1.uiBadge.addBadge(type: .label(.number(4)))

        return bt1
    }()

    lazy var viewnum: UIView = {
        let bt1 = UIButton(type: .custom)
        bt1.frame = CGRect(x: 200, y: 240, width: 100, height: 100)
        bt1.backgroundColor = #colorLiteral(red: 0.1921568662, green: 0.007843137719, blue: 0.09019608051, alpha: 1)
        bt1.addTarget(self, action: #selector(goto2), for: .touchUpInside)

        bt1.uiBadge.addBadge(type: .label(.number(0)))
        bt1.uiBadge.badgeView?.type = .label(.number(0))
        return bt1
    }()

    lazy var viewnum2: UIView = {
        var bt1 = UIButton(type: .custom)
        bt1.frame = CGRect(x: 200, y: 360, width: 100, height: 100)
        bt1.backgroundColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
        bt1.addTarget(self, action: #selector(goto3), for: .touchUpInside)

        bt1.uiBadge.addBadge(type: .dot(.pin))

        bt1.uiBadge.badgeView?.type = .dot(.pin)

        let bg = BadgeView(with: BadgeType.label(.number(0)))
        bg.type = .none

        bt1.addSubview(bg)

        return bt1
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(viewdot)
        view.addSubview(viewnum)
        view.addSubview(viewnum2)

        var value: Int = 0
        var reverse: Bool = false
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            value += reverse ? -100 : 100

            if value >= 1000 { reverse.toggle() }
            if value <= 0 { reverse.toggle() }
            print(value)
            if value > 500 && value < 800 {
                self?.viewdot.uiBadge.badgeView?.type = .dot(.lark)
            } else {
                self?.viewdot.uiBadge.badgeView?.type = .label(.number(value))
            }

        }
        RunLoop.current.add(timer, forMode: .common)
        timer.fire()
    }

    @objc
    fileprivate func goto() {
        if viewdot.uiBadge.badgeView?.style == .strong {
            viewdot.uiBadge.badgeView?.style = .middle
        } else if viewdot.uiBadge.badgeView?.style == .middle {
            viewdot.uiBadge.badgeView?.style = .weak
        } else if viewdot.uiBadge.badgeView?.style == .weak {
            viewdot.uiBadge.badgeView?.style = .strong
        }
    }

    @objc
    fileprivate func goto2() {
        if case .label = viewnum.uiBadge.badgeView?.type {
            viewnum.uiBadge.badgeView?.type = .dot(.lark)
        } else if case .dot = viewnum.uiBadge.badgeView?.type {
            viewnum.uiBadge.badgeView?.type = .label(.number(1))
        }
    }

    @objc
    fileprivate func goto3() {
        viewnum2.badge.clearBadge()
    }

    deinit {
        print("viewControllerC dealloced")
    }

}
