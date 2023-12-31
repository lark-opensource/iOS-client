// 
// Created by duanxiaochen.7 on 2020/5/6.
// Affiliated with SpaceKit.
// 
// Description: 业务方若无需实现页面上下滚动就可以直接继承该类，
// 否则，一级页面 SheetToolkitFacadeViewController 补充了 contentView，二级页面 SheetScrollableToolkitViewController 补充了 scrollView，有需要实现可滚动的页面请直接继承这两个类

import SKCommon
import SKUIKit
import UniverseDesignColor
import RxSwift

/// 具有被资源定位的能力
protocol ResourceLocatable {
    var resourceIdentifier: String { get }
}

protocol SheetBadgeLocator: AnyObject {
    func fetchBadgeList(_ controller: SheetBaseToolkitViewController) -> Set<String>?
    func finishBadges(identifiers: [String], controller: SheetBaseToolkitViewController)
}

class SheetBaseToolkitViewController: UIViewController, ResourceLocatable, SheetToolkitNavigationBarDelegate {

    let draggableViewHeight: CGFloat = SheetToolkitNavigationController.draggableViewHeight
    let navigationBarHeight: CGFloat = 48
    let itemHeight: CGFloat = 48
    let itemSpacing: CGFloat = 16
    
    var topPaddingWithHeader: CGFloat {
        return draggableViewHeight + navigationBarHeight
    }

    lazy var allowUpDrag: Bool = {
        if let panelIdentifier = BadgedItemIdentifier(rawValue: resourceIdentifier) {
            return panelIdentifier.allowsDraggingUp()
        }
        return true
    }()

    lazy var navigationBar: SheetToolkitNavigationBar = {
        let view = SheetToolkitNavigationBar(title: "")
        view.delegate = self
        return view
    }()

    var navBarGestureDelegate: SheetToolkitNavigationControllerGestureDelegate? {
        let quickNavigator = navigationController as? SheetToolkitNavigationController
        return quickNavigator?.gestureDelegate
    }

    weak var badgeDelegate: SheetBadgeLocator?

    var resourceIdentifier: String {
        return BadgedItemIdentifier.none.rawValue
    }

    var badgedList: Set<String> {
        let list = badgeDelegate?.fetchBadgeList(self) ?? Set<String>()
        return list
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        return
    }

    func docsPresent(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    func didReceivedPanBegin(point: CGPoint, view: SheetToolkitNavigationBar) {
        navBarGestureDelegate?.panBegin(point, allowUp: allowUpDrag)
    }

    func didReceivedPanMoved(point: CGPoint, view: SheetToolkitNavigationBar) {
        navBarGestureDelegate?.panMove(point, allowUp: allowUpDrag)
    }

    func didReceivedPanEnded(point: CGPoint, view: SheetToolkitNavigationBar) {
        navBarGestureDelegate?.panEnd(point, allowUp: allowUpDrag)
    }

    // 点击 back 事件抽象方法
    func willExistControllerByUser() {

    }

    func didReceivedTapGesture(view: SheetToolkitNavigationBar) {
        willExistControllerByUser()
        navigationController?.popViewController(animated: true)
    }
}
