//
//  CalendarController.swift
//  Calendar
//
//  Created by zhuchao on 2018/2/27.
//  Copyright © 2018年 EE. All rights reserved.
//

import UniverseDesignIcon
import Foundation
import CalendarFoundation
import UIKit
import LarkUIKit

open class CalendarController: UIViewController {
    var isNavigationBarHidden: Bool = false
    var navigationBarHiddenAnimated: Bool = true

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.layoutSubviews()
    }

    override open func viewWillAppear(_ animated: Bool) {
        if self.navigationController?.isNavigationBarHidden != self.isNavigationBarHidden {
           self.navigationController?.setNavigationBarHidden(self.isNavigationBarHidden, animated: navigationBarHiddenAnimated)
        }
        super.viewWillAppear(animated)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.modalPresentationControl.readyToControlIfNeeded()
    }

    @discardableResult
    func addBackItem() -> LKBarButtonItem {
        let barItem = LKBarButtonItem(image:
                                        UDIcon.getIconByKeyNoLimitSize(.leftOutlined)
                                        .scaleNaviSize()
                                        .renderColor(with: .n1)
                                        .withRenderingMode(.alwaysOriginal), title: nil)
        barItem.button.addTarget(self, action: #selector(backItemTapped), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = barItem
        return barItem
    }

    @discardableResult
    func addDismissItem() -> LKBarButtonItem {
        let barItem = LKBarButtonItem(image: UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).scaleNaviSize().ud
                                        .withTintColor(UIColor.ud.iconN1), title: nil)
        barItem.button.addTarget(self, action: #selector(dismissPressed), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = barItem
        return barItem
    }

    @objc
    func backItemTapped() {
        self.navigationController?.popViewController(animated: true)
    }

    @objc
    func dismissPressed() {
        self.dismiss(animated: true, completion: nil)
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

}

extension CalendarController: UIPopoverPresentationControllerDelegate {
    public func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }

    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }

}
