//
//  UDDrawerContainerLifecycle.swift
//  UniverseDesignDrawer
//
//  Created by 袁平 on 2021/3/12.
//

// DrawerContainerVC Lifecycle
import UIKit
import Foundation
public protocol UDDrawerContainerLifecycle: UIView {
    var contentWidth: CGFloat { get }

    func viewDidLoad()
    func viewWillAppear(_ animated: Bool)
    func viewDidAppear(_ animated: Bool)
    func viewWillDisappear(_ animated: Bool)
    func viewDidDisappear(_ animated: Bool)
}

public extension UDDrawerContainerLifecycle {
    var contentWidth: CGFloat {
        return UDDrawerValues.subViewDefaultWidth
    }

    func viewDidLoad() {}
    func viewWillAppear(_ animated: Bool) {}
    func viewDidAppear(_ animated: Bool) {}
    func viewWillDisappear(_ animated: Bool) {}
    func viewDidDisappear(_ animated: Bool) {}
}
