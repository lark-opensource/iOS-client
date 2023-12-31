//
//  LarkUIDependency.swift
//  ByteViewMod
//
//  Created by kiri on 2023/2/21.
//

import Foundation
import ByteViewCommon
import ByteViewUI
import EENavigator
import LarkBizAvatar
import ByteWebImage
import AppContainer
import LarkUIKit
import LarkSceneManager
import LarkSetting
import RustPB
import LarkEmotion
#if canImport(FigmaKit)
import FigmaKit
#endif
#if LarkMod
import Heimdallr
#endif

final class LarkUIDependency: UIDependency {
    static let shared = LarkUIDependency()

    func topMost(of viewController: UIViewController) -> UIViewController? {
        // 直接用下面这个方法会导致Toolbar-More-点击二级页面时，present不出来。
        // UIViewController.topMost(of: viewController, checkSupport: false)
        if let presentedViewController = viewController.presentedViewController {
            if presentedViewController.isBeingDismissed || presentedViewController.isMovingFromParent {
                return presentedViewController.presentingViewController ?? viewController
            } else {
                return topMost(of: presentedViewController)
            }
        }

        // UITabBarController
        if let tabBarController = viewController as? UITabBarController, let selectedViewController = tabBarController.selectedViewController {
            return topMost(of: selectedViewController)
        }

        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return topMost(of: visibleViewController)
        }

        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
            let vcs = pageViewController.viewControllers, vcs.count == 1, let vc = vcs.first {
            return topMost(of: vc)
        }

        // detailvc is the topmost vc
        if let lastVC = (viewController as? UISplitViewController)?.viewControllers.last {
            return topMost(of: lastVC)
        }

        if let lastVC = (viewController as LKSplitVCDelegate).lkTopMost {
            return topMost(of: lastVC)
        }

        // child view controller
        for subview in viewController.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return topMost(of: childViewController)
            }
        }
        return viewController
    }

    func createAvatarView() -> AvatarViewProtocol {
        BizAvatar()
    }

    func createFocusTagView() -> UserFocusTagViewProtocol {
        #if MessengerMod
        return LarkFocusTagView()
        #else
        return DefaultFocusTagView()
        #endif
    }

    func setOrientationControl(for window: UIWindow, shouldControl: Bool) {
        window.preferControlOrientation = shouldControl
    }

    func setWindowIdentifier(_ identifier: String, for window: UIWindow) {
        Logger.ui.info("setWindowIdentifier: \(identifier), window = \(window)")
        window.windowIdentifier = identifier
    }

    func createScrollViewLoadingDelegate(for scrollView: UIScrollView) -> UIScrollViewLoadingDelegate {
        UIScrollViewLoadMoreDelegateImpl(scrollView)
    }

    func setImage(for imageView: UIImageView, resource: ByteViewUI.ImageResource, placeholder: UIImage?, completion: ((Result<UIImage?, Error>) -> Void)?) -> ByteViewUI.ImageRequest? {
        var modifier: RequestModifier?
        let larkRes: LarkImageResource
        switch resource {
        case .url(let urlString, let accessToken):
            if !accessToken.isEmpty {
                modifier = { request in
                    var request = request
                    request.setValue("session=\(accessToken)", forHTTPHeaderField: "Cookie")
                    return request
                }
            }
            larkRes = .default(key: urlString)
        case .reaction(let key):
            larkRes = .reaction(key: key, isEmojis: false)
        case .emojiSectionIcon(let key):
            larkRes = .default(key: key)
        }
        return imageView.bt.setLarkImage(with: larkRes, placeholder: placeholder, modifier: modifier, completion: { result in
            switch result {
            case .success(let r):
                completion?(.success(r.image))
            case .failure(let error):
                completion?(.failure(error))
            }
        })
    }

    func setSquircleMask(for view: UIView, cornerRadius: CGFloat, rect: CGRect) {
        let maskLayer = CAShapeLayer()
        #if canImport(FigmaKit)
        maskLayer.path = UIBezierPath.squircle(forRect: rect, cornerRadius: cornerRadius).cgPath
        #else
        maskLayer.path = UIBezierPath.init(roundedRect: rect, cornerRadius: cornerRadius).cgPath
        #endif
        view.layer.mask = maskLayer
    }

    func openMainScene(completion: ((UIWindow?, Error?) -> Void)?) {
        SceneManager.shared.active(scene: .mainScene(), from: nil, callback: completion)
    }

    var supportsMultipleScenes: Bool {
        SceneManager.shared.supportsMultipleScenes
    }

    func openScene(from: UIWindow?, info: SceneInfo, localContext: AnyObject? = nil, completion: ((UIWindow?, Error?) -> Void)?) {
        guard #available(iOS 13, *), supportsMultipleScenes else {
            completion?(nil, RouterError.notHandled)
            return
        }
        let scene = info.toScene()
        switch info.key {
        case .chat:
            #if MessengerMod
            let controllerService = ChatViewControllerServiceImpl(extraInfo: info.extraInfo)
            scene.userInfo["chatFromWhere"] = ChatFromWhere.vcMeeting.rawValue
            SceneManager.shared.active(scene: scene, from: from, localContext: controllerService) { window, error in
                if let vc = window?.rootViewController {
                    controllerService.associateToObject(vc)
                }
                completion?(window, error)
            }
            #else
            SceneManager.shared.active(scene: scene, from: from, localContext: localContext, callback: completion)
            #endif
        default:
            SceneManager.shared.active(scene: scene, from: from, localContext: localContext, callback: completion)
        }
    }

    @available(iOS 13, *)
    func closeScene(_ scene: SceneInfo, animation: SceneDismissalAnimation = .standard, errorHandler: ((Error) -> Void)? = nil) {
        SceneManager.shared.deactive(scene: scene.toScene(), animation: animation.sceneAnimation, errorHandler: errorHandler)
    }

    @available(iOS 13, *)
    func deactive(from: UIScene, animation: SceneDismissalAnimation = .standard, errorHandler: ((Error) -> Void)? = nil) {
        SceneManager.shared.deactive(from: from, animation: animation.sceneAnimation, errorHandler: errorHandler)
    }

    @available(iOS 13, *)
    func isConnected(scene: SceneInfo) -> Bool {
        SceneManager.shared.isConnected(scene: scene.toScene())
    }

    @available(iOS 13.0, *)
    func connectedScene(scene: SceneInfo) -> UIScene? {
        SceneManager.shared.connectedScene(scene: scene.toScene())
    }

    @available(iOS 13.0, *)
    func isValidScene(scene: UIWindowScene) -> Bool {
        !scene.sceneInfo.isInvalidScene() && !scene.windows.isEmpty && scene.delegate != nil
    }

    func trackEnterViewController(_ uniqueId: String) {
        #if LarkMod
        HMDFPSMonitor.shared().enterFluencyCustomScene(withUniq: uniqueId)
        #else
        Logger.ui.info("didEnterViewController: \(uniqueId)")
        #endif
    }

    func trackLeaveViewController(_ uniqueId: String) {
        #if LarkMod
        HMDFPSMonitor.shared().leaveFluencyCustomScene(withUniq: uniqueId)
        #else
        Logger.ui.info("didLeaveViewController: \(uniqueId)")
        #endif
    }

    lazy var pushCard: PushCardDependency = PushCardDependencyImpl()

    func imageByKey(_ key: String) -> UIImage? {
        EmotionResouce.shared.imageBy(key: key)
    }
}

extension LarkImageRequest: ByteViewUI.ImageRequest {}

extension BizAvatar: AvatarViewProtocol {
    private static let logger = Logger.getLogger("Avatar")

    public func setAvatarInfo(_ avatarInfo: AvatarInfo, size: AvatarSize) {
        switch avatarInfo {
        case .asset(let image):
            avatar.image = image
            avatar.backgroundColor = .clear
        case let .remote(key: key, entityId: entityId):
            Self.logger.info("setAvatar key = \(key), entityId is nil \(entityId).")
            backgroundColor = UIColor.ud.N300
            setAvatarByIdentifier(entityId, avatarKey: key, avatarViewParams: toSize(size))
        }
    }

    public func updateStyle(_ style: AvatarStyle) {
        switch style {
        case .square:
            avatar.updateConfig(.init(style: .square))
        default:
            avatar.updateConfig(.init(style: .circle))
        }
    }

    public func removeMaskView() {
        avatar.ud.removeMaskView()
    }

    /// 设置点击事件
    public func setTapAction(_ action: (() -> Void)?) {
        if let action = action {
            self.onTapped = { _ in action() }
        } else {
            self.onTapped = nil
        }
    }

    private func toSize(_ size: AvatarSize) -> ByteWebImage.AvatarViewParams {
        switch size {
        case .large:
            return .defaultBig
        case .medium:
            return .defaultMiddle
        case .size(let value):
            return .init(sizeType: .size(value))
        default:
            return .defaultThumb
        }
    }
}

private class UIScrollLoadingView: UIView, LoadingViewProtocol {
    private let loadingView = LoadingView(style: .blue)
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false
        self.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupLayout() {
        guard self.superview != nil else { return }
        self.snp.makeConstraints {
            $0.width.height.equalTo(16)
            $0.center.equalToSuperview()
        }
    }

    func startLoading() {
        self.isHidden = false
        self.loadingView.play()
    }

    func stopLoading() {
        self.loadingView.stop()
        self.isHidden = true
    }
}

private class UIScrollViewLoadMoreDelegateImpl: UIScrollViewLoadingDelegate {
    private weak var scrollView: UIScrollView?

    init(_ scrollView: UIScrollView?) {
        self.scrollView = scrollView
    }

    var bottomLoadingView: UIView? {
        self.scrollView?.bottomLoadMoreView
    }

    func addBottomLoading(handler: @escaping () -> Void) {
        self.scrollView?.addBottomLoadMoreView(loadingView: UIScrollLoadingView(), handler: handler)
    }

    func endBottomLoading(hasMore: Bool) {
        self.scrollView?.endBottomLoadMore(hasMore: hasMore)
    }

    func removeBottomLoading() {
        self.scrollView?.removeBottomLoadMore()
    }

    var topLoadingView: UIView? {
        self.scrollView?.topLoadMoreView
    }

    func addTopLoading(handler: @escaping () -> Void) {
        self.scrollView?.addTopLoadMoreView(height: 44.0, handler: handler)
    }

    func endTopLoading(hasMore: Bool) {
        self.scrollView?.endTopLoadMore()
    }

    func removeTopLoading() {
        self.scrollView?.removeTopLoadMore()
    }
}

private final class DefaultFocusTagView: UIView, UserFocusTagViewProtocol {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCustomStatuses(_ customStatuses: [Any]) {}

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 20)
    }
}

#if MessengerMod
import LarkFocus
import LarkFocusInterface
import LarkMessengerInterface

extension ChatViewControllerServiceImpl {
    convenience init(extraInfo: [String: Any]) {
        let messageCloseBlock = extraInfo["closeAction"] as? (() -> Void)
        let messageRenderBlock = extraInfo["messageRenderBlock"] as? (() -> Void)
        let messageDeinitBlock = extraInfo["messageDeinitBlock"] as? (() -> Void)
        self.init(messageCloseBlock: messageCloseBlock, messageRenderBlock: messageRenderBlock, messageDeinitBlock: messageDeinitBlock)
    }
}

private final class LarkFocusTagView: UIView, UserFocusTagViewProtocol {
    private lazy var tagView: FocusTagView = {
        let view = FocusTagView()
        view.isHidden = true
        addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }()

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.isHidden = true
        addSubview(view)
        view.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.edges.equalToSuperview()
        }
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isHidden = true
        self.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCustomStatuses(_ customStatuses: [Any]) {
        var currentStatus: Basic_V1_Chatter.ChatterCustomStatus?
        for case let status as Basic_V1_Chatter.ChatterCustomStatus in customStatuses {
            if status.effectiveInterval.isActive {
                currentStatus = status
                break
            }
        }
        guard let currentStatus = currentStatus else {
            self.isHidden = true
            return
        }
        self.subviews.forEach { $0.isHidden = true }
        // 使用主端提供的个人状态组件，包含普通状态、请假状态
        self.tagView.config(with: currentStatus)
        self.tagView.isHidden = false
        self.isHidden = false
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 20)
    }
}
#endif

extension SceneDismissalAnimation {
    var sceneAnimation: LarkSceneManager.SceneManager.DismissalAnimation {
        switch self {
        case .standard:
            return .standard
        case .commit:
            return .commit
        case .decline:
            return .decline
        }
    }
}

@available(iOS 13, *)
extension SceneInfo {
    func toScene() -> Scene {
        switch key {
        case .main:
            return .mainScene()
        default:
            return Scene(key: key.rawValue, id: id, title: title, needRestoration: true, userInfo: userInfo, windowType: windowType, createWay: createWay)
        }
    }
}
