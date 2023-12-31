//
//  ProfileTab.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/6/25.
//

import Foundation
import UIKit

public struct ProfileTabItem {
    let title: String
    let identifier: String
    let profileCallBack: (() -> ProfileTab)?
    let supportReuse: Bool
    var profileTab: ProfileTab?

    public init(title: String,
                identifier: String,
                supportReuse: Bool = true,
                profileCallBack: (() -> ProfileTab)? = nil) {
        self.title = title
        self.identifier = identifier
        self.supportReuse = supportReuse
        self.profileCallBack = profileCallBack
    }
}

public protocol ProfileTab: SegmentedTableViewContentable {
    static var tabId: String { get }
    var itemId: String { get }
    var profileVC: UIViewController? { get set }
}

public final class ProfileBaseTab: SegmentedTableViewContent, ProfileTab {
    public static var tabId: String {
        return ""
    }

    public var itemId: String = ""

    public var profileVC: UIViewController?
}
