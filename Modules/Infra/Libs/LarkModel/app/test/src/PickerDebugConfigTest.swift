//
//  PickerDebugConfigTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/5/11.
//
// swiftlint:disable all
import XCTest
import LarkModel

final class PickerDebugConfigTest: XCTestCase {

    func testToJson() {
        let config = PickerDebugConfig(
            featureConfig: PickerFeatureConfig(
                multiSelection: .init(isOpen: true, selectedViewStyle: .iconList),
                navigationBar: .init(title: "", sureText: ""),
                searchBar: .init(placeholder: "")),
            searchConfig: PickerSearchConfig(entities: [
                PickerConfig.ChatterEntityConfig(talk: .all, resign: .all, field: .init()),
                PickerConfig.ChatEntityConfig(tenant: .inner, field: .init()),
                PickerConfig.UserGroupEntityConfig(),
                PickerConfig.DocEntityConfig(),
                PickerConfig.WikiEntityConfig(),
                PickerConfig.WikiSpaceEntityConfig()
            ], permission: []),
            disablePrefix: "",
            forceSelectPrefix: "")
        do {
            let data = try JSONEncoder().encode(config)
            let jsonString = String(data: data, encoding: .utf8)!
            XCTAssertFalse(jsonString.isEmpty)
        } catch {
            XCTFail()
        }
    }

//    func testToConfig() {
//        let str = """
//{\"disablePrefix\":\"\",\"featureConfig\":{\"navigationBar\":{\"title\":\"Picker\",\"sureText\":\"Select\"},\"searchBar\":{},\"scene\":\"unknown\",\"multiSelection\":{\"isOpen\":true,\"isDefaultMulti\":true,\"canSwitchToMulti\":true,\"canSwitchToSingle\":false,\"canSelectEmptyResult\":true,\"selectedViewStyle\":{\"value\":\"iconList\"},\"targetPreview\":{\"isOpen\":false}},\"forceSelectPrefix\":\"\",\"searchConfig\":{\"chatId\":null,\"entities\":{\"chats\":[],\"wikis\":[],\"docs\":[{\"fromIds\":[],\"useExtendedSearchV2\":false,\"sortType\":1,\"reviewTimeRange\":{\"value\":{\"key\":\"all\"}},\"enableExtendedSearch\":false,\"crossLanguage\":false,\"belongUser\":{\"value\":{\"key\":\"\",\"content\":\"\"}},\"type\":\"doc\",\"searchContentTypes\":[],\"folderTokens\":[],\"sharerIds\":[],\"types\":[],\"belongChat\":{\"value\":{\"key\":\"all\",\"content\":\"\"}}}],\"chatters\":[]},\"permissions\":[]},\"contactConfig\":{\"entries\":{\"ownedGroup\":[{}],\"organization\":[{}],\"external\":[{}],\"relatedOrganization\":[],\"emailContact\":[]}}}
//"""
//        do {
//            let data = str.data(using: .utf8)!
//            let config = try JSONDecoder().decode(PickerDebugConfig.self, from: data)
//            XCTAssertNotNil(config)
//        } catch {
//            XCTFail(error.localizedDescription)
//        }
//    }
}
// swiftlint:enable all
