//
//  PickerSearchConfigTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/4/10.
//

import XCTest
import LarkModel
// swiftlint:disable all
final class PickerSearchConfigTest: XCTestCase {
    typealias Chatter = PickerConfig.ChatterEntityConfig
    typealias Chat = PickerConfig.ChatEntityConfig
    typealias Doc = PickerConfig.DocEntityConfig
    typealias Wiki = PickerConfig.WikiEntityConfig
    typealias WikiSpace = PickerConfig.WikiSpaceEntityConfig
    typealias UserGroup = PickerConfig.UserGroupEntityConfig

    func testConfigToJson() {
        let config = PickerSearchConfig(entities: [
            Chatter(),
            Chat(field: .init(relationTag: true, directlyTeamIds: [])),
            Doc(),
            Wiki(),
            WikiSpace(),
            UserGroup(category: .all, userGroupVisibilityType: .ccm)
        ], permission: [])
        let json = try! JSONEncoder().encode(config)
        let jsonString = String(data: json, encoding: .utf8) ?? ""
        print(jsonString)
        XCTAssertFalse(jsonString.isEmpty)
    }

    func testJsonToConfig() {
        let config = PickerSearchConfig(entities: [
            Chatter(),
            Chat(field: .init(relationTag: true, directlyTeamIds: [])),
            Doc(),
            Wiki(),
            WikiSpace(),
            UserGroup()
        ], permission: [.inviteEvent])
        let json = try! JSONEncoder().encode(config)
        let jsonString = String(data: json, encoding: .utf8) ?? ""
//        let jsonString = """
//{"entities":{"chatters":[{"tenant":"inner","talk":"talked","type":"chatter","resign":"unresigned","relatedOrganization":"all"}],"chats":[{"shield":"noShield","tenant":"inner","owner":"all","frozen":"noFrozened","join":"joined","publicType":"all","crypto":"normal","type":"chat"}]},"permissions":[12]}
//"""
        XCTAssertFalse(jsonString.isEmpty)
        let newJson = jsonString.data(using: .utf8)
        let result = try! JSONDecoder().decode(PickerSearchConfig.self, from: newJson!)
        XCTAssertEqual(result.entities.count, 6)
    }
}
// swiftlint:enable all
