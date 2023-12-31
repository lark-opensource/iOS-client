//
//  ProfileFactory.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/6/24.
//

import Foundation
import Swinject
import LarkContainer

public struct ProfileContext {
    var data: ProfileData

    init(data: ProfileData) {
        self.data = data
    }
}

public protocol ProfileFactory: AnyObject {
    func createTabs(by profile: ProfileInfoProtocol, context: ProfileContext, provider: ProfileDataProvider) -> [ProfileTabItem]

    func createProfile(by data: ProfileData) -> ProfileViewController?
}

public protocol LarkProfileTab: ProfileTab {
    static func createTab(by tab: LarkUserProfilTab,
                          resolver: UserResolver,
                          context: ProfileContext,
                          profile: ProfileInfoProtocol,
                          dataProvider: ProfileDataProvider) -> ProfileTabItem?

    func update(_ profile: ProfileInfoProtocol, context: ProfileContext)
}

extension LarkProfileTab {
    public func update(_ profile: ProfileInfoProtocol, context: ProfileContext) { }
}
