//
//  Navigator+PresentOrPush.swift
//  LarkNavigator
//
//  Created by lixiaorui on 2019/9/3.
//

import EENavigator
import LarkUIKit

extension Navigatable {

    // ipad 走present
    // iphone 走push
    public func presentOrPush<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: UIViewController,
        prepareForPresent: ((UIViewController) -> Void)? = nil,
        animated: Bool = true,
        completion: Handler? = nil) {
        if Display.pad {
            present(body: body, naviParams: naviParams, context: context, wrap: wrap, from: from, prepare: prepareForPresent, animated: animated, completion: completion)
        } else {
            push(body: body, naviParams: naviParams, context: context, from: from, animated: animated, completion: completion)
        }
    }

    public func presentOrPush(
        _ url: URL,
        naviParams: NaviParams? = nil,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: UIViewController,
        prepareForPresent: ((UIViewController) -> Void)? = nil,
        animated: Bool = true,
        completion: Handler? = nil) {
        if Display.pad {
            present(url, context: context, wrap: wrap, from: from, prepare: prepareForPresent, animated: animated, completion: completion)
        } else {
            push(url, context: context, from: from, animated: animated, completion: completion)
        }
    }

    public func presentOrPush(
        _ viewController: UIViewController,
        wrap: UINavigationController.Type? = nil,
        from: UIViewController,
        prepareForPresent: ((UIViewController) -> Void)? = nil,
        animated: Bool = true,
        completion: Completion? = nil) {
        if Display.pad {
            present(viewController, wrap: wrap, from: from, prepare: prepareForPresent, animated: animated, completion: completion)
        } else {
            push(viewController, from: from, animated: animated, completion: completion)
        }
    }
}
