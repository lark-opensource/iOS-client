//
//  BTChatterPanelViewModelTest.swift
//  SKBitable-Unit-Tests
//
//  Created by X-MAN on 2023/2/3.
//

import Foundation
@testable import SKFoundation
import XCTest
@testable import SKBrowser
import RxRelay
import SKCommon
import SwiftyJSON
import OHHTTPStubs

class BTChatterPanelViewModelTest: XCTestCase {
    
    var viewModel: BTChatterPanelViewModel?
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        let docInfo = DocsInfo(type: .bitable, objToken: "testBitableToken")
        viewModel = BTChatterPanelViewModel(docInfo, chatId: "chatId",
                                            openSource: .record(chatterType: .group),
                                            lastSelectNotifies: false,
                                            chatterType: .group)
        stub { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains("/api/mention/recommend.v2/")
            return contain
        } response: { _ in
            let response = HTTPStubsResponse(jsonObject:
                                                ["code": 0,
                                                "data": [
                                                    "entities": [
                                                        "chats": [],
                                                        "groups": [
                                                            "6938327275343446035": [
                                                                "avatar_url": "",
                                                                "desc": "",
                                                                "id": "6938327275343446035",
                                                                "is_chat_share_able": "",
                                                                "is_cross_tenant": false,
                                                                "name": "测试测试公开测试",
                                                                "owner": "",
                                                                "type": 6
                                                            ],
                                                            "6959537443225731092": [
                                                                "avatar_url": "",
                                                                "desc": "",
                                                                "id": "6959537443225731092",
                                                                "is_chat_share_able": "",
                                                                "is_cross_tenant": false,
                                                                "name": "测试测试测试",
                                                                "owner": "",
                                                                "type": 6
                                                            ],
                                                        ],
                                                        "notes": [],
                                                        "users": []
                                                    ],
                                                    "result_list": [["token": "6938327275343446035",
                                                                     "type": 6
                                                                    ], ["token": "6959537443225731092",
                                                                        "type": 6]],
                                                    "uuid": "51fa83f009c02075269be2fe8aff677e9b31e07d"
                                                ],
                                                "msg": "Success"
                                            ],
                                                     statusCode: 200,
                                                     headers: ["Content-Type": "application/json"])
            return response
        }

    }
    func testUpdateSelected() {
        let model = BTCapsuleModel(id: "id",
                                   text: "xxx",
                                   color: BTColorModel(),
                                   isSelected: true,
                                   font: .systemFont(ofSize: 14),
                                   token: "",
                                   avatarUrl: "",
                                   userID: "id",
                                   name: "name",
                                   enName: "name",
                                   displayName: nil,
                                   chatterType: .group)
        viewModel?.updateSelected([model])
        XCTAssert(viewModel?.selectedData.value.isEmpty != nil)
    }
    
    func testDeselected() {
        let model = BTCapsuleModel(id: "id",
                                   text: "xxx",
                                   color: BTColorModel(),
                                   isSelected: true,
                                   font: .systemFont(ofSize: 14),
                                   token: "",
                                   avatarUrl: "",
                                   userID: "id",
                                   name: "name",
                                   enName: "name",
                                   displayName: nil,
                                   chatterType: .group)
        viewModel?.updateSelected([model])
        viewModel?.deselect(at: 0)
        XCTAssert(viewModel?.selectedData.value.isEmpty ?? true)
    }
    
    func testChangeSelect() {
        let model = BTCapsuleModel(id: "id",
                                   text: "xxx",
                                   color: BTColorModel(),
                                   isSelected: true,
                                   font: .systemFont(ofSize: 14),
                                   token: "",
                                   avatarUrl: "",
                                   userID: "id",
                                   name: "name",
                                   enName: "name",
                                   displayName: nil,
                                   chatterType: .group)
        viewModel?.updateSelected([model])
        viewModel?.changeSelectStatus(at: 0, token: nil)
        XCTAssert(viewModel?.selectedData.value.isEmpty ?? false)
    }
    
    func testChangeSelectMore() {
        let model = BTCapsuleModel(id: "id",
                                   text: "xxx",
                                   color: BTColorModel(),
                                   isSelected: true,
                                   font: .systemFont(ofSize: 14),
                                   token: "",
                                   avatarUrl: "",
                                   userID: "id",
                                   name: "name",
                                   enName: "name",
                                   displayName: nil,
                                   chatterType: .group)
        viewModel?.updateSelected([model])
        let recommond = RecommendData(withToken: "xxx", keyword: "new", type: .group, infos: JSON(dictionary: [:])!)
        viewModel?.recommendData.accept( [recommond])
        viewModel?.changeSelectStatus(at: 0, token: nil)
        XCTAssert(viewModel?.selectedData.value.first?.id == "xxx")
    }
    
    func testSearch() {
        viewModel?.searchText.accept("new")
    }
    
    func testNotifyModel() {
        let mode = viewModel?.notifyMode
        XCTAssert(mode != nil)
    }
    
    func testNotify() {
        let enable = viewModel?.notifyMode.notifiesEnabled
        XCTAssert(enable == false)
    }
}
