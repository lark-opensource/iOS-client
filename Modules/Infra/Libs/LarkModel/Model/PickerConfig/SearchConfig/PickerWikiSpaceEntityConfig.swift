//
//  PickerWikiSpaceEntityConfig.swift
//  LarkModel
//
//  Created by Yuri on 2023/5/23.
//

import Foundation
import RustPB

extension Search_V2_UniversalFilters.WikiSpaceFilter.SpaceType: Codable {}

public extension PickerConfig {
    struct WikiSpaceEntityConfig: WikiSpaceEntityConfigType, Codable {

        public var type: SearchEntityType = .wikiSpace
        public var wikiSpaceTypes: [Search_V2_UniversalFilters.WikiSpaceFilter.SpaceType] = []

        public init(wikiSpaceTypes: [Search_V2_UniversalFilters.WikiSpaceFilter.SpaceType] = []) {
            self.wikiSpaceTypes = wikiSpaceTypes
        }
    }
}
