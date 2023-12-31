//
//  String+MinutesURLCheck.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/2/28.
//

import Foundation
import LarkSetting

extension MinsWrapper where Base == String {

    public func isLarkDomain() -> Bool {
        guard let setting = domainSetting(),
              let pattern = setting.hostList.first,
              let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(location: 0, length: base.utf16.count)
        return regex.firstMatch(in: base, options: [], range: range) != nil
    }

    public func isMinutesPath() -> Bool {
        guard let setting = domainSetting(),
              let pattern = setting.detail.first,
              let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(location: 0, length: base.utf16.count)
        return regex.firstMatch(in: base, options: [], range: range) != nil
    }

    public func isHomePath() -> Bool {
        guard let setting = domainSetting(),
              let pattern = setting.homeList.first,
              let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(location: 0, length: base.utf16.count)
        return regex.firstMatch(in: base, options: [], range: range) != nil
    }

    public func isMyPath() -> Bool {
        guard let setting = domainSetting(),
              let pattern = setting.myList.first,
              let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(location: 0, length: base.utf16.count)
        return regex.firstMatch(in: base, options: [], range: range) != nil
    }

    public func isSharePath() -> Bool {
        guard let setting = domainSetting(),
              let pattern = setting.shareList.first,
              let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(location: 0, length: base.utf16.count)
        return regex.firstMatch(in: base, options: [], range: range) != nil
    }

    public func isTrashPath() -> Bool {
        guard let setting = domainSetting(),
              let pattern = setting.trashList.first,
              let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(location: 0, length: base.utf16.count)
        return regex.firstMatch(in: base, options: [], range: range) != nil
    }

    func domainSetting() -> MinutesDomainSetting? {
        if let setting = try? SettingManager.shared.staticSetting(with: MinutesDomainSetting.self) {
            return setting
        }
        return defaultSetting()
    }

    func defaultSetting() -> MinutesDomainSetting {
        return MinutesDomainSetting(hostList: ["\\S*.feishu(-(pre|staging|boe))?\\.cn$|\\S*.larksuite(-(pre|staging|boe))?\\.com$"],
                                    myList: ["/(minutes|minutes_feishu)/me[/]?$"],
                                    homeList: ["/(minutes|minutes_feishu)/home[/]?$"],
                                    trashList: ["/(minutes|minutes_feishu)/trash[/]?$"],
                                    shareList: ["/(minutes|minutes_feishu)/shared[/]?$"],
                                    detail: ["/(minutes|minutes_feishu)/(ob|mm)(\\w{22})[/]?$"])
    }
}

struct MinutesDomainSetting: SettingDecodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "vc_mm_url_pattern_iOS")
    let hostList: [String]
    let myList: [String]
    let homeList: [String]
    let trashList: [String]
    let shareList: [String]
    let detail: [String]
}
