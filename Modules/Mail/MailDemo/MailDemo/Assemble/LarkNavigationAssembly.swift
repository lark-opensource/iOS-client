//
//  NavigationDependencyImpl.swift
//  LarkApp
//
//  Created by CharlieSu on 11/29/19.
//

//import Foundation
//import RxSwift
//import Swinject
//import LarkNavigation
//import LarkContainer
//import LarkUIKit
//import LarkMessengerInterface
//import RxCocoa
//import LarkSDKInterface
//import LarkMailInterface
//import LarkAssembler
//
//public final class LarkNavigationAssembly: Assembly, LarkAssemblyInterface {
//
//    public init() { }
//
//    public func assemble(container: Container) {
//        // sub assembly
//        registContainer(container: container)
//    }
//
//    public func registContainer(container: Container) {
//        container.register(NavigationDependency.self) { _ -> NavigationDependency in
//            return NavigationDependencyImpl(resolver: container)
//        }
//    }
//
//    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
//        NavigationAssembly()
//    }
//    public func asyncAssemble() {
//
//    }
//}
//
//fileprivate class NavigationDependencyImpl: NavigationDependency {
//    func notifyMailNaviUpdated(isEnabled: Bool) {
//    }
//
//    func updateBadge(to count: Int) {
//        badgeService.setIconBadgeNumber(count)
//    }
//
//    private let resolver: Resolver
//
//    init(resolver: Resolver) {
//        self.resolver = resolver
//    }
//
//
//
//    private lazy var userGeneralSettings: UserGeneralSettings = { return resolver.resolve(UserGeneralSettings.self)! }()
//    private var badgeService = ApplicationBadgeNumber.shared
//
//    func checkOnboardingIfNeeded() -> Observable<Void> {
//        return Observable.empty()
//    }
//
//    var shouldNoticeNewVerison: Observable<Bool> {
//        return Observable.empty()
//    }
//
//    var doNotDisturbType: Observable<NaviBarDoNotDisturbType> {
//        return userGeneralSettings.doNotDisturbType.asObservable().map { (type) -> NaviBarDoNotDisturbType in
//            switch type {
//            case .none:
//                return NaviBarDoNotDisturbType.none
//            case .normal:
//                return NaviBarDoNotDisturbType.normal
//            case .deadLine:
//                return NaviBarDoNotDisturbType.deadLine
//            default:
//                return NaviBarDoNotDisturbType.none
//            }
//        }
//    }
//
//    var mailEnable: Bool {
//        return resolver.resolve(LarkMailInterface.self)?.checkLarkMailTabEnable() ?? false
//    }
//
//    func notifyMailNaviEnabled() {
//        resolver.resolve(LarkMailInterface.self)?.notifyMailNaviUpdated(isEnabled: true)
//    }
//
//    func notifyVideoConferenceTabEnabled() {
//
//    }
//}
