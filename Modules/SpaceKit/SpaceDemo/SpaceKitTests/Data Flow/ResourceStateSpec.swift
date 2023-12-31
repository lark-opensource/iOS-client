//
//  ResourceStateSpec.swift
//  DocsTests
//
//  Created by guotenghu on 2019/7/14.
//  Copyright © 2019 Bytedance. All rights reserved.
// 测试数据流逻辑

import Foundation
import Quick
import Nimble
@testable import SpaceKit
import SwiftyBeaver

private let testStore = SpaceStore(reducer: FileResource.fileResourceReducer, state: ResourceState())

class ResourceStateSpec: DocsSpec {
    override func spec() {
        self.testChangePin()
        //其他Action 加在这里
    }

    private func expectOnQueue() {
        dispatchPrecondition(condition: .onQueue(reSwiftQueue))
    }
}

// UpdatePinAction
extension ResourceStateSpec {
    private func testChangePin() {
        testLog.info("\(#line)")

        testLog.info("\(#line)")
        it("pin一个文档") {
            testLog.info("\(#line)")
            waitUntil(timeout: 2) { (done) in
                DispatchQueue.dataQueueAsyn {

                    testStore.dispatch(LoadNewDBDataAction(dbData: self.getDBData1(), feedData: []))
                    done()
                }

            }
            testLog.info("\(#line)")

            testLog.info("\(#function) init")

            testLog.info("\(#line)")

            //check before
            let preFileEntry = testStore.state.allFileEntries["objtoken1"]!
            expect(preFileEntry.isPined).notTo(beTrue())
            testLog.info("\(#line)")
            waitUntil(timeout: 2) { (done) in
                DispatchQueue.dataQueueAsyn {

                    testStore.dispatch(UpdatePinAction(objToken: "objtoken1", isPined: true))
                    done()
                }
            }
            testLog.info("\(#line)")

            let postFileEntry = testStore.state.allFileEntries["objtoken1"]!
            expect(postFileEntry.isPined).to(beTrue())
        }
    }

    private func getDBData1() -> DBData {
        var dbData = DBData()
        let fileEntry1 = SpaceEntry(type: .doc, nodeToken: "nodeToken1", objToken: "objtoken1")
        dbData.fileEntry = [fileEntry1]
        dbData.nodeTokensMap = [:]
        dbData.nodeToObjTokenMap = ["nodeToken1": "objtoken1"]
        return dbData
    }
}
