//
// Created by duanxiaochen.7 on 2019/7/25.
// Affiliated with SpaceKit.
//
// Description: Sheet Redesign - Toolkit Panel - NavigationVC

import SKCommon
import SKUIKit

protocol SheetToolkitNavigationControllerGestureDelegate: AnyObject {
    func panBegin(_ point: CGPoint, allowUp: Bool)
    func panMove(_ point: CGPoint, allowUp: Bool)
    func panEnd(_ point: CGPoint, allowUp: Bool)
    func tapToExit()
}

protocol SheetToolkitNavigationControllerDelegate: AnyObject {
    func requestPresentNewViewController(_ controller: UIViewController, navigator: SheetToolkitNavigationController)
    func requestPushNewViewController(_ controller: UIViewController, navigator: SheetToolkitNavigationController)
}

class SheetToolkitNavigationController: UINavigationController {
    //导航回退的时候分发给前端的事件
    static let backIdentifier: String = "back"
    static let draggableViewHeight: CGFloat = 12
    weak var gestureDelegate: SheetToolkitNavigationControllerGestureDelegate?
    weak var navigationDelegate: SheetToolkitNavigationControllerDelegate?

    private lazy var dragHandle: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineBorderCard
        view.layer.cornerRadius = 2
        view.isUserInteractionEnabled = false
        view.docs.addStandardLift()
        return view
    }()

    private lazy var draggableView: UIView = {
        let view = UIView()
        view.addSubview(dragHandle)
        view.backgroundColor = UIColor.ud.bgBody
        dragHandle.snp.makeConstraints { (make) in
            make.width.equalTo(40)
            make.height.equalTo(4)
            make.centerX.bottom.equalToSuperview()
        }
        return view
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        setNavigationBarHidden(true, animated: false)
        addDraggableView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = .top
        view.layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setDraggableHandle(isHidden: Bool) {
        dragHandle.isHidden = isHidden
    }

    private func addDraggableView() {
        view.addSubview(draggableView)
        draggableView.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(SheetToolkitNavigationController.draggableViewHeight)
            make.top.left.equalToSuperview()
        }

        let titlePan = UIPanGestureRecognizer(target: self, action: #selector(didReceivePanGesture(gesture:)))
        draggableView.addGestureRecognizer(titlePan)
    }

    @objc
    func didReceivePanGesture(gesture: UIPanGestureRecognizer) {
        var allowUp = true
        if let vc = viewControllers.last as? SheetBaseToolkitViewController,
            let pandleIdentifer = BadgedItemIdentifier(rawValue: vc.resourceIdentifier) {
            allowUp = pandleIdentifer.allowsDraggingUp()
        }

        let point = gesture.location(in: draggableView)
        if gesture.state == .began {
            gestureDelegate?.panBegin(point, allowUp: allowUp)
        } else if gesture.state == .changed {
            gestureDelegate?.panMove(point, allowUp: allowUp)
        } else {
            gestureDelegate?.panEnd(point, allowUp: allowUp)
        }
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        navigationDelegate?.requestPushNewViewController(viewController, navigator: self)
        return
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        navigationDelegate?.requestPresentNewViewController(viewControllerToPresent, navigator: self)
        return
    }

    func docsPushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
    }

}

struct SheetPanelContextKey {
    static let panelIndex = "oppanelIndex"
    static let tookkitBack = "tookkitBack"
}
