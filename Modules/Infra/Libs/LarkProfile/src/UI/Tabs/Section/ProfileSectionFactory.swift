//
//  ProfileSectionFactory.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/12/29.
//

import Foundation
import UIKit

public final class ProfileSectionFactory {

    private static var profileSectionProviderType: [ProfileSectionProvider.Type] = [ProfileSectionSkeletonProvider.self,
                                                                                    ProfileSectionNormalProvider.self]

    public static func register(type: ProfileSectionProvider.Type) {
        guard !ProfileSectionFactory.profileSectionProviderType.contains(where: { $0 == type }) else {
            return
        }
        profileSectionProviderType.append(type)
    }

    public static func createWithItem(_ item: ProfileSectionItem, fromVC: UIViewController?) -> ProfileSectionProvider? {
        for type in profileSectionProviderType {
            if var provider = type.init(item: item) {
                provider.fromVC = fromVC
                return provider
            }
        }
        return nil
    }

    public static func createWithItems(_ items: [ProfileSectionItem], fromVC: UIViewController?) -> [ProfileSectionProvider] {
        var providers: [ProfileSectionProvider] = []
        for item in items {
            if let provider = ProfileSectionFactory.createWithItem(item, fromVC: fromVC) {
                providers.append(provider)
            }
        }
        return providers
    }
}
