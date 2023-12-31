//
//  PanViewController+Public.swift
//  ByteView
//
//  Created by huangshun on 2020/2/11.
//

import Foundation
import UIKit

extension PanViewController {

    public func push(_ viewController: UIViewController, animated: Bool) {
        let fromWare: PanWare? = stack.last
        let toWare: PanWare = makeWare(with: viewController)
        toWare.viewController.panViewController = self
        checkLayout(toWare)
        addChildWare(toWare)
        stack.append(toWare)
        addPushCommit(toWare, from: fromWare, animated: animated)
    }

    @discardableResult
    public func pop(animated: Bool, complete: (() -> Void)? = nil) -> UIViewController? {
        let fromWare: PanWare? = stack.popLast()
        fromWare?.viewController.panViewController = nil
        let toWare: PanWare? = stack.last
        addChildWare(toWare)
        insertWare(toWare, below: fromWare)
        view.layoutIfNeeded()
        addPopCommit(fromWare, toWare: toWare, complete: complete)
        return fromWare?.viewController
    }

    public func updateBelowLayout() {
        belowWare?.resetLayout(currentLayout, view: view)
    }

    public var panMaskView: UIView? {
        belowWare?.wrapper.foregroundMaskView
    }
}
