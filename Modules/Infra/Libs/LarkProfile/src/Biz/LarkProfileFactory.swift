//
//  LarkProfileFactory.swift
//  LarkContact
//
//  Created by 姚启灏 on 2021/8/3.
//

import Foundation
import LarkContainer
import Swinject
import LarkFeatureGating
import LKCommonsLogging
import LarkSetting

public final class LarkProfileTabs {
    public static var shared = LarkProfileTabs()
    public var tabs: [String: LarkProfileTab.Type] = [LarkProfileFieldTab.tabId: LarkProfileFieldTab.self,
                                                       LarkProfileSectionTab.tabId: LarkProfileSectionTab.self]
    
    public func registerTab(_ type: LarkProfileTab.Type) {
        guard self.tabs[type.tabId] == nil else {
            assertionFailure("Tab already exists")
            return
        }
        self.tabs[type.tabId] = type
    }
}
public final class LarkProfileFactory: ProfileFactory, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver
    
    @ScopedInjectedLazy var dependency: LarkProfileDataProviderDependency?
    static let logger = Logger.log(LarkProfileFactory.self, category: "LarkProfileFactory")
    
    /// 是否使用技术优化后的profile vc展示
    private lazy var refactorProfile: Bool = userResolver.fg.staticFeatureGatingValue(with: "core.profile.tech_refactor")

    public init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }

    public func createTabs(by profile: ProfileInfoProtocol, context: ProfileContext, provider: ProfileDataProvider) -> [ProfileTabItem] {
        var tabItem: [ProfileTabItem] = []
        for tab in profile.tabOrders {
            for (_, type) in LarkProfileTabs.shared.tabs {
                if let item = type.createTab(by: tab,
                                             resolver: self.userResolver,
                                             context: context,
                                             profile: profile,
                                             dataProvider: provider) {
                    tabItem.append(item)
                    break
                }
            }
        }
        return tabItem
    }

    public func createProfile(by data: ProfileData) -> ProfileViewController? {
        let fg = refactorProfile
        LarkProfileFactory.logger.info("Profile.VC: refactor profile fg: \(fg)")
        if fg {
            guard let data = data as? LarkProfileData else {
                return nil
            }
            let dataprovider = NewProfileDataProvider(data: data, resolver: userResolver, factory: self)
            dataprovider.dependency = dependency
            dataprovider.factory = self
            let vc = NewProfileViewController(resolver: userResolver, provider: dataprovider)
        
            if let data = data as? LarkProfileData, let id = data.extraParams?["tab"] {
                vc.setDefaultSelected(identifier: id)
            }
            return vc
        } else {
            guard let dataprovider = LarkProfileDataProvider.createDataProvider(by: data, resolver: userResolver, factory: self) as? LarkProfileDataProvider else {
                return nil
            }

            let vc = ProfileViewController(resolver: userResolver, provider: dataprovider)
            dataprovider.dependency = dependency
            dataprovider.factory = self

            if let data = data as? LarkProfileData, let id = data.extraParams?["tab"] {
                vc.setDefaultSelected(identifier: id)
            }

            return vc
        }
    }
}
