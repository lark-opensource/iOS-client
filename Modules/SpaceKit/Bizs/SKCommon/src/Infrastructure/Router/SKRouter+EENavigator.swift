//
//  SKRouter+EENavigator.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/8/7.
//  

import EENavigator
import LarkUIKit
import SKFoundation
import SKUIKit
import LarkSplitViewController
import LarkNavigator
import SKInfra

extension EENavigator.Navigator: DocsExtensionCompatible {}
extension UserNavigator: DocsExtensionCompatible {}

extension DocsExtension where BaseType: Navigatable {
    // MARK: - ShowDetailOrPush
    public func showDetailOrPush(
        _ viewController: UIViewController,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil) {
        var toViewController = viewController
        if viewController.needShowInDetail && SKDisplay.pad,
           let svc = from.lkSplitViewController,
           from.navigationController != svc.secondaryViewController {
            if let wrap = wrap, !(viewController is UINavigationController) {
                toViewController = wrap.init(rootViewController: viewController)
            } else {
                toViewController = viewController
            }
            base.showDetail(toViewController, wrap: wrap, from: from, completion: completion)
        } else {
            base.push(viewController, from: from, animated: animated, completion: completion)
        }
    }

    public func showDetailOrPush(
        _ url: URL,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: UIViewController,
        forcePush: Bool? = nil,
        animated: Bool = true,
        completion: Handler? = nil) {
        if url.needShowInDetail && SKDisplay.pad,
           let svc = from.lkSplitViewController,
           from.navigationController != svc.secondaryViewController {
            base.showDetail(url,
                            context: context,
                            wrap: wrap,
                            from: from,
                            completion: completion)
        } else {
            base.push(url,
                      context: context,
                      from: from,
                      forcePush: forcePush,
                      animated: animated,
                      completion: completion)
        }
    }

    public func showDetailOrPush<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: UIViewController,
        animated: Bool = true,
        completion: Handler? = nil) {
        var newParams: NaviParams = naviParams ?? NaviParams()
        newParams.forcePush = true
        if body.needShowInDetail && SKDisplay.pad,
           let svc = from.lkSplitViewController,
           from.navigationController != svc.secondaryViewController {
            base.showDetail(body: body,
                            naviParams: newParams,
                            context: context,
                            wrap: wrap,
                            from: from,
                            completion: completion)
        } else {
            base.push(body: body,
                      naviParams: newParams,
                      context: context,
                      from: from,
                      animated: animated,
                      completion: completion)
        }
    }

    // MARK: - ShowMasterOrPush
    public func showMasterOrPush(
        _ viewController: UIViewController,
        wrap: UINavigationController.Type? = nil,
        from: UIViewController,
        animated: Bool = true) {
        var toViewController = viewController
        if let wrap = wrap, !(viewController is UINavigationController) {
            toViewController = wrap.init(rootViewController: viewController)
        } else {
            toViewController = viewController
        }

        var fromVC = from
        if viewController.needShowInMaster && SKDisplay.pad {
            fromVC = from.larkSplitViewController?.primaryViewController ?? from
        }

        fromVC.navigationController?.pushViewController(toViewController, animated: animated)
    }

    public func showMasterOrPush(
        _ url: URL,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: UIViewController,
        animated: Bool = true,
        completion: Handler? = nil) {
        var fromVC = from
        if url.needShowInMaster && SKDisplay.pad {
            fromVC = from.larkSplitViewController?.primaryViewController ?? from
        }
        base.push(url,
                  context: context,
                  from: fromVC,
                  animated: animated,
                  completion: completion)
    }
    public func showMasterOrPush<T: Body>(
        body: T,
        naviParams: NaviParams? = nil,
        context: [String: Any] = [:],
        wrap: UINavigationController.Type? = nil,
        from: UIViewController,
        animated: Bool = true,
        completion: Handler? = nil) {
        var fromVC = from
        if body.needShowInMaster && SKDisplay.pad {
            fromVC = from.larkSplitViewController?.primaryViewController ?? from
        }
        var newParams: NaviParams = naviParams ?? NaviParams()
        newParams.forcePush = true
        base.push(body: body,
                  naviParams: newParams,
                  context: context,
                  from: fromVC,
                  animated: animated,
                  completion: completion)
    }
}

// MARK: - Private
private extension UIViewController {
    var needShowInMaster: Bool {
        return isFolderDetail
    }
    var needShowInDetail: Bool {
        return !isFolderDetail
    }
    private var isFolderDetail: Bool {
        guard let subVC = DocsContainer.shared.resolve(SubFolderVCProtocol.self) else {
            spaceAssert(false, "SubFolderVCProtocol injection failed")
            DocsLogger.error("SubFolderVCProtocol injection failed")
            return false
        }
        return subVC.isSubFolderViewController(self)
    }
}

private extension URL {
    var needShowInMaster: Bool {
        return isFolder
    }

    var needShowInDetail: Bool {
        return !isFolder
    }

    private var isFolder: Bool {
        return DocsUrlUtil.getFileType(from: self) == .folder
    }
}

private extension Body {
    var needShowInMaster: Bool {
        return isFolder
    }

    var needShowInDetail: Bool {
        return !isFolder
    }

    private var isFolder: Bool {
        guard let entryBody = self as? SKEntryBody else {
            return false
        }
        return entryBody.file.type == .folder
    }
}
