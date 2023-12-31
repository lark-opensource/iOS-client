//
//  PanViewControllerDelegate.swift
//  ByteRtcRenderDemo
//
//  Created by huangshun on 2019/10/16.
//  Copyright © 2019 huangshun. All rights reserved.
//

import Foundation
import UIKit

public enum RoadAxis: Int {

    case landscape

    case portrait

}

public enum RoadLayout: Int {

    case expand

    case shrink
}

public enum PanHeight {

    case maxHeightWithTopInset(CGFloat)

    case contentHeight(CGFloat, minTopInset: CGFloat = 8)

    case intrinsicHeight
}

public enum PanWidth {

    case inset(left: CGFloat, right: CGFloat)

    case fullWidth

    case maxWidth(width: CGFloat)

}

public protocol PanChildViewControllerProtocol: AnyObject {

    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth

    var defaultLayout: RoadLayout { get }

    var roadTrigger: CGFloat { get }

    var shouldRoundTopCorners: Bool { get }

    var showDragIndicator: Bool { get }

    var showBarView: Bool { get }

    var indicatorColor: UIColor { get }

    var backgroudColor: UIColor { get }

    var maskColor: UIColor { get }

    var springDamping: CGFloat { get }

    var transitionAnimationOptions: UIView.AnimationOptions { get }

    var panScrollable: UIScrollView? { get }

    func configurePanWareContentView(_ contentView: UIView)
}

class WeakBox<T: AnyObject> {

    weak var value: T?

    init(_ value: T?) { self.value = value }

}

extension UIViewController {

    private static var panViewControllerKey: String = "PanViewControllerKey"

    public var panViewController: PanViewController? {

        get {
            let weakBox = objc_getAssociatedObject(
                self,
                &UIViewController.panViewControllerKey
            ) as? WeakBox<UIViewController>

            return weakBox?.value as? PanViewController
        }

        set {
            objc_setAssociatedObject(
                self,
                &UIViewController.panViewControllerKey,
                WeakBox<UIViewController>(newValue),
                .OBJC_ASSOCIATION_RETAIN
            )
        }

    }

}

extension UIInterfaceOrientation {

    var roadAxis: RoadAxis {
        switch self {
        case .landscapeLeft, .landscapeRight: return .landscape
        case .portrait, .portraitUpsideDown: return .portrait
        default: return .landscape
        }
    }

}
