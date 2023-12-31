//
//  SideBarBody.swift
//  LarkNavigation
//
//  Created by 袁平 on 2021/3/11.
//

import UIKit
import Foundation
import EENavigator
import LarkNavigator

public struct SideBarBody: PlainBody {
    public static let pattern = "//client/sidebar/home"
    public var hostProvider: UIViewController?

    public init(hostProvider: UIViewController?) {
        self.hostProvider = hostProvider
    }
}

final class SideBarHandler: UserTypedRouterHandler {

    func handle(_ body: SideBarBody, req: EENavigator.Request, res: Response) throws {
        let mineViewController = (try? sideBarVC?(userResolver, body.hostProvider)) ?? UIViewController()
        let vc = SideBarViewController(
            tenantVC: try TenantViewControllerFactory.createTenantVC(userResolver: userResolver),
            mineViewController: mineViewController)
        res.end(resource: vc)
    }
}

public struct SideBarFilterBody: PlainBody {
    public static let pattern = "//client/sidebar/filter"
    public var hostProvider: UIViewController?

    public init(hostProvider: UIViewController?) {
        self.hostProvider = hostProvider
    }
}

final class SideBarFilterHandler: UserTypedRouterHandler {

    func handle(_ body: SideBarFilterBody, req: EENavigator.Request, res: Response) throws {
        let filterViewController = (try? sideBarFilterVC?(userResolver, body.hostProvider)) ?? UIViewController()
        let vc = SideBarFilterListViewController(
            filterViewController: filterViewController)
        res.end(resource: vc)
    }
}
