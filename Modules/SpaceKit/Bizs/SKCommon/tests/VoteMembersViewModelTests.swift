//
//  VoteMembersViewModelTests.swift
//  SKCommon_Tests
//
//  Created by zhysan on 2022/9/16.
//

import XCTest
import OHHTTPStubs
@testable import SKCommon
import SKFoundation
import SKInfra

private enum MockPageId: String {
    case requestError = "mock_pageId_request_error"
    case decodeError = "mock_pageId_decode_error"
    case normal = "mock_pageId_normal"
}

class VoteMembersViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()

        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.pollOptionData)
            return contain
        }, response: { request in
            guard let str = request.url?.absoluteString,
                  let cmp = URLComponents(string: str),
                  let pageIdStr = cmp.queryItems?.first(where: { $0.name == "page_id" })?.value,
                  let pageId = MockPageId(rawValue: pageIdStr),
                  let offset = cmp.queryItems?.first(where: { $0.name == "offset" })?.value else {
                let error = VoteMemberError.inner("invalid param")
                return HTTPStubsResponse(error: error)
            }
            switch pageId {
            case .requestError:
                return HTTPStubsResponse(jsonObject: [:], statusCode: 404, headers: nil)
            case .decodeError:
                return HTTPStubsResponse(
                    fileAtPath: OHPathForFile("PollDataError1.json", type(of: self))!,
                    statusCode: 200,
                    headers: ["Content-Type": "application/json"]
                )
            case .normal:
                if offset == "1" {
                    return HTTPStubsResponse(
                        fileAtPath: OHPathForFile("PollData1.json", type(of: self))!,
                        statusCode: 200,
                        headers: ["Content-Type": "application/json"]
                    )
                } else if offset == "2" {
                    return HTTPStubsResponse(
                        fileAtPath: OHPathForFile("PollData2.json", type(of: self))!,
                        statusCode: 200,
                        headers: ["Content-Type": "application/json"]
                    )
                } else {
                    return HTTPStubsResponse(
                        fileAtPath: OHPathForFile("PollData3.json", type(of: self))!,
                        statusCode: 200,
                        headers: ["Content-Type": "application/json"]
                    )
                }
            }
        })
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
        super.tearDown()
    }

    func testVoteMembersRequestError() {
        let context = DocVote.OptionContext(
            pageId: MockPageId.requestError.rawValue,
            blockId: "doxbcK6gmCsAWqUW85ni6hMCaOs",
            optionId: "5e8c342f-9de3-4663-addb-4880d85ac956",
            voteCount: 10,
            offset: "1",
            isVoteDesc: true
        )
        let vm = VoteMembersViewModel(optionContext: context)
        let expect1 = expectation(description: "testVoteMembers")
        vm.updateVoteMembers { error in
            if case .request = error {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
            expect1.fulfill()
        }
        waitForExpectations(timeout: 20) { error in
            XCTAssertNil(error)
        }
    }
    
    func testVoteMembersDecodeError() {
        let context = DocVote.OptionContext(
            pageId: MockPageId.decodeError.rawValue,
            blockId: "doxbcK6gmCsAWqUW85ni6hMCaOs",
            optionId: "5e8c342f-9de3-4663-addb-4880d85ac956",
            voteCount: 10,
            offset: "1",
            isVoteDesc: true
        )
        let vm = VoteMembersViewModel(optionContext: context)
        let expect1 = expectation(description: "testVoteMembers")
        vm.updateVoteMembers { error in
            if case .decode = error {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
            expect1.fulfill()
        }
        waitForExpectations(timeout: 20) { error in
            XCTAssertNil(error)
        }
    }
    
    func testVoteMembersNormal() {
        let context = DocVote.OptionContext(
            pageId: MockPageId.normal.rawValue,
            blockId: "doxbcK6gmCsAWqUW85ni6hMCaOs",
            optionId: "5e8c342f-9de3-4663-addb-4880d85ac956",
            voteCount: 10,
            offset: "1",
            isVoteDesc: true
        )
        let vm = VoteMembersViewModel(optionContext: context)
        let expect1 = expectation(description: "testVoteMembers1")
        vm.updateVoteMembers { error in
            XCTAssertNil(error)
            XCTAssertTrue(vm.members.count == 5)
            expect1.fulfill()
        }
        waitForExpectations(timeout: 20) { error in
            XCTAssertNil(error)
        }
        
        let expect2 = expectation(description: "testVoteMembers2")
        vm.updateVoteMembers { error in
            XCTAssertNil(error)
            XCTAssertTrue(vm.members.count == 10)
            expect2.fulfill()
        }
        waitForExpectations(timeout: 20) { error in
            XCTAssertNil(error)
        }
        
        let expect3 = expectation(description: "testVoteMembers3")
        vm.updateVoteMembers { error in
            if case .noMore = error {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
            expect3.fulfill()
        }
        waitForExpectations(timeout: 20) { error in
            XCTAssertNil(error)
        }
    }
}
