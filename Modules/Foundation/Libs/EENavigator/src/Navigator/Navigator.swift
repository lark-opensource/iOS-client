//
//  Navigator.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/6.
//

import Foundation
import UIKit

/// @available(*, deprecated, message: "Will bew removed sometime in the future")
public protocol LKSplitVCDelegate: AnyObject {

    var lkTopMost: UIViewController? { get }
    var lkTabIdentifier: String? { get }
}

public typealias QueryHandler = ((NaviParams, [String: Any], Navigator), @escaping Completion) -> Void

public typealias NavigatorTimeTracker = (String, String, NavigatorType, Int64) -> Void

/// Route navigation type
@objc public enum NavigatorType: Int {
    case unknow, present, push, showDetail, didAppear
}

private struct NavigatorTracker {
    /// start time
    var navigatorStartTime: Date = Date()

    /// the controller name to open from
    var fromVCClassName: String = ""

    /// the controller hashValue to open
    var toVCHashValue: Int = -1

    /// the callback to track time
    var navigatorTimeTracker: NavigatorTimeTracker?

    var shouldTrack: Bool = false

    init(navigatorStartTime: Date = Date(),
         fromVCClassName: String = "",
         toVCHashValue: Int = 0,
         shouldTrack: Bool = false,
         navigatorTimeTracker: NavigatorTimeTracker? = nil) {
        self.navigatorStartTime = navigatorStartTime
        self.fromVCClassName = fromVCClassName
        self.shouldTrack = shouldTrack
        self.toVCHashValue = toVCHashValue
        self.navigatorTimeTracker = navigatorTimeTracker
    }

    mutating func reset() {
        self.navigatorStartTime = Date()
        self.shouldTrack = false
        self.fromVCClassName = ""
        self.toVCHashValue = -1
    }
}

// swiftlint:disable type_body_length
open class Navigator: Router, Navigatable {

    private struct OpenTypeItem {
        let matcher: URLMatcher
        let handler: OpenTypeHandler
    }

    @objc
    public private(set) static var shared = Navigator()

//    @available(*, deprecated, message: "此接口由于适配 UIScene 原因已废弃, 请选择其他接口获取 Navigation")
    public var navigation: UINavigationController? {
        return self.navigationProvider?()
    }

//    @available(*, deprecated, message: "此接口由于适配 UIScene 原因已废弃, 请选择其他接口获取 Navigation")
    public var navigationProvider: (() -> UINavigationController)?

    /// 用于获取 FG 值
    public var featureGatingProvider: ((_ key: String) -> Bool)?

    /// tabProvider for find & switch ability
//    @available(*, deprecated, message: "此接口由于适配 UIScene 原因已废弃, 请选择其他接口获取 Tab")
    public var tabProvider: (() -> TabProvider)?

    private var navigatorTracker: NavigatorTracker = NavigatorTracker()

    private var queryHandlers: [QueryHandler] = []

    private var openTypeHandlers: [OpenTypeItem] = []

    private override init() {
        let popToHandler: QueryHandler = { (args, completion) in
            let (parameters, context, navigator) = args
            if let popToURL = parameters.popTo,
               let from = context.from() {
                navigator.popTo(
                    popToURL,
                    from: from,
                    animated: false,
                    completion: completion
                )
            } else {
                completion()
            }
        }

        let switchTabHandler: QueryHandler = { (args, completion) in
            let (parameters, context, navigator) = args
            if let switchTabURL = parameters.switchTab,
               let from = context.from() {
                navigator.switchTab(
                    switchTabURL,
                    from: from,
                    completion: completion)
            } else {
                completion()
            }
        }

        self.queryHandlers = [popToHandler, switchTabHandler]
    }

    @discardableResult
    public static func resetSharedNavigator() -> Navigator {
        shared = Navigator()
        return shared
    }

    public func registerOpenType(
        pattern: String,
        _ handler: @escaping OpenTypeHandler) {
        let matcher = PathPatternURLMatcher(pattern: pattern)
        let item = OpenTypeItem(matcher: matcher, handler: handler)
        self.openTypeHandlers.append(item)
    }

    public func registerOpenType(
        plainPattern: String,
        _ handler: @escaping OpenTypeHandler) {
        let matcher = PlainURLMatcher(pattern: plainPattern)
        let item = OpenTypeItem(matcher: matcher, handler: handler)
        self.openTypeHandlers.append(item)
    }

    public func registerOpenType(
        regExpPattern: String,
        _ handler: @escaping OpenTypeHandler) {
        let matcher = RegExpURLMatcher(regExpPattern: regExpPattern)
        let item = OpenTypeItem(matcher: matcher, handler: handler)
        self.openTypeHandlers.append(item)
    }

    /// Time tracker
    /// - Parameters:
    ///   - from: the controller to open from
    ///   - to: the controller to open
    ///   - navigatorType: present / push / showDetail / didAppear
    func timeTracker(
        from: NavigatorFrom,
        to: UIViewController,
        navigatorType: NavigatorType = .unknow) {
        var fromVCClassName = ""
        var toVCHashValue = to.hashValue

        var toVCClassName = NSStringFromClass(type(of: to))

        if let fromVC = from.fromViewController,
            !(fromVC is UINavigationController) {
            fromVCClassName = NSStringFromClass(type(of: fromVC))
        }
        self.navigatorTracker.fromVCClassName = fromVCClassName

        if let navigationVC = to as? UINavigationController, let lastVC = navigationVC.viewControllers.last {
            toVCClassName = NSStringFromClass(type(of: lastVC))
            toVCHashValue = lastVC.hashValue
        }
        self.navigatorTracker.toVCHashValue = toVCHashValue

        let time = Int64(Date().timeIntervalSince(self.navigatorTracker.navigatorStartTime) * 1000)

        self.navigatorTracker.navigatorTimeTracker?(fromVCClassName, toVCClassName, navigatorType, time)

        self.navigatorTracker.navigatorStartTime = Date()
        self.navigatorTracker.shouldTrack = true
    }

    /// vc didAppear Time tracker
    /// - Parameters:
    ///   - toVC: the controller name to open
    @objc public func didAppearTimeTracker(toVC: UIViewController) {
        guard self.navigatorTracker.shouldTrack, toVC.hashValue == self.navigatorTracker.toVCHashValue else {
            return
        }

        var toVCClassName = NSStringFromClass(type(of: toVC))
        if let navigationVC = toVC as? UINavigationController, let lastVC = navigationVC.viewControllers.last {
            toVCClassName = NSStringFromClass(type(of: lastVC))
        }

        let time = Int64(Date().timeIntervalSince(self.navigatorTracker.navigatorStartTime) * 1000)

        self.navigatorTracker.navigatorTimeTracker?(
            self.navigatorTracker.fromVCClassName,
            toVCClassName,
            .didAppear,
            time
        )

        self.navigatorTracker.reset()
    }

    /// update NavigatorTimeTracker Callback
    /// - Parameter navigatorTimeTracker: the callback to track time
    public func updateNavigatorTimeTracker(_ navigatorTimeTracker: @escaping NavigatorTimeTracker) {
        self.navigatorTracker.navigatorTimeTracker = navigatorTimeTracker
    }

    /// update Navigator Start Time
    public func updateNavigatorStartTime() {
        self.navigatorTracker.navigatorStartTime = Date()
    }

    // swiftlint:disable function_body_length

    /// push by url
    ///
    /// - Parameters:
    ///   - url: the url for the resource
    ///   - context: addtional data pass to the request
    ///   - from: the controller to push from
    ///   - animated: with animation or not
    ///   - completion: completion handler
    public func push(
        _ url: URL,
        context: [String: Any] = [:],
        from: NavigatorFrom,
        animated: Bool = true,
        completion: Handler? = nil) {
        push(url, context: context, from: from, forcePush: nil, animated: animated, completion: completion)
    }

    func defaultOpenType(url: URL, context: [String: Any], backup: OpenType?) -> NavigatorOpenRequest.RequestOpenType {
        let designatedOpenType = self.openTypeHandlers.first { (item) -> Bool in
            return item.matcher.match(url: url).matched
        }.map { (item) -> OpenType? in
            return item.handler(url, context)
        }
        let openType: OpenType = (designatedOpenType ?? backup) ?? .push
        switch openType {
        case .present: return .present(wrap: nil, prepare: nil)
        case .showDetail: return .showDetail(wrap: nil)
        case .none:
            fallthrough
        case .push:
            return .push(forcePush: false)
        }
    }

    public func open(_ req: NavigatorOpenRequest) {
        var url = req.url
        var context = req.context
        let completion = req.completion

        var naviParams = self.getNaviParams(from: url, context: context)
        let animated = req.animated ?? naviParams.animated
        let reqOpenType = req.openType ?? defaultOpenType(url: url, context: context, backup: naviParams.openType)
        let openType = reqOpenType.rawValue

        self.updateNavigatorStartTime()
        let urlID = url.absoluteString.hashValue

        Router.logger.debug("Start \(openType) URL: \(urlID)")
        let from = self.transform(from: req.from)
        self.merge(from: from, openType: openType, to: &context)
        naviParams.openType = openType
        naviParams.animated = animated
        if case let .push(forcePush?) = reqOpenType {
            naviParams.forcePush = forcePush
        }

        let fragment = url.fragment
        url = self.normalize(url)

        if openType == .push, !naviParams.forcePush,
            self.checkAndPop(url, context: context, from: from, animated: animated, completion: completion) {
            notifyLocateOrPopObservers(for: url, context: context)
            Router.logger.info("No need to push, pop to destination controller: \(urlID)")
            return
        }

        // Async redirect
        let redirect: RedirectHandler = self
            .wrapRedirctHandler(fragment: fragment, naviParams: naviParams) { [weak self] (url, context) in
                self?.open(NavigatorOpenRequest(
                    url: url, context: context, from: from,
                    openType: reqOpenType, animated: animated,
                    completion: completion
                    ))
            }
        context[ContextKeys.acyncRedirect] = redirect

        let res = self.response(for: url, context: context)

        func innerOpen(with resource: Resource?) {
            let url = res.request.url
            let context = res.request.context
            guard let controller = resource as? UIViewController,
                openType != .push || !(controller is UINavigationController)
            else {
                var (isVC, isNav) = (false, false)
                if let avc = resource as? UIViewController {
                    isVC = true
                    isNav = avc is UINavigationController
                }

                Router.logger.info("Cannot \(openType), wrong format of resource: \(urlID), isVC: \(isVC), isNav: \(isNav)")
                res.end(error: RouterError.resourceWithWrongFormat.patchExtraInfo(
                    with: url.absoluteString,
                    from: from,
                    naviParams: naviParams))
                completion?(res.request, res)
                return
            }

            let callback: () -> Void
            switch reqOpenType {
            case .push:
                func innerPush() {
                    if !naviParams.forcePush,
                       (context[ContextKeys.body] as? Body)?.forcePush != true,
                       self.checkAndPop(url, context: context, from: from, animated: animated, completion: completion) {
                        self.notifyLocateOrPopObservers(for: url, context: context)
                        Router.logger.info(
                            "No need to push, pop to destination controller: \(urlID)"
                        )
                        return
                    }
                    guard let navigationController = from
                        .fromViewController?.nearestNavigation else {
                        Router.logger.info("Cannot find a UINavigationController to push: \(urlID)")
                            res.end(error: RouterError.cannotPush.patchExtraInfo(with: url.absoluteString,
                                                                                 from: from,
                                                                                 naviParams: naviParams))
                        completion?(res.request, res)
                        return
                    }
                    if (context[ContextKeys.checkPushSafety] as? Bool) == true,
                       self.blockPush(target: controller, with: navigationController, url: url, context: context, animated: animated, completion: completion) {
                        Router.logger.info(
                            "No need to push, pop to exists controller: \(urlID)"
                        )
                        return
                    }
                    when(
                        animated: animated,
                        action: { [weak self] in
                            Router.logger.debug("Begin push: \(urlID)")
                            self?.timeTracker(from: from, to: controller, navigatorType: .push)
                            navigationController.pushViewController(controller, animated: animated)
                            return navigationController
                        },
                        completion: {
                            Router.logger.debug("Push end: \(urlID)")
                            completion?(res.request, res)
                        }
                    )
                }
                callback = innerPush
            case let .present(wrap: wrap, prepare: prepare):
                func innerPresent() {
                    guard let presentFrom = from.fromViewController else {
                        Router.logger.info("Cannot find a host to present: \(urlID)")
                        res.end(error: RouterError.cannotPresent.patchExtraInfo(with: url.absoluteString,
                                                                                from: from,
                                                                                naviParams: naviParams))
                        completion?(res.request, res)
                        return
                    }
                    let presentController: UIViewController
                    if let wrap = wrap, !(controller is UINavigationController) {
                        presentController = wrap.init(rootViewController: controller)
                    } else {
                        presentController = controller
                    }
                    prepare?(presentController)

                    Router.logger.debug("Begin present: \(urlID)")

                    self.timeTracker(from: presentFrom, to: presentController, navigatorType: .present)
                    presentFrom.present(presentController, animated: animated) {
                        Router.logger.debug("Present end: \(urlID)")
                        completion?(res.request, res)
                    }
                }
                callback = innerPresent
            case let .showDetail(wrap: wrap):
                func innerShowDetail() {
                    guard let showFrom = from.fromViewController else {
                        Router.logger.info("Cannot showDetail, cannot find the host: \(urlID)")
                        res.end(error: RouterError.cannotShowDetail.patchExtraInfo(with: url.absoluteString,
                                                                                   from: from,
                                                                                   naviParams: naviParams))
                        completion?(res.request, res)
                        return
                    }
                    let detailController: UIViewController
                    if let wrap = wrap, !(controller is UINavigationController) {
                        detailController = wrap.init(rootViewController: controller)
                    } else {
                        detailController = controller
                    }

                    Router.logger.debug("Begiin showDetail: \(urlID)")
                    self.timeTracker(from: from, to: detailController, navigatorType: .showDetail)
                    showFrom.showDetailViewController(detailController, sender: nil)
                    completion?(res.request, res)
                }
                callback = innerShowDetail
            }
            combine(handlers: self.queryHandlers)((naviParams, context, self), callback)
        }

        if let asyncResult = res.resource as? AsyncResult {
            Router.logger.debug("\(openType) async result: \(urlID)")
            asyncResult.add { (result) in
                if result.error != nil {
                    Router.logger.info("\(openType) async result with error: \(urlID)")
                    completion?(res.request, res)
                } else {
                    Router.logger.debug("\(openType) async result: \(urlID)")
                    innerOpen(with: result.resource)
                }
            }
        } else if res.error == nil {
            Router.logger.debug("\(openType) sync result: \(urlID)")
            innerOpen(with: res.resource)
        } else {
            Router.logger.info("\(openType) sync result with error: \(urlID)")
            completion?(res.request, res)
        }
    }

    public func open(_ req: NavigatorOpenControllerRequest) {
        self.updateNavigatorStartTime()
        innerOpen(req)
    }

    func innerOpen(_ req: NavigatorOpenControllerRequest) {
        let from = req.from
        let viewController = req.controller
        let animated = req.animated
        let completion = req.completion
        switch req.openType {
        case let .present(wrap: wrap, prepare: prepare):
            guard let presentFrom = from.fromViewController else {
                return
            }

            var controller = viewController
            if let wrap = wrap, !(controller is UINavigationController) {
                controller = wrap.init(rootViewController: controller)
            }

            prepare?(controller)

            self.timeTracker(from: from, to: viewController, navigatorType: .present)
            presentFrom.present(controller, animated: animated, completion: completion)
        case let .showDetail(wrap: wrap):
            guard let showFrom = from.fromViewController else {
                return
            }

            let detailController: UIViewController
            if let wrap = wrap, !(viewController is UINavigationController) {
                detailController = wrap.init(rootViewController: viewController)
            } else {
                detailController = viewController
            }

            self.timeTracker(from: from, to: detailController, navigatorType: .showDetail)
            showFrom.showDetailViewController(detailController, sender: nil)
            completion?()
        case nil: fallthrough
        case .push:
            guard let navigation = from.fromViewController?.nearestNavigation else {
                // TODO: 日志？错误回调？
                return
            }
            when(
                animated: animated,
                action: { [weak self] in
                    self?.timeTracker(from: from, to: viewController, navigatorType: .push)
                    navigation.pushViewController(viewController, animated: animated)
                    return navigation
                },
                completion: completion
            )
        }
    }

    public func globalValid() -> Bool { return true }

    @_disfavoredOverload
    public func switchTab(
        _ url: URL,
        from: NavigatorFrom,
        animated: Bool = false,
        completion: Completion? = nil
    ) {
        let completion = completion.flatMap { origin in return { (_: Bool) in origin() } }
        self.switchTab(url, from: from, animated: animated, completion: completion)
    }

    /// switch tab by url
    ///
    /// - Parameters:
    ///   - url: the url for the resource
    ///   - completion: completion handler, pass in true if success switch
    public func switchTab(
        _ url: URL,
        from: NavigatorFrom,
        animated: Bool = false,
        completion: ((Bool) -> Void)? = nil) {

        let url = self.normalize(url)
        guard let tabProvider = tabProvider?(), let tabbar = tabProvider.tabbarController else {
            Router.logger.info("Cannot switchTab, cannot find the tabbarController: \(url.absoluteString.hashValue)")
            assertionFailure("Switch tab by url failed")
            completion?(false)
            return
        }

        Router.logger.debug("Begin switchTab: \(url.absoluteString.hashValue)")
        self.popTo(tabbar, animated: animated) { [weak tabbar] in
            tabbar?.switchTab(by: url.identifier, tabProvider: tabProvider)
            if let top = from.fromViewController, let fragment = url.fragment {
                Router.logger.debug("Begin locate in page: \(url.absoluteString.hashValue)")
                locate(target: top, animated: animated, by: fragment)
            }
            completion?(true)
        }
    }

    private func popTo(
        _ url: URL,
        from: NavigatorFrom,
        animated: Bool = true,
        completion: Completion? = nil) {

        let url = self.normalize(url)
        guard let ancestor = from.fromViewController?.findAncestor(by: url.identifier) else {
            Router.logger.info("Cannot pop, cannot find the ancestor: \(url.absoluteString.hashValue)")
            assertionFailure("PopTo by url failed")
            completion?()
            return
        }

        Router.logger.debug("Begin pop to: \(url.absoluteString.hashValue)")
        self.popTo(ancestor, animated: animated, completion: completion)
    }

    typealias Step = (@escaping Completion) -> Void
    /// pop to previous controller
    ///
    /// - Parameters:
    ///   - ancestor: previous controller
    ///   - animated: with animation or not
    ///   - completion: completion handler
    private func popTo(
        _ ancestor: UIViewController,
        animated: Bool = true,
        completion: Completion? = nil) {

        func makeStep(with block: @escaping () -> UIViewController?) -> Step {
            return { comp in
                if let controller = block() {
                    willDismiss(target: controller, animated: false)
                    controller.dismiss(animated: false, completion: comp)
                } else {
                    comp()
                }
            }
        }

        weak var ancestor = ancestor

        let step1 = makeStep { ancestor?.navigationController?.presentedViewController }
        let step2 = makeStep { ancestor?.tabBarController?.presentedViewController }
        let step3 = makeStep { ancestor?.presentedViewController }

        let step4: Step = { comp in
            when(
                animated: animated,
                action: {
                    guard let ancestor = ancestor else {
                        return nil
                    }
                    var controller = ancestor
                    if let tabbar = ancestor as? UITabBarController,
                        let selectedViewController = tabbar.selectedViewController {
                        controller = selectedViewController
                    }
                    // If ancestor is UINavigationController
                    // It means that ancestor is wrapped by a UINavigationController with the given identifier
                    // In this case pop to rootViewController
                    // Else pop to ancestor
                    if let navigationController = controller as? UINavigationController {
                        navigationController.popToRootViewController(animated: animated)
                        return navigationController
                    } else {
                        controller.navigationController?.popToViewController(ancestor, animated: animated)
                        return controller.navigationController
                    }
                },
                completion: comp
            )
        }

        combine(handlers: [step1, step2, step3, step4])(completion ?? {})
    }
}

public extension Navigatable {

    /// get view controller by body.
    func getResource<T: Body>(
        body: T,
        context: [String: Any] = [:],
        completion: ((Resource?) -> Void)?) {

        let context = context.merging(body: body)
        self.getResource(
            body._url,
            context: context,
            completion: completion
        )
    }

    /// get view controller by url.
    func getResource(
        _ url: URL,
        context: [String: Any] = [:],
        completion: ((Resource?) -> Void)?) {

        var context = context
        // Async redirect
        let redirect: RedirectHandler = { (url, context) in
            self.getResource(url, context: context, completion: completion)
        }
        context[ContextKeys.acyncRedirect] = redirect

        let res = self.response(for: url, context: context)
        if let asyncResult = res.resource as? AsyncResult {
            asyncResult.add { (result) in
                completion?(result.resource)
            }
        } else {
            completion?(res.resource)
        }
    }
}

extension Navigator {
    private func checkAndPop(
        _ url: URL,
        context: [String: Any],
        from: NavigatorFrom,
        animated: Bool,
        completion: Handler?
    ) -> Bool {
        if let sibling = from.fromViewController?.findSibling(by: url.identifier) {
            self.popTo(sibling, animated: animated) { [weak sibling] in
                let res = self.initResponse(for: url, context: context)
                let req = res.request
                if let fragment = url.fragment, let sibling = sibling {
                    locate(target: sibling, animated: animated, by: fragment, with: req.parameters)
                }
                res.end(resource: EmptyResource())
                completion?(req, res)
            }
            return true
        }
        return false
    }

    private func blockPush(
        target: UIViewController,
        with navigationController: UINavigationController,
        url: URL,
        context: [String: Any],
        animated: Bool,
        completion: Handler?
    ) -> Bool {
        guard let exists = navigationController.viewControllers.first(where: { $0 == target }) else {
            return false
        }
        self.popTo(exists, animated: animated) {
            let res = self.initResponse(for: url, context: context)
            let req = res.request
            res.end(resource: EmptyResource())
            completion?(req, res)
        }
        return true
    }

    /// 对 from 进行转化
    ///  目的有两个
    ///  1 from 会被存储进 context，我们不希望强持有 from，需要进行封装
    ///  2 如果 原始 from 被释放，我们仍然希望能够获取对应上下文，需要尝试获取原始 from 更高层级的 UI context
    ///  举例：如果原始 from 是 viewController，那么我们会尝试获取 vc 的 window /  Scene，那么即使 from 被释放了，我们依然可以获取正确 UI context 并完成 UI 跳转
    private func transform(from: NavigatorFrom) -> NavigatorFrom {
        if from is NavigatorFromWrapper {
            return from
        }
        return NavigatorFromWrapper(from)
    }

    private func merge(from: NavigatorFrom, openType: OpenType, to context: inout [String: Any]) {
        context[ContextKeys.from] = from
        context[ContextKeys.openType] = openType
    }

    private func getNaviParams(from url: URL, context: [String: Any]) -> NaviParams {
        if let naviParams = context[ContextKeys.naviParams] as? NaviParams {
            return naviParams
        }

        let dict = (url.queryParameters as [String: Any]).merging(context, uniquingKeysWith: { _, cKey in cKey })
        return NaviParams.parse(from: dict, with: decoder)
    }

    private func wrapRedirctHandler(
        fragment: String?,
        naviParams: NaviParams,
        _ handler: @escaping RedirectHandler) -> RedirectHandler {

        return { url, context in
            let url = url.append(fragment: fragment, forceNew: false)
            var context = context
            if context[ContextKeys.naviParams] == nil {
                context[ContextKeys.naviParams] = naviParams
            }
            handler(url, context)
        }
    }
}

/// 使用路由进行导致的请求
public struct NavigatorOpenRequest {
    public enum RequestOpenType {
        case push(forcePush: Bool?)
        case present(wrap: UINavigationController.Type?, prepare: ((UIViewController) -> Void)?)
        case showDetail(wrap: UINavigationController.Type?)
        public var rawValue: OpenType {
            switch self {
            case .push: return .push
            case .present: return .present
            case .showDetail: return .showDetail
            }
        }
    }

    public var url: URL
    public var context: [String: Any]
    public var from: NavigatorFrom
    public var openType: RequestOpenType?
    public var animated: Bool?
    public var completion: Handler?
    public init(
        url: URL,
        context: [String: Any] = [:],
        from: NavigatorFrom,
        openType: RequestOpenType? = nil,
        animated: Bool? = nil,
        completion: Handler? = nil
    ) {
        self.url = url
        self.context = context
        self.from = from
        self.openType = openType
        self.animated = animated
        self.completion = completion
    }
}

/// 直接使用Controller产物进行导航的请求
public struct NavigatorOpenControllerRequest {
    public var controller: UIViewController
    public var from: NavigatorFrom
    public var openType: Navigatable.RequestOpenType?
    public var animated: Bool
    public var completion: Completion?
    public init(
        controller: UIViewController,
        from: NavigatorFrom,
        openType: Navigatable.RequestOpenType? = nil,
        animated: Bool = true,
        completion: Completion? = nil
    ) {
        self.controller = controller
        self.from = from
        self.openType = openType
        self.animated = animated
        self.completion = completion
    }
}

/// 方便包装Navigator的协议，提供核心使用接口的声明和统一的protocol方法扩展
public protocol Navigatable: Routable {
    typealias RequestOpenType = NavigatorOpenRequest.RequestOpenType
    func open(_ params: NavigatorOpenRequest)
    func open(_ params: NavigatorOpenControllerRequest)
    /// return true if the navigator is still valid to interact with global view
    func globalValid() -> Bool
    /// - Parameter completion: 调用结果，传入是否成功
    func switchTab(_ url: URL, from: NavigatorFrom, animated: Bool, completion: ((Bool) -> Void)?)
}
