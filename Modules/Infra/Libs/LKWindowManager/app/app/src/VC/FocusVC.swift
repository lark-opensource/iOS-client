//
//  FocusVC.swift
//  MultiUIWindowSolution
//
//  Created by bytedance on 2022/4/21.
//

import Foundation
import UIKit
import SnapKit

// swiftlint:disable all
class FocusVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        addSubViews()
        makeConstraints()
        setAppearance()
    }

    lazy var tableView: UITableView = UITableView(frame: .zero, style: .plain)
    lazy var container: UIView = UIView()
    lazy var visualEffectView: UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    lazy var button: UIButton = UIButton()
    
}
