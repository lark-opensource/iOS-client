//
//  NavigationController+DynamicModal.swift
//  ByteView
//
//  Created by Tobb Huang on 2023/5/11.
//

import Foundation

extension NavigationController: DynamicModalDelegate {
    public func regularCompactStyleDidChange(isRegular: Bool) {
        guard let wrapper = topViewController as? DynamicModalDelegate else {
            return
        }
        wrapper.regularCompactStyleDidChange(isRegular: isRegular)
    }

    public func didAttemptToSwipeDismiss() {
        guard let wrapper = topViewController as? DynamicModalDelegate else {
            return
        }
        wrapper.didAttemptToSwipeDismiss()
    }
}

extension NavigationController: PanChildViewControllerProtocol {

    public func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.height(axis, layout: layout)
        }
        return wrapper.height(axis, layout: layout)
    }

    public func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.width(axis, layout: layout)
        }
        return wrapper.width(axis, layout: layout)
    }

    public var defaultLayout: RoadLayout {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.defaultLayout
        }
        return wrapper.defaultLayout
    }

    public var roadTrigger: CGFloat {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.roadTrigger
        }
        return wrapper.roadTrigger
    }

    public var shouldRoundTopCorners: Bool {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.shouldRoundTopCorners
        }
        return wrapper.shouldRoundTopCorners
    }

    public var showDragIndicator: Bool {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.showDragIndicator
        }
        return wrapper.showDragIndicator
    }

    public var showBarView: Bool {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.showBarView
        }
        return wrapper.showBarView
    }

    public var indicatorColor: UIColor {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.indicatorColor
        }
        return wrapper.indicatorColor
    }

    public var backgroudColor: UIColor {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.backgroudColor
        }
        return wrapper.backgroudColor
    }

    public var maskColor: UIColor {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.maskColor
        }
        return wrapper.maskColor
    }

    public var springDamping: CGFloat {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.springDamping
        }
        return wrapper.springDamping
    }

    public var transitionAnimationOptions: UIView.AnimationOptions {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.transitionAnimationOptions
        }
        return wrapper.transitionAnimationOptions
    }

    public var panScrollable: UIScrollView? {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.panScrollable
        }
        return wrapper.panScrollable
    }

    public func configurePanWareContentView(_ contentView: UIView) {
        guard let wrapper = topViewController as? PanChildViewControllerProtocol else {
            return PanViewControllerProtocolWrapper.default.configurePanWareContentView(contentView)
        }
        return wrapper.configurePanWareContentView(contentView)
    }
}
