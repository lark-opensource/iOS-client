//
//  PanChildViewControllerProtocol+Default.swift
//  Action
//
//  Created by huangshun on 2020/2/7.
//

import Foundation
import UIKit
import UniverseDesignColor

extension PanChildViewControllerProtocol where Self: UIViewController {

    public var shouldRoundTopCorners: Bool {
        return PanViewControllerProtocolWrapper.default.shouldRoundTopCorners
    }

    public var showDragIndicator: Bool {
        return PanViewControllerProtocolWrapper.default.showDragIndicator
    }

    public var showBarView: Bool {
        return PanViewControllerProtocolWrapper.default.showBarView
    }

    public var defaultLayout: RoadLayout {
        return PanViewControllerProtocolWrapper.default.defaultLayout
    }

    public var roadTrigger: CGFloat {
        return PanViewControllerProtocolWrapper.default.roadTrigger
    }

    public var indicatorColor: UIColor {
        return PanViewControllerProtocolWrapper.default.indicatorColor
    }

    public var backgroudColor: UIColor {
        return PanViewControllerProtocolWrapper.default.backgroudColor
    }

    public var maskColor: UIColor {
        return PanViewControllerProtocolWrapper.default.maskColor
    }

    public var springDamping: CGFloat {
        return PanViewControllerProtocolWrapper.default.springDamping
    }

    public var transitionAnimationOptions: UIView.AnimationOptions {
        return PanViewControllerProtocolWrapper.default.transitionAnimationOptions
    }

    public func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        return PanViewControllerProtocolWrapper.default.height(axis, layout: layout)
    }

    public func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        return PanViewControllerProtocolWrapper.default.width(axis, layout: layout)
    }

    public var panScrollable: UIScrollView? {
        return PanViewControllerProtocolWrapper.default.panScrollable
    }

    public func configurePanWareContentView(_ contentView: UIView) {
        PanViewControllerProtocolWrapper.default.configurePanWareContentView(contentView)
    }
}

class PanViewControllerProtocolWrapper: PanChildViewControllerProtocol {

    static var `default`: PanViewControllerProtocolWrapper = {
        return PanViewControllerProtocolWrapper()
    }()

    var shouldRoundTopCorners: Bool {
        return true
    }

    var showDragIndicator: Bool {
        return true
    }

    var showBarView: Bool {
        return true
    }

    var defaultLayout: RoadLayout {
        return .shrink
    }

    var roadTrigger: CGFloat {
        return 50
    }

    var indicatorColor: UIColor {
        return UIColor.ud.lineBorderCard
    }

    var backgroudColor: UIColor {
        return UIColor.ud.bgBody
    }

    var maskColor: UIColor {
        return UIColor.ud.bgMask
    }

    var transitionAnimationOptions: UIView.AnimationOptions {
        return [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]
    }

    var springDamping: CGFloat {
        return 1.0
    }

    var panScrollable: UIScrollView? {
        return nil
    }

    // disable-lint: magic number
    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        switch (axis, layout) {
        case (.portrait, .expand): return .maxHeightWithTopInset(52)
        case (.portrait, .shrink): return .maxHeightWithTopInset(240)
        case (.landscape, .expand): return .maxHeightWithTopInset(max(20 + 5, 25))
        case (.landscape, .shrink): return .maxHeightWithTopInset(max(20 + 5, 25))
        }
    }
    // enable-lint: magic number

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        return .fullWidth
    }

    func configurePanWareContentView(_ contentView: UIView) {
        contentView.backgroundColor = backgroudColor
    }

}
