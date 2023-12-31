//
//  SearchEntityGeneratorUserTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/3/29.
//

import XCTest
import RustPB
import LarkModel
@testable import LarkSearchCore
// swiftlint:disable all
final class SearchEntityGeneratorUserTest: XCTestCase {
    typealias Config = PickerConfig.ChatterEntityConfig
    typealias SearchType = Search_V2_UniversalFilters.UserFilter.SearchType
    
    func testGenerateUser() {
        let entity = config { _ in }
        XCTAssertEqual(entity.type, .user)
    }
    
    func testTalk() {
        XCTContext.runActivity(named: "all") { activity in
            let entity = config { $0.talk = .all }
            let talked = Int32(SearchType.talked.rawValue)
            let unTalked = Int32(SearchType.unTalked.rawValue)
            let type = entity.entityFilter.userFilter.searchType.first ?? 0
            XCTAssertEqual(type | talked, type)
            XCTAssertEqual(type | unTalked, type)
        }
        XCTContext.runActivity(named: "talk") { activity in
            let entity = config { $0.talk = .talked }
            let value = Int32(SearchType.talked.rawValue)
            let type = entity.entityFilter.userFilter.searchType.first ?? 0
            XCTAssertEqual(type | value, type)
        }
        XCTContext.runActivity(named: "untalked") { activity in
            let entity = config { $0.talk = .untalked }
            let value = Int32(SearchType.unTalked.rawValue)
            let type = entity.entityFilter.userFilter.searchType.first ?? 0
            XCTAssertEqual(type | value, type)
        }
    }
    
    func testRisigned() {
        XCTContext.runActivity(named: "all") { activity in
            let entity = config { $0.resign = .all }
            let resigned = Int32(SearchType.resigned.rawValue)
            let unResigned = Int32(SearchType.unResigned.rawValue)
            let type = entity.entityFilter.userFilter.searchType.first ?? 0
            XCTAssertEqual(type | resigned, type)
            XCTAssertEqual(type | unResigned, type)
        }
        XCTContext.runActivity(named: "unresigned") { activity in
            let entity = config { $0.resign = .unresigned }
            let value = Int32(SearchType.unResigned.rawValue)
            let type = entity.entityFilter.userFilter.searchType.first ?? 0
            XCTAssertEqual(type | value, type)
        }
        XCTContext.runActivity(named: "resigned") { activity in
            let entity = config { $0.resign = .resigned }
            let value = Int32(SearchType.resigned.rawValue)
            let type = entity.entityFilter.userFilter.searchType.first ?? 0
            XCTAssertEqual(type | value, type)
        }
    }

    /// 在职 和 离职聊过
    func testWorkedAndTalkedResign() {
        var config1 = PickerConfig.ChatterEntityConfig()
        config1.resign = .unresigned
        var config2 = PickerConfig.ChatterEntityConfig()
        config2.resign = .resigned
        config2.talk = .talked
        let entity = SearchEntityGenerator.getUserEntity(by: [config2, config1])
        let unResigned = Int32(SearchType.unResigned.rawValue)
        let resigned = Int32(SearchType.resigned.rawValue)
        let unTalked = Int32(SearchType.unTalked.rawValue)
        let type = entity.entityFilter.userFilter.searchType.first ?? 0
        XCTAssertNotEqual(type | unResigned, type)
        XCTAssertEqual(type | resigned, type)
        XCTAssertEqual(type | unTalked, type)
        XCTAssertTrue(entity.entityFilter.userFilter.exclude)
    }

    func testOnlyRelatedOrganization() {
        let entity = config {
            $0.tenant = .all
            $0.externalFriend = .noExternalFriend
        }
        XCTAssertTrue(entity.entityFilter.userFilter.excludeOuterContact)
    }

    /// 多次设置实体时, 以最后一个设置为准
    func testRepeatProperty() {
        var config1 = PickerConfig.ChatterEntityConfig()
        config1.talk = .talked
        var config2 = PickerConfig.ChatterEntityConfig()
        config2.talk = .untalked
        let entity = SearchEntityGenerator.getUserEntity(by: [config1, config2])
        let value = Int32(SearchType.unTalked.rawValue)
        let type = entity.entityFilter.userFilter.searchType.first ?? 0
        XCTAssertEqual(type | value, type)
    }
    
    // MARM: - Field
    func testInChat() {
        let id = UUID().uuidString
        let entity = config {
            $0.field = .init(chatIds: [id])
        }
        XCTAssertEqual(entity.entitySelector.userSelector.isInChatID, id)
    }
    func testInDirectoryTeam() {
        let id = UUID().uuidString
        let entity = config {
            $0.field = .init(directlyTeamIds: [id])
        }
        XCTAssertEqual(entity.entitySelector.userSelector.isDirectlyInTeamID, id)
    }
    func testRelationTag() {
        let entity = config {
            var field = PickerConfig.ChatterField()
            field.relationTag = true
            $0.field = field
        }
        XCTAssertTrue(entity.entitySelector.userSelector.relationTag)
    }
    
    // MARK: - Private
    private func config(transform: (inout Config) -> Void) -> Search_V2_BaseEntity.EntityItem {
        var config = PickerConfig.ChatterEntityConfig()
        transform(&config)
        let entity = SearchEntityGenerator.getUserEntity(by: [config])
        return entity
    }
}
// swiftlint:enable all
