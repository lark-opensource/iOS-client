//
//  WikiContainerViewModelTests.swift
//  SKWikiV2_Tests
//
//  Created by majie.7 on 2022/7/12.
//
@testable import SKWikiV2
@testable import SKWorkspace
import Foundation
import XCTest
import RxSwift
import SKFoundation
import SKSpace
import SpaceInterface
import LarkContainer


class WikiContainerViewModelTests: XCTestCase {
    let bag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        SpaceModule.init().setup()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }
    
    private func createViewModel() -> WikiContainerViewModel {
        let wikiNode = WikiNodeMeta(wikiToken: "wikitoken", objToken: "objtoken", docsType: .docX, spaceID: "123")
        
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let vm = WikiContainerViewModel(userResolver: userResolver, wikiNode: wikiNode, treeContext: nil, params: nil, extraInfo: [:])
        return vm
    }
    
    func testHandleSuccess() {
        let vm = createViewModel()
        let params: [String: Any] = ["wiki_info": ["code": 0]]
        vm.handle(event: .setWikiInfo, params: params)
        vm.output.viewStateEvent.drive(onNext: { state in
            switch state {
            case .success:
                XCTAssertTrue(true)
            default:
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
    }
    
    func testHandleTitleChange() {
        let vm = createViewModel()
        let newWikiName = "new_name"
        let params: [String: Any] = ["wikiToken": "wikitoken", "newName": newWikiName]
        let expect = expectation(description: "test wiki title notification")
        expect.expectedFulfillmentCount = 1
        NotificationCenter.default
            .rx
            .notification(Notification.Name.Docs.wikiTitleUpdated)
            .subscribe(onNext: { notification in
                guard let userInfo = notification.userInfo,
                      let newName = userInfo["newName"] as? String else {
                    print("wiki container test: title change failed")
                    XCTAssertTrue(false)
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(newName, newWikiName)
                print("wiki container test: title change success")
                expect.fulfill()
            })
            .disposed(by: bag)
        vm.handle(event: .titleChanged, params: params)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
}
