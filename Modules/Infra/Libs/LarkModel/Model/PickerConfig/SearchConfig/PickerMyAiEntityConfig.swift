//
//  PickerMyAiEntityConfig.swift
//  LarkModel
//
//  Created by Yuri on 2023/6/20.
//

import Foundation

public extension PickerConfig {
    struct MyAiEntityConfig: MyAiEntityConfigType, TalkConfigurable, Codable {
        public var type: SearchEntityType = .myAi
        public var talk: TalkCondition = .all

        public init(talk: TalkCondition) {
            self.talk = talk
        }
    }
}
