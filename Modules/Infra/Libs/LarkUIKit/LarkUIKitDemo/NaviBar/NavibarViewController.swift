//
//  NavibarViewController.swift
//  LarkUIKitDemo
//
//  Created by ChalrieSu on 03/04/2018.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift

class NavibarViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private lazy var normalNaviBar: TitleNaviBar = {
        return TitleNaviBar(titleString: "联系人")
    }()

    private lazy var largeNaviBar: LargeTitleNaviBar = {
        return LargeTitleNaviBar(titleString: "联系人")
    }()

    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        let item = TitleNaviBarItem(image: Resources.navigation_new_scene, action: { (_) in
            print("点击了Item")
        })
        normalNaviBar.rightItems = [item]

        tableView.delegate = self
        tableView.dataSource = self

        NaviBarAnimator.setUpAnimatorWith(scrollView: tableView,
                                          normalNaviBar: normalNaviBar,
                                          largeNaviBar: largeNaviBar,
                                          toVC: self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
    }
}
