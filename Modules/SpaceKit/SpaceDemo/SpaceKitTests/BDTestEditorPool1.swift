//
//  BDTestEditorPool1.swift
//  DocsTests
//
//  Created by guotenghu on 2019/5/28.
//  Copyright © 2019 Bytedance. All rights reserved.

import XCTest
@testable import SpaceKit
@testable import Docs
import Nimble
import Quick

class EditorPoolSpec: QuickSpec {
    private var editorPool: EditorsPool<ReusableTest>!
    private static var weakItems = [Weak<ReusableTest>]()
    private let user: User = {
        let user = User.current
        let userInfo = UserInfo(userID: "")
        User.current.info = userInfo
        userInfo.updateUser(info: ("65934242", "1", "00888"))
        return user
    }()
    private func reset() {
        EditorPoolSpec.weakItems = [Weak<ReusableTest>]()
        editorPool = EditorsPool<ReusableTest>(poolMaxCount: 1, maxUsedPerItem: 5, inUser: user) { () -> ReusableTest in
            let item = ReusableTest()
            EditorPoolSpec.weakItems.insert(Weak<ReusableTest>(item), at: 0)
            return item
        }
    }

    private func wait(_ seconds: Double) {
        waitUntil(timeout: seconds + 2) { (done) in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds, execute: {
                done()
            })
        }
    }

    private var docloaded: PreloadStatus {
        var status = PreloadStatus()
        status.addType("doc")
        return status
    }

    override func spec() {
        func testCanReclaim() {
            //预加载， 只有一个
            // 拿出去以后，池子里是空的
            // 回收以后，池子里又有一个了
            expect(self.editorPool.items.count).to(equal(1))

            self.editorPool.items.first?.preloadStatus = .init(self.docloaded)
            let item = self.editorPool.dequeueReuseableItem(for: .doc)
            expect(self.editorPool.items.isEmpty).to(beTrue())
            self.editorPool.reclaim(editor: item)
            expect(self.editorPool.items.count).to(equal(1))
        }
        describe("打开然后关闭") {
            beforeEach {
                self.reset()
                self.editorPool.preload()
                self.wait(1)
            }
            it("可以正常回收", closure: {
                testCanReclaim()
            })
        }
        describe("被 drain 以后，可以回收") {
            beforeEach {
                self.reset()
                self.editorPool.preload()
                self.wait(1)
            }
            it("drain以后，正常流程", closure: {
                testCanReclaim()
                self.editorPool.drain()
                self.editorPool.preload()
                self.wait(1)
                testCanReclaim()
            })
        }
        describe("遇到item被terminate") {
            beforeEach {
                self.reset()
                self.editorPool.preload()
                self.wait(1)
            }
            it("在外面的不能回收", closure: {
                expect(self.editorPool.items.count).to(equal(1))
                self.editorPool.items.first?.preloadStatus = .init(self.docloaded)
                let item = self.editorPool.dequeueReuseableItem(for: .doc)
                expect(self.editorPool.items.isEmpty).to(beTrue())
                item.webviewHasBeenTerminated.value = true
                self.editorPool.reclaim(editor: item)
                expect(self.editorPool.items.count).to(equal(0))
            })
            it("在pool里的，被termiante要及时清理", closure: {
                expect(self.editorPool.items.count).to(equal(1))
                autoreleasepool(invoking: { () -> Void in
                    let rawItem = self.editorPool.items.first!
                    rawItem.preloadStatus = .init(self.docloaded)
                    rawItem.webviewHasBeenTerminated.value = true
                })
                self.wait(1)
                // 有重新预加载好的一个
                expect(self.editorPool.items.count).to(equal(1))
                let newItem = self.editorPool.items.first!
                newItem.preloadStatus.value = self.docloaded
                //拿出来的，是重新预加载好的一个
                let item = self.editorPool.dequeueReuseableItem(for: .doc)
                item.preloadStatus.value = self.docloaded
                expect(newItem === item).to(beTrue())
                //被成功回收
                self.editorPool.reclaim(editor: item)
                expect(self.editorPool.items.count).to(equal(1))
                expect(EditorPoolSpec.weakItems.count).to(equal(2))
                expect(EditorPoolSpec.weakItems.filter({ $0.value != nil }).count).to(equal(1))
            })
        }
        describe("回收逻辑") {
            beforeEach {
                self.reset()
                self.editorPool.preload()
                self.wait(1)
            }
            it("使用次数到上限以后要拿一个新的", closure: {
                expect(self.editorPool.items.count).to(equal(1))
                let rawItem = self.editorPool.items.first!
                rawItem.preloadStatus = .init(self.docloaded)
                (0..<5).forEach({ (_) in
                    let item = self.editorPool.dequeueReuseableItem(for: .doc)
                    expect(item === rawItem).to(beTrue())
                    self.editorPool.reclaim(editor: item)
                })
                let item = self.editorPool.dequeueReuseableItem(for: .doc)
                expect(item === rawItem).to(beFalse())
            })
        }
    }
}

private class ReusableTest: DocReusableItem {
    var usedCounter: Int = 0

    var isInEditorPool: Bool = false

    var preloadStatus: ObserableWrapper<PreloadStatus> = .init(PreloadStatus())

    var webviewHasBeenTerminated: ObserableWrapper<Bool> = .init(false)

    var editorIdentity: String {
        return "\(ObjectIdentifier(self))"
    }

    var openSessionID: String?

    var reuseState: String {
        return  ["editor": "\(self.editorIdentity)",
            "mainFrameReady": self.preloadStatus.value,
            "webviewHasBeenTerminated": self.webviewHasBeenTerminated.value,
            "usedCounter": self.usedCounter].description
    }

    func canReuse(for type: DocsType) -> Bool {
        return preloadStatus.value.hasPreload(type) && !self.webviewHasBeenTerminated.value
    }

    func preload() -> Self {
        return self
    }

    var isHidden: Bool = false

    func addToViewHierarchy() -> Self {
        return self
    }

    func removeFromViewHierarchy() {

    }

    func loadFailView() {

    }
    
    func prepareForReuse() {

    }

    var preloadStartTimeStamp: TimeInterval = 0

    var preloadEndTimeStamp: TimeInterval = 0

    var webviewStartLoadUrlTimeStamp: TimeInterval = 0

    static func == (lhs: ReusableTest, rhs: ReusableTest) -> Bool {
        return lhs === rhs
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(editorIdentity)
    }
}
