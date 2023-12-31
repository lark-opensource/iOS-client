//
//  BTStatisticManager+setting.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/11/22.
//

import Foundation

extension BTStatisticManager {
    func enable(key: String) -> Bool {
        return configSetting[key] as? Bool ?? false
    }
}
