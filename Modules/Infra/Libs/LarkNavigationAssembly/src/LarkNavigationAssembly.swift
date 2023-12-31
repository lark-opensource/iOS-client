//
//  NavigationDependencyImpl.swift
//  LarkApp
//
//  Created by CharlieSu on 11/29/19.
//

import Foundation
import RxSwift
import RxCocoa
import Swinject
import LarkContainer
import LarkUIKit
import LarkNavigation
import LarkQuickLaunchInterface
import LarkTab
import EENavigator
#if canImport(LarkOPInterface)
import LarkOPInterface
#endif
#if canImport(LarkSDKInterface)
import LarkSDKInterface
#endif
import LarkAssembler

#if canImport(LarkVersion)
import LarkVersion
#endif
#if canImport(LarkMailInterface)
import LarkMailInterface
#endif
#if canImport(ByteViewTab)
import ByteViewTab
#endif
#if canImport(LarkMessengerInterface)
import LarkMessengerInterface
#endif

public final class LarkNavigationAssembly: LarkAssemblyInterface {

    public init() { }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(.userV2)
        user.register(NavigationDependency.self) { (r) -> NavigationDependency in
            return NavigationDependencyImpl(userResolver: r)
        }
    }
    
    public func registRouter(container: Container) {
#if canImport(LarkMessengerInterface)
        Navigator.shared.registerRoute.type(NavigationSearchEnterBody.self)
        .factory(NavigationSearchEnterHandler.init(resolver:))
#endif
    }

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        NavigationAssembly()
    }
}

fileprivate final class NavigationDependencyImpl: NavigationDependency {
    func updateBadge(to count: Int) {
        ApplicationBadgeNumber.shared.setIconBadgeNumber(count)
    }

    private let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func createOPAppTabRepresentable(tab: Tab) -> TabRepresentable {
#if canImport(LarkOPInterface)
        return OPAppTabRepresentable(tab: tab)
#else
        return DefaultTabRepresentable(tab: tab)
#endif
    }

    var shouldNoticeNewVerison: Observable<Bool> {
#if canImport(LarkVersion)
        let versionService = try? self.userResolver.resolve(assert: VersionUpdateService.self)
        return versionService?.shouldNoticeNewVerison.asObservable() ?? .empty()
#else
        return .empty()
#endif
    }

    var mailEnable: Bool {
#if canImport(LarkMailInterface)
        return (try? self.userResolver.resolve(assert: LarkMailInterface.self))?.checkLarkMailTabEnable() ?? false
#else
        return false
#endif
    }

    func notifyMailNaviUpdated(isEnabled: Bool) {
#if canImport(LarkMailInterface)
        (try? self.userResolver.resolve(assert: LarkMailInterface.self))?.notifyMailNaviUpdated(isEnabled: isEnabled)
#endif
    }

    func notifyVideoConferenceTabEnabled() {
#if canImport(ByteViewTab)
        (try? self.userResolver.resolve(assert: ByteViewTab.TabBadgeService.self))?.notifyTabEnabled()
        (try? self.userResolver.resolve(assert: ByteViewTab.TabGuideService.self))?.notifyTabEnabled()
#endif
    }

    func getMedalKey() -> String {
#if canImport(LarkSDKInterface)
        let chatterManager = try? self.userResolver.resolve(assert: ChatterManagerProtocol.self)
        return chatterManager?.currentChatter.medalKey ?? ""
#else
        return ""
#endif
    }

    func updateMedalAvatar(medalUpdate: ((_ entityId: String, _ avatarKey: String, _ medalKey: String) -> Void)?) {
#if canImport(LarkSDKInterface)
        let chatterManager = try? self.userResolver.resolve(assert: ChatterManagerProtocol.self)
        _ = chatterManager?.currentChatterObservable.subscribe(onNext: { [weak self] (currentChatter) in
            guard let self = self, let medalUpdate = medalUpdate else { return }
            /// 防止头像提前更新到其他租户上
            guard self.userResolver.userID == currentChatter.id else { return }
            medalUpdate(currentChatter.id, currentChatter.avatarKey, currentChatter.medalKey)
        })
#endif
    }

    func notifyNavigationAppInfos(appInfos: [OpenNavigationAppInfo]) {
        // todo: 业务方实现了协议后把这里打开
        (try? self.userResolver.resolve(assert: OpenNavigationProtocol.self))?.notifyNavigationAppInfos(appInfos: appInfos)
    }

    func getSearchVC(fromTabURL: URL?, sourceOfSearchStr: String?, entryAction: String) -> UIViewController? {
#if canImport(LarkMessengerInterface) && canImport(LarkSearch)
        let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self)
        let model = SearchEnterModel(fromTabURL: fromTabURL,
                                     sourceOfSearchStr: sourceOfSearchStr,
                                     entryAction: SearchEntryAction(rawValue: entryAction) ?? .unKnown)
        return searchOuterService?.getCurrentSearchPadVC(searchEnterModel: model)
#else
        return nil
#endif
    }

    func getSearchOnPadEntranceView() -> UIView {
#if canImport(LarkMessengerInterface) && canImport(LarkSearch)
        let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self)
        return searchOuterService?.getSearchOnPadEntranceView() ?? .init()
#else
        return .init()
#endif
    }
    func changeSelectedState(isSelect: Bool) {
#if canImport(LarkMessengerInterface) && canImport(LarkSearch)
        let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self)
        searchOuterService?.changeSelectedState(isSelect: isSelect)
#endif
    }

    func enableUseNewSearchEntranceOnPad() -> Bool {
#if canImport(LarkMessengerInterface) && canImport(LarkSearch)
        let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self)
        return searchOuterService?.enableUseNewSearchEntranceOnPad() ?? false
#else
        return false
#endif
    }
}

