//
//  PickerMailUserEntityConfig.swift
//  LarkModel
//
//  Created by ByteDance on 2023/10/4.
//

import Foundation

public extension PickerConfig {
    struct MailUserEntityConfig: MailUserEntityConfigType, Codable {
        public var type: SearchEntityType = .mailUser
        public var extras: Dictionary<String,String>

        public init(extras: Dictionary<String,String> = [:]) {
            self.extras = extras
        }
    }
}
