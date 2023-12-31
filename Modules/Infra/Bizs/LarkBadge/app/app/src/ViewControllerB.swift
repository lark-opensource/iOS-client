//
//  ViewControllerB.swift
//  BadgeDemo
//
//  Created by 康涛 on 2019/3/27.
//  Copyright © 2019 康涛. All rights reserved.
//

import Foundation
import UIKit
import LarkBadge

public class ViewControllerB: UIViewController {

    lazy var viewdot: UIButton = {
        var bt1 = UIButton(type: .custom)
        bt1.frame = CGRect(x: 200, y: 100, width: 100, height: 100)
        bt1.backgroundColor = #colorLiteral(red: 0.1921568662, green: 0.007843137719, blue: 0.09019608051, alpha: 1)
        bt1.addTarget(self, action: #selector(goto), for: .touchUpInside)

        bt1.badge.observe(for: Path().prefix(Path().chat_id, with: "123"))
        bt1.badge.set(type: .image(.web(URL(string:
            "http://cms-bucket.nosdn.127.net/a2482c0b2b984dc88a479e6b7438da6020161219074944.jpeg")!)))

        return bt1
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(viewdot)

        BadgeManager.setBadge(Path().prefix(Path().chat_id, with: "123").chat_pin,
                              type: .image(.default(.new)))
        BadgeManager.setBadge(Path().prefix(Path().chat_id, with: "123").chat_setting,
                              type: .image(.default(.new)))
    }

    @objc
    fileprivate func goto() {
        self.navigationController?.pushViewController(ViewControllerC(), animated: true)
    }

    deinit {
        print("viewControllerB dealloced")
    }

}
