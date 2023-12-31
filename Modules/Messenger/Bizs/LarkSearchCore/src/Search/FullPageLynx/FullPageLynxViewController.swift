//
//  FullPageLynxViewController.swift
//  LarkSearchCore
//
//  Created by sunyihe on 2022/6/29.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import Lynx
import UniverseDesignTheme
import LarkLocalizations
import LarkReleaseConfig
import LKCommonsLogging
import LarkContainer
import LarkAccountInterface
import LarkEnv
import LarkSetting

final public class LynxViewFactory {
    private let lynxPropsManager: LynxPropsManagerProtocol
    let userResolver: UserResolver
    public init(userResovler: UserResolver) {
        self.userResolver = userResovler
        self.lynxPropsManager = LynxPropsManager(userResolver: userResovler)
    }

    /// 创建新的LynxView
    public func newLynxView(viewModel: LynxViewModelProtocol, params: ASLynxBridgeDependency, imageFetcher: SearchLynxImageFetcher) -> LynxView {
        let lynxView = LynxView(builderBlock: { lynxViewBuilder in
            lynxViewBuilder.group = LynxGroup(name: "enterprise_entity_word", withPreloadScript: nil, useProviderJsEnv: false, enableCanvas: false)
            lynxViewBuilder.screenSize = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
            lynxViewBuilder.config = LynxConfig(provider: SearchLynxTemplateProvider())
            lynxViewBuilder.config?.register(ASLynxBridge.self, param: params)
        })
        lynxView.imageFetcher = imageFetcher
        if #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
            let theme = LynxTheme()
            theme.updateValue("dark", forKey: "brightness")
            lynxView.setTheme(theme)
        }
        lynxView.bridge.globalPropsData = lynxPropsManager.getGlobalProps()
        return lynxView
    }
}

/// 通用Lynx容器VC
final public class FullPageLynxViewController: UIViewController, UIViewControllerTransitioningDelegate {

    public var dismissBlock: (() -> Void)?
    public var updateBlock: (([AnyHashable: Any], [AnyHashable: Any]) -> Void)?
    var lynxViewTemplate: Data?
    private var lynxView: LynxView
    private var viewModel: LynxViewModelProtocol
    var imageFetcher: SearchLynxImageFetcher
    private let userResolver: UserResolver

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if Display.pad {
            return [.all]
        }
        return viewModel.supportOrientations
    }

    private static let logger = Logger.log(FullPageLynxViewController.self, category: "LarkSearchCore.FullPageLynxViewController")

    public init(viewModel: LynxViewModelProtocol, params: ASLynxBridgeDependency) {
        self.viewModel = viewModel

        self.imageFetcher = SearchLynxImageFetcher(userResolver: params.userResolver)
        self.lynxView = LynxViewFactory(userResovler: params.userResolver).newLynxView(viewModel: viewModel, params: params, imageFetcher: imageFetcher)
        self.userResolver = params.userResolver
        super.init(nibName: nil, bundle: nil)
        viewModel.loadHostVC(hostVC: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isTranslucent = false
        if SearchTrackUtil.enablePostTrack() {
            self.lynxView.addLifecycleClient(self)
        }
        setUpSubViews()
        Self.logger.info("viewDidLoad！")
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        //高度最大限制为610
        self.lynxView.updateViewport(withPreferredLayoutWidth: size.width,
                                     preferredLayoutHeight: min(size.height, 610))
        super.viewWillTransition(to: size, with: coordinator)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Self.logger.info("viewDidAppear！")
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Self.logger.info("viewDidLayoutSubviews！")
        if enablePadRemakeLynxViewSize(), Display.pad {
            //fix pad下使用formsheet弹出vc，尺寸和lynxView初始值不一样，导致页面上再弹出页面时，层叠式动画阴影被漏出；lynxview使用依赖布局，内部实际展示的UILynxView尺寸并不会改变
            var isSizeChange = false
            if lynxView.preferredLayoutWidth != self.view.frame.size.width {
                lynxView.preferredLayoutWidth = self.view.frame.size.width
                isSizeChange = true
            }
            if lynxView.preferredLayoutHeight != min(self.view.frame.size.height, 610) {
                lynxView.preferredLayoutHeight = min(self.view.frame.size.height, 610) //历史背景最大高度是610
                isSizeChange = true
            }
            if isSizeChange {
                viewModel.loadTemplate(lynxView: lynxView)
            }
        }
    }

    private func enablePadRemakeLynxViewSize() -> Bool {
        let aslConfig = try? self.userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "lark_asl_config"))
        if let enable = aslConfig?["enable_pad_remake_lynxView_size"] as? Bool {
            return enable
        }
        return true
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    public func setExtraTiming(extraTiming: LynxExtraTiming) {
        guard SearchTrackUtil.enablePostTrack() else { return }
        lynxView.setExtraTiming(extraTiming)
    }

    private func setUpSubViews() {
        view.addSubview(lynxView)
        lynxView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }
        view.backgroundColor = .clear
        lynxView.layoutWidthMode = .exact
        lynxView.layoutHeightMode = .exact
        if Display.pad {
            lynxView.preferredLayoutWidth = min(UIApplication.shared.keyWindow?.bounds.width ?? UIScreen.main.bounds.width, 540)
            lynxView.preferredLayoutHeight = 610
        } else {
            lynxView.preferredLayoutWidth = UIScreen.main.bounds.width
            lynxView.preferredLayoutHeight = UIScreen.main.bounds.height
        }

        viewModel.loadTemplate(lynxView: lynxView)
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        Presentation(presentedViewController: presented, presenting: presenting ?? source)
    }

    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) {
            completion?()
            self.dismissBlock?()
        }
    }

    /// 主要是考虑到动画时机不一样。dimmingView是渐变的。而contentController是present出来的
    /// 所以使用Presentation来管理背景View
    final class Presentation: UIPresentationController {
        private let dimmingView = UIView()

        init(presentedViewController: UIViewController,
                      presenting presentingViewController: UIViewController?,
                      backgroundColor: UIColor = UIColor.ud.bgMask) {
            super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
            dimmingView.backgroundColor = backgroundColor
        }

        override func presentationTransitionWillBegin() {
            super.presentationTransitionWillBegin()
            dimmingView.alpha = 0
            if let containerView = containerView {
                containerView.addSubview(dimmingView)
                dimmingView.frame = containerView.bounds
            }
            let coordinator = presentedViewController.transitionCoordinator
            coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 }, completion: nil)
        }

        override func dismissalTransitionWillBegin() {
            super.dismissalTransitionWillBegin()
            let coordinator = presentedViewController.transitionCoordinator
            coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 0 }, completion: nil)
        }

        override func containerViewWillLayoutSubviews() {
            super.containerViewWillLayoutSubviews()
            if let containerView = containerView {
                dimmingView.frame = containerView.bounds
            }
        }
    }
}

extension FullPageLynxViewController: LynxViewLifecycle {
    public func lynxView(_ lynxView: LynxView!, onUpdate info: [AnyHashable: Any]!, timing updateTiming: [AnyHashable: Any]!) {
        guard SearchTrackUtil.enablePostTrack() else { return }
        self.updateBlock?(info, updateTiming)
    }
}
