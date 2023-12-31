//
//  ProfileHeaderView.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/6/20.
//

import UIKit
import Foundation
import UniverseDesignTag
import LarkTag
import LarkFocusInterface

public struct ProfileUserInfo {
    public var id: String?
    public var name: String
    public var alias: String = ""
    public var pronouns: String = ""
    public var nameTag: [UIView] = []
    public var customBadges: [UIView] = []
    public var descriptionView: UIView?
    public var companyView: UIView?
    public var focusList: [ChatterFocusStatus] = []
    public var isSelf: Bool
    public var metaUnitDescription: String?
}
