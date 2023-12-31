//
//  Extension+Navigator.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/30.
//

import UIKit
import Foundation

extension Navigatable {

    /// Pop current view controller
    ///
    /// - Parameters:
    ///   - from: find the nearest controller to pop from
    ///   - animated: with animation or not
    ///   - completion: completion handler
    public func pop(
        from: NavigatorFrom,
        animated: Bool = true,
        completion: Completion? = nil) {

        guard let navigation = from.fromViewController?.nearestNavigation else {
            return
        }
        when(animated: animated, action: { () -> UINavigationController? in
            navigation.popViewController(animated: animated)
            return navigation
        }, completion: completion)

    }

    /// Push with view controller
    ///
    /// - Parameters:
    ///   - viewController: the view controller to be pushed
    ///   - from: the controller to push from
    ///   - animated: with animation or not
    ///   - completion: completion handler
    public func push(
        _ viewController: UIViewController,
        from: NavigatorFrom,
        animated: Bool = true,
        completion: Completion? = nil) {
            self.open(NavigatorOpenControllerRequest(
                controller: viewController, from: from, openType: .push(forcePush: nil),
                animated: animated, completion: completion
                ))
    }

    /// Present with view controller
    ///
    /// - Parameters:
    ///   - viewController: the view controller to be presented
    ///   - wrap: class of UINavigationController to be wrapped
    ///   - from: the controller to present from
    ///   - prepare: when get controller from resource, do something to prepare for presenting
    ///   - animated: with animation or not
    ///   - completion: completion handler
    public func present(
        _ viewController: UIViewController,
        wrap: UINavigationController.Type? = nil,
        from: NavigatorFrom,
        prepare: ((UIViewController) -> Void)? = nil,
        animated: Bool = true,
        completion: Completion? = nil) {
            self.open(NavigatorOpenControllerRequest(
                controller: viewController, from: from, openType: .present(wrap: wrap, prepare: prepare),
                animated: animated, completion: completion
                ))
    }

    /// Present with view controller
    ///
    /// - Parameters:
    ///   - viewController: the view controller to be presented
    ///   - wrap: class of UINavigationController to be wrapped
    ///   - from: the controller to present from
    ///   - completion: completion handler
    public func showDetail(
        _ viewController: UIViewController,
        wrap: UINavigationController.Type? = nil,
        from: NavigatorFrom,
        completion: Completion? = nil) {
            self.open(NavigatorOpenControllerRequest(
                controller: viewController, from: from, openType: .showDetail(wrap: wrap),
                animated: true, completion: completion
                ))
    }
}

extension Navigatable {
    /// present by url
    ///
    /// - Parameters:
    ///   - url: the url for the resource
    ///   - context: addtional data pass to the request
    ///   - wrap: class of UINavigationController to be wrapped
    ///   - from: the controller to present from
    ///   - prepare: when get controller from resource, do something to prepare for presenting
    ///   - animated: with animation or not
    ///   - completion: completion handler
    public func present(
        _ url: URL,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: NavigatorFrom,
        prepare: ((UIViewController) -> Void)? = nil,
        animated: Bool = true,
        completion: Handler? = nil) {

        self.open(NavigatorOpenRequest(
            url: url, context: context, from: from,
            openType: .present(wrap: wrap, prepare: prepare), animated: animated,
            completion: completion
            ))
    }

    /// Present using model
    ///
    /// - Parameters:
    ///   - body: request body
    ///   - naviParams: navigation parameters
    ///   - context: addtional context pass to requst
    ///   - wrap: class of UINavigationController to be wrapped
    ///   - from: the controller to present from
    ///   - prepare: when get controller from resource, do something to prepare for presenting
    ///   - animated: with animation or not
    ///   - completion: completion handler
    public func present<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: NavigatorFrom,
        prepare: ((UIViewController) -> Void)? = nil,
        animated: Bool = true,
        completion: Handler? = nil) {

        var context = context.merging(body: body)
        if let naviParams = naviParams {
            context = context.merging(naviParams: naviParams)
        }
        self.present(
            body._url,
            context: context,
            wrap: wrap,
            from: from,
            prepare: prepare,
            animated: animated,
            completion: completion
        )
    }

    /// push by url
    /// - Parameters:
    ///   - url: the url for the resource
    ///   - context: addtional data pass to the request
    ///   - from: the controller to push from
    ///   - forcePush: whether force push new vc when vc with same id is already in navi stack. This param's priority is higher than NaviParams's forcePush property
    ///   - animated: with animation or not
    ///   - completion: completion handler
    public func push(
        _ url: URL,
        context: [String: Any] = [:],
        from: NavigatorFrom,
        forcePush: Bool? = nil,
        animated: Bool = true,
        completion: Handler? = nil) {

        self.open(NavigatorOpenRequest(
            url: url, context: context, from: from,
            openType: .push(forcePush: forcePush), animated: animated,
            completion: completion
            ))
    }

    /// Push using model
    ///
    /// - Parameters:
    ///   - body: request body
    ///   - naviParams: navigation parameters
    ///   - context: addtional context pass to requst
    ///   - from: the controller to push from
    ///   - animated: with animation or not
    ///   - completion: completion handler
    public func push<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        context: [String: Any] = [:],
        from: NavigatorFrom,
        animated: Bool = true,
        completion: Handler? = nil) {

        var context = context.merging(body: body)
        if let naviParams = naviParams {
            context = context.merging(naviParams: naviParams)
        }
        self.push(
            body._url,
            context: context,
            from: from,
            forcePush: body.forcePush,
            animated: animated,
            completion: completion
        )
    }

    public func open(
        _ url: URL,
        context: [String: Any] = [:],
        from: NavigatorFrom,
        useDefaultOpenType: Bool = true,
        completion: Handler? = nil) {
        // useDefaultOpenType 原来实现是直接回调给调用方，不进行push或者present.
        // 这个选项没有人用，被废弃，忽略该参数。
        // 有需求时再重新实现..

        self.open(NavigatorOpenRequest(
            url: url,
            context: context,
            from: from,
            completion: completion
        ))
    }

    /// Send a request
    ///
    /// - Parameters:
    ///   - body: request body
    ///   - naviParams: navigation parameters
    ///   - context: addtional context pass to requst
    ///   - from: the controller to open from\
    ///   - useDefaultOpenType: use push as default openType
    ///   - completion: completion handler
    public func open<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        context: [String: Any] = [:],
        from: NavigatorFrom,
        useDefaultOpenType: Bool = true,
        completion: Handler? = nil) {

        var context = context.merging(body: body)
        if let naviParams = naviParams {
            context = context.merging(naviParams: naviParams)
        }
        self.open(
            body._url,
            context: context,
            from: from,
            useDefaultOpenType: useDefaultOpenType,
            completion: completion
        )
    }

    public func showDetail(
        _ url: URL,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: NavigatorFrom,
        completion: Handler? = nil) {

        self.open(NavigatorOpenRequest(
            url: url, context: context, from: from,
            openType: .showDetail(wrap: wrap), animated: nil,
            completion: completion
            ))
    }

    /// Show detail using model
    ///
    /// - Parameters:
    ///   - body: request body
    ///   - naviParams: navigation parameters
    ///   - context: addtional context pass to requst
    ///   - wrap: class of UINavigationController to be wrapped
    ///   - from: the controller to show detail from
    ///   - completion: completion handler
    public func showDetail<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: NavigatorFrom,
        completion: Handler? = nil) {

        var context = context.merging(body: body)
        if let naviParams = naviParams {
            context = context.merging(naviParams: naviParams)
        }
        self.showDetail(
            body._url,
            context: context,
            wrap: wrap,
            from: from,
            completion: completion
        )
    }
}
