//
//  UserAliasInfo.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/11/14.
//

import Foundation
import LarkLocalizations
import SwiftyJSON
import SpaceInterface

public extension UserAliasInfo {
    var dictionaryRepresentation: [String: Any] {
        return [
            CodingKeys.displayName.rawValue: displayName ?? "",
            CodingKeys.i18nDisplayNames.rawValue: i18nDisplayNames
        ]
    }
}

public extension UserAliasInfo {
    typealias CodingProxy = UserAliasInfoCodingProxy

    var codingProxy: CodingProxy {
        return CodingProxy(wrapping: self)
    }
}

public final class UserAliasInfoCodingProxy: NSCoding {

    public let info: UserAliasInfo

    public init(wrapping info: UserAliasInfo) {
        self.info = info
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(info.displayName, forKey: UserAliasInfo.CodingKeys.displayName.rawValue)
        coder.encode(info.i18nDisplayNames, forKey: UserAliasInfo.CodingKeys.i18nDisplayNames.rawValue)
    }
    
    public required init?(coder: NSCoder) {
        let displayName = coder.decodeObject(forKey: UserAliasInfo.CodingKeys.displayName.rawValue) as? String
        let i18nDisplayNames = coder.decodeObject(forKey: UserAliasInfo.CodingKeys.i18nDisplayNames.rawValue) as? [String: String] ?? [:]
        info = UserAliasInfo(displayName: displayName, i18nDisplayNames: i18nDisplayNames)
    }
}
