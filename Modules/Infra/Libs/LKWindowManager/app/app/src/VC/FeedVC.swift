//
//  ViewController.swift
//  MultiUIWindowSolution
//
//  Created by bytedance on 2022/4/21.
//

import Foundation
import UIKit
import SnapKit

// swiftlint:disable all
class FeedVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.lightGray
        addSubViews()
        makeConstraints()
        setAppearance()
    }

    lazy var navi = NaviBar()
    lazy var tableView = UITableView(frame: .zero, style: .plain)
    lazy var focus = UIButton()
//    lazy var alertBtn = UIButton()
    
}
