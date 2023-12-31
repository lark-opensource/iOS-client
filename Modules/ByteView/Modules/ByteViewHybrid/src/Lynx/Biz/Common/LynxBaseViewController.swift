//
// Created by maozhixiang.lip on 2022/10/20.
//

import Foundation
import ByteViewUI
import ByteViewCommon
import UniverseDesignIcon
import ByteViewUDColor
import Lynx
import BDXServiceCenter
import ByteViewTracker

class LynxBaseViewController: UIViewController {
    let userId: String
    let path: String
    var lynxView: LynxView?
    var disablePullDownDismiss: Bool = false
    var preferredNavigationBarStyle: ByteViewNavigationBarStyle = .light
    var globalFrame: CGRect? { self.view.superview?.convert(self.view.frame, to: nil) }

    init(userId: String, path: String) {
        self.userId = userId
        self.path = path
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func setupLynxView(with builder: LynxViewBuilder) {
        fatalError("override me")
    }

    private func createLynxView() -> LynxView? {
        Logger.lynx.info("create lynx view, path = \(self.path)")
        return LynxManager.shared.createView(userId: userId, path: path) { [weak self] builder in
            guard let self = self else { return }
            _ = builder.lifecycleDelegate(self)
            self.setupLynxView(with: builder)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let lynxView = createLynxView() else {
            return
        }
        self.lynxView = lynxView
        self.view.backgroundColor = .clear
        self.view.addSubview(lynxView)
        lynxView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        self.lynxView?.load()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        let userInfo = notification.userInfo
        let frame = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        self.lynxView?.sendEvent(name: "KeyboardStatusChange", params: ["isOn": true, "height": frame.size.height])
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        self.lynxView?.sendEvent(name: "KeyboardStatusChange", params: ["isOn": false, "height": 0])
    }
}


extension LynxBaseViewController: LynxViewLifecycleDelegate {
    func view(_ view: BDXKitViewProtocol, didLoadFailedWithUrl url: String?, error: Error?) {
        self.dismiss(animated: true)
        self.reportError(error)
    }

    func view(_ view: BDXKitViewProtocol, didRecieveError error: Error?) {
        // Lynx升级到2.10.18-lark之后，部分场景会报1301错误码，但实际页面渲染无问题，怀疑是Lynx的检查逻辑有问题，因此暂时先针对性屏蔽该错误
        // Lynx检查逻辑: https://code.byted.org/lynx/template-assembler/blob/release/2.10/Lynx/css/parser/color_handler.cc#L38
        if let nsError = error as? NSError, nsError.code == 1301 {
            Logger.lynx.warn("ignore lynx error, err = \(nsError)")
            return
        }
        self.dismiss(animated: true)
        self.reportError(error)
    }

    private func reportError(_ error: Error?) {
        guard let error = error else { return }
        Logger.lynx.error("lynx error, err = \(error)")
        AppreciableTracker.shared.trackError(.vc_lynx_error, params: ["error": error.localizedDescription])
    }
}

extension LynxBaseViewController: DynamicModalDelegate {
    func didAttemptToSwipeDismiss() {
        self.lynxView?.sendEvent(name: "didAttemptToPullDown", params: [:])
    }
}

extension UIEdgeInsets {
    var dict: [String: Any] {
        ["top": self.top, "right": self.right, "bottom": self.bottom, "left": self.left]
    }
}

extension CGRect {
    var dict: [String: Any] {
        [
            "origin": ["x": self.origin.x, "y": self.origin.y],
            "size": ["width": self.size.width, "height": self.size.height]
        ]
    }
}

extension CGSize {
    var dict: [String: Any] {
        [
            "width": self.width,
            "height": self.height
        ]
    }
}
