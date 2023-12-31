import UIKit
import ByteViewUI

final class InnerFloatingVCLogic: RouterListener {

    private let viewModel: InMeetViewModel
    private let rootVCIdentifier: ObjectIdentifier

    private var isWindowFloating: Bool = false {
        didSet {
            updateShouldDisplayFloating()
        }
    }
    private var isRootChanged = false {
        didSet {
            updateShouldDisplayFloating()
        }
    }
    var isViewAppeared: Bool = true {
        didSet {
            updateShouldDisplayFloating()
        }
    }

    private var floatingHandle: DragbleHandle?
    private var floatingVC: UIViewController?

    private var shouldDisplayFloating: Bool = false {
        didSet {
            guard self.shouldDisplayFloating != oldValue else {
                return
            }
            if shouldDisplayFloating {
                self.presentFloatingVC()
            } else {
                self.dismissFloatingVC()
            }
        }
    }

    private func updateShouldDisplayFloating() {
        // TODO: @liujianlong 内部悬浮窗
        self.shouldDisplayFloating = !isRootChanged && !isViewAppeared && !isWindowFloating && false
    }

    let factory: () -> UIViewController

    init(viewModel: InMeetViewModel, rootVC: ObjectIdentifier, factory: @escaping () -> UIViewController) {
        self.rootVCIdentifier = rootVC
        self.factory = factory
        self.viewModel = viewModel
        self.viewModel.meeting.router.addListener(self)
    }

    func didChangeWindowFloatingAfterAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        self.isWindowFloating = isFloating
    }

    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        self.isWindowFloating = isFloating
    }

    func didChangeWindowRootVC(_ newVC: UIViewController) {
        self.isRootChanged = ObjectIdentifier(newVC) != rootVCIdentifier
    }

    private var window: UIWindow? {
        self.viewModel.meeting.router.window
    }

    private func floatingSize(isLandscape: Bool) -> CGSize {
        if Display.phone {
            return CGSize(width: 90, height: 90)
        } else {
            return isLandscape ? CGSize(width: 240, height: 135) : CGSize(width: 160, height: 160)
        }
    }

    @objc
    private func handleFloatingTapped() {
        guard !isRootChanged else {
            return
        }
        if let rootVC = self.window?.rootViewController,
           rootVC.presentedViewController != nil {
            rootVC.dismiss(animated: true)
        }
    }

    private func dismissFloatingVC() {
        guard let floatingVC = self.floatingVC else {
            return
        }
        floatingVC.view.removeFromSuperview()
        floatingHandle?.invalidate()

        self.floatingVC = nil
        self.floatingHandle = nil
    }

    private func presentFloatingVC() {
        guard self.floatingHandle == nil,
              let window = self.window else {
            return
        }
        let viewController = factory()

        let tapGest = UITapGestureRecognizer(target: self, action: #selector(handleFloatingTapped))

        viewController.view.addGestureRecognizer(tapGest)
        viewController.view.addGestureRecognizer(tapGest)

        window.addSubview(viewController.view)
        self.floatingVC = viewController
        viewController.view.applyFloatingShadow()
        self.floatingHandle = setupFloatingDrag(view: viewController.view)
        self.floatingHandle?.floatingSize = self.floatingSize(isLandscape: VCScene.isLandscape)
        self.floatingHandle?.translate(offset: CGPoint(x: 0.0, y: 100.0))
    }

    deinit {
        dismissFloatingVC()
    }

    func resetFloatingSize(isLandscape: Bool) {
        self.floatingHandle?.floatingSize = self.floatingSize(isLandscape: isLandscape)
    }
}
