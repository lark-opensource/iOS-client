//
//  FocusWindow.swift
//  MultiUIWindowSolution
//
//  Created by bytedance on 2022/4/21.
//

import Foundation
import UIKit
import SnapKit

// swiftlint:disable all
class FocusWindow: UIWindow {
    public static let shared = FocusWindow(frame: UIScreen.main.bounds)
    
    var tableView = UITableView(frame: .zero, style: .grouped)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        windowLevel = UIWindow.Level.statusBar - 2
        rootViewController = FocusVC()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
