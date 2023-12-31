//
//  SearchEntityGeneratorChatTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/4/3.
//

import XCTest
import RustPB
import LarkModel
@testable import LarkSearchCore
// swiftlint:disable all
final class SearchEntityGeneratorChatTest: XCTestCase {
    typealias Config = PickerConfig.ChatEntityConfig
    typealias SearchType = Search_V2_UniversalFilters.ChatFilter.SearchType
    
    func testGenerateUser() {
        let entity = config { _ in }
        XCTAssertEqual(entity.type, .groupChat)
    }
    
    func testOwner() {
        XCTContext.runActivity(named: "all") { activity in
            let entity = config { $0.owner = .all }
            XCTAssertFalse(entity.entityFilter.groupChatFilter.addableAsUser)
        }
        XCTContext.runActivity(named: "owned") { activity in
            let entity = config { $0.owner = .ownered }
            XCTAssertTrue(entity.entityFilter.groupChatFilter.addableAsUser)
        }
    }
    
    func testJoined() {
        XCTContext.runActivity(named: "all") { activity in
            let entity = config { $0.join = .all }
            let joined = Int32(SearchType.joined.rawValue)
            let unjoined = Int32(SearchType.unJoined.rawValue)
            let type = entity.entityFilter.groupChatFilter.searchTypes.first ?? 0
            XCTAssertNotEqual(joined | type, joined)
            XCTAssertNotEqual(unjoined | type, unjoined)
        }
        XCTContext.runActivity(named: "joined") { activity in
            let entity = config { $0.join = .joined }
            let value = Int32(SearchType.joined.rawValue)
            let type = entity.entityFilter.groupChatFilter.searchTypes.first ?? 0
            XCTAssertEqual(type | value, type)
        }
        XCTContext.runActivity(named: "unjoined") { activity in
            let entity = config { $0.join = .unjoined }
            let value = Int32(SearchType.unJoined.rawValue)
            let type = entity.entityFilter.groupChatFilter.searchTypes.first ?? 0
            XCTAssertEqual(type | value, type)
        }
    }
    
    func testTenant() {
        XCTContext.runActivity(named: "all") { activity in
            let entity = config { $0.tenant = .all }
            let unCrossTenant = Int32(SearchType.unCrossTenant.rawValue)
            let crossTenant = Int32(SearchType.crossTenant.rawValue)
            let type = entity.entityFilter.groupChatFilter.searchTypes.first ?? 0
            XCTAssertNotEqual(unCrossTenant | type, unCrossTenant)
            XCTAssertNotEqual(crossTenant | type, crossTenant)
        }
        XCTContext.runActivity(named: "outer") { activity in
            let entity = config { $0.tenant = .outer }
            let value = Int32(SearchType.crossTenant.rawValue)
            let type = entity.entityFilter.groupChatFilter.searchTypes.first ?? 0
            XCTAssertEqual(type | value, type)
        }
        XCTContext.runActivity(named: "inner") { activity in
            let entity = config { $0.tenant = .inner }
            let value = Int32(SearchType.unCrossTenant.rawValue)
            let type = entity.entityFilter.groupChatFilter.searchTypes.first ?? 0
            XCTAssertEqual(type | value, type)
        }
    }

    func testPublicType() {
        XCTContext.runActivity(named: "all") { activity in
            let entity = config { $0.publicType = .all }
            let pub = Int32(SearchType.public.rawValue)
            let pri = Int32(SearchType.private.rawValue)
            let type = entity.entityFilter.groupChatFilter.searchTypes.first ?? 0
            XCTAssertNotEqual(pub | type, pub)
            XCTAssertNotEqual(pri | type, pri)
        }
        XCTContext.runActivity(named: "public") { activity in
            let entity = config { $0.publicType = .public }
            let value = Int32(SearchType.public.rawValue)
            let type = entity.entityFilter.groupChatFilter.searchTypes.first ?? 0
            XCTAssertEqual(type | value, type)
        }
        XCTContext.runActivity(named: "private") { activity in
            let entity = config { $0.publicType = .private }
            let value = Int32(SearchType.private.rawValue)
            let type = entity.entityFilter.groupChatFilter.searchTypes.first ?? 0
            XCTAssertEqual(type | value, type)
        }
    }

    func testShield() {
        XCTContext.runActivity(named: "notShield") { activity in
            let entity = config { $0.shield = .noShield }
            XCTAssertFalse(entity.entityFilter.groupChatFilter.searchShield)
        }
        XCTContext.runActivity(named: "isShield") { activity in
            let entity = config { $0.shield = .shield }
            XCTAssertTrue(entity.entityFilter.groupChatFilter.searchShield)
        }
    }
    
    func testFrozen() {
        XCTContext.runActivity(named: "all") { activity in
            let entity = config { $0.frozen = .all }
            XCTAssertTrue(entity.entityFilter.groupChatFilter.needFrozenChat)
        }
        XCTContext.runActivity(named: "isShield") { activity in
            let entity = config { $0.frozen = .noFrozened }
            XCTAssertFalse(entity.entityFilter.groupChatFilter.needFrozenChat)
        }
    }

    func testCrypto() {
        XCTContext.runActivity(named: "all") { activity in
            let entity = config { $0.crypto = .all }
            let crypto = Int32(SearchType.crypto.rawValue)
            let normal = Int32(SearchType.normal.rawValue)
            let type = entity.entityFilter.groupChatFilter.searchTypes.first ?? 0
            XCTAssertEqual(type | crypto, type)
            XCTAssertEqual(type | normal, type)
        }
        XCTContext.runActivity(named: "normal") { activity in
            let entity = config { $0.crypto = .normal }
            let value = Int32(SearchType.normal.rawValue)
            let type = entity.entityFilter.groupChatFilter.searchTypes.first ?? 0
            XCTAssertEqual(type | value, type)
        }
        XCTContext.runActivity(named: "normacryptol") { activity in
            let entity = config { $0.crypto = .crypto }
            let value = Int32(SearchType.crypto.rawValue)
            let type = entity.entityFilter.groupChatFilter.searchTypes.first ?? 0
            XCTAssertEqual(type | value, type)
        }
    }
    // MARK: - Field
    func testRelationTag() {
        let entity = config {
            $0.field = .init(relationTag: true)
        }
        XCTAssertTrue(entity.entitySelector.groupChatSelector.relationTag)
    }

    func testInTeam() {
        let id = UUID().uuidString
        let entity = config {
            $0.field = .init(directlyTeamIds: [id])
        }
        XCTAssertEqual(entity.entitySelector.groupChatSelector.isInTeamID, id)
    }
    // MARK: - Private
    private func config(transform: (inout Config) -> Void) -> Search_V2_BaseEntity.EntityItem {
        var config = PickerConfig.ChatEntityConfig()
        transform(&config)
        let entity = SearchEntityGenerator.getChatEntity(by: [config])
        return entity
    }
}
// swiftlint:enable all
