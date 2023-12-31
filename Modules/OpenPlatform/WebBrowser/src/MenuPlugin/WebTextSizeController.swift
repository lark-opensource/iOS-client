//
//  WebTextSizeController.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/6/11.
//

import Foundation
import LarkUIKit
import LKCommonsLogging
import LarkZoomable

final class WebTextSizeController: UIViewController {
    private static let logger = Logger.webBrowserLog(WebTextSizeController.self, category: "WebTextSizeController")
    
    private weak var container: UIViewController?
    private var panel: WebTextSizePanel?
    
    init(from container: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.container = container
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var shouldAutorotate: Bool {
        if Display.phone, (UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight) {
            return false
        }
        return super.shouldAutorotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if #available(iOS 16.0, *) {
            if Display.phone {
                switch UIApplication.shared.statusBarOrientation {
                case .landscapeLeft:
                    return .landscapeLeft
                case .landscapeRight:
                    return .landscapeRight
                case .portrait, .portraitUpsideDown:
                    return .portrait
                case .unknown:
                    return .portrait
                @unknown default:
                    return .portrait
                }
            } else {
                return super.supportedInterfaceOrientations
            }
        }
        return super.supportedInterfaceOrientations
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupPanel()
        setupPanelConstraints()
    }
    
    private func setupPanel() {
        if let panel = self.panel {
            panel.removeFromSuperview()
            self.panel = nil
        }
        let panel = WebTextSizePanel(delegate: self)
        view.addSubview(panel)
        self.panel = panel
    }
    
    private func setupPanelConstraints() {
        guard let panel = panel else {
            return
        }
        panel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func showPanel(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard let container = container else {
            return
        }
        Self.logger.info("[WebTextSize] presents the web text size view controller")
        container.present(self, animated: animated) {
            completion?()
        }
    }
}

extension WebTextSizeController: WebTextSizePanelProtocol {
    func dismissPanel(animated: Bool, completion: (() -> Void)?) {
        guard let container = container else {
            return
        }
        Self.logger.info("[WebTextSize] dismisses the web text size view controller")
        container.dismiss(animated: animated) {
            completion?()
        }
    }
}
