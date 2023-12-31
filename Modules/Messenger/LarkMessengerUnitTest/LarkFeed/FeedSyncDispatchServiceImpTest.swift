//
//  FeedSyncDispatchServiceImpTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import LarkModel
import RxSwift
@testable import LarkFeed

class FeedSyncDispatchServiceImpTest: XCTestCase {
    var dispatchService: FeedSyncDispatchServiceImp!
    var mockDependency: MockFeedSyncDispatchServiceDependency!
    var disposeBag: DisposeBag!

    override func setUp() {
        mockDependency = MockFeedSyncDispatchServiceDependency()
        dispatchService = FeedSyncDispatchServiceImp(dependency: mockDependency)
        disposeBag = DisposeBag()
        super.setUp()
    }

    override func tearDown() {
        mockDependency = nil
        dispatchService = nil
        disposeBag = nil
        super.tearDown()
    }

    // MARK: - allShortcutChats

    /// case 1: 获取本地shortcut的Chat
    func test_allShortcutChats() {
        mockDependency.getLocalChatsBuilder = { ids -> [String: Chat] in
            let chat1 = buildChat()
            chat1.id = "1"
            let chat2 = buildChat()
            chat2.id = "2"
            let chat3 = buildChat()
            chat3.id = "3"
            let chat4 = buildChat()
            chat4.id = "4"
            return ["1": chat1,
                    "2": chat2,
                    "3": chat3,
                    "4": chat4]
        }
        let chats = dispatchService.allShortcutChats
        XCTAssert(chats.map({ $0.id }) == ["1", "2", "3"])
    }

    // MAKR: - topInboxChats

    /// case 1: 返回Chat按照rankTime降序排列
    func test_topInboxChats_1() {
        // 自定义返回值
        mockDependency.feedCellViewModelsBuilder = {
            let vm1 = self.buildCellViewModel(id: 1)
            let vm2 = self.buildCellViewModel(id: 2)
            let vm3 = self.buildCellViewModel(id: 3)
            let vm4 = self.buildCellViewModel(id: 4)
            return [vm1, vm2, vm3, vm4]
        }
        mockDependency.getLocalChatsBuilder = { ids -> [String: Chat] in
            let chat1 = buildChat()
            chat1.id = "1"
            let chat2 = buildChat()
            chat2.id = "2"
            let chat3 = buildChat()
            chat3.id = "3"
            let chat4 = buildChat()
            chat4.id = "4"
            return ["1": chat1,
                    "2": chat2,
                    "3": chat3,
                    "4": chat4]
        }

        let chats = dispatchService.topInboxChats(by: 10, chatType: nil, needChatBox: true)

        // 校验
        let chatIds = chats.map({ $0.id })
        XCTAssert(chatIds == ["4", "3", "2", "1"])
    }

    /// case 2: 返回小于等于count个数据
    func test_topInboxChats_2() {
        // 自定义返回值
        mockDependency.feedCellViewModelsBuilder = {
            let vm1 = self.buildCellViewModel(id: 1)
            let vm2 = self.buildCellViewModel(id: 2)
            let vm3 = self.buildCellViewModel(id: 3)
            let vm4 = self.buildCellViewModel(id: 4)
            return [vm1, vm2, vm3, vm4]
        }
        mockDependency.getLocalChatsBuilder = { ids -> [String: Chat] in
            let chat1 = buildChat()
            chat1.id = "1"
            let chat2 = buildChat()
            chat2.id = "2"
            let chat3 = buildChat()
            chat3.id = "3"
            let chat4 = buildChat()
            chat4.id = "4"
            return ["1": chat1,
                    "2": chat2,
                    "3": chat3,
                    "4": chat4]
        }

        // 数量足够时，返回前count个
        let chats1 = dispatchService.topInboxChats(by: 2, chatType: nil, needChatBox: true)
        let chatIds1 = chats1.map({ $0.id })
        XCTAssert(chatIds1 == ["4", "3"])

        // 数量不足时，返回所有
        let chats2 = dispatchService.topInboxChats(by: 5, chatType: nil, needChatBox: true)
        let chatIds2 = chats2.map({ $0.id })
        XCTAssert(chatIds2 == ["4", "3", "2", "1"])
    }

    /// case 3: needChatBox = false -> 过滤消息盒子数据
    func test_topInboxChats_3() {
        // 自定义返回值
        mockDependency.feedCellViewModelsBuilder = {
            let vm1 = self.buildCellViewModel(id: 1)
            let vm2 = self.buildCellViewModel(id: 2)
            let vm3 = self.buildCellViewModel(id: 3)
            let vm4 = self.buildCellViewModel(id: 4)
            let vm5 = self.buildCellViewModel(id: 5)
            vm5.feedCardPreview.type = .box
            return [vm1, vm2, vm3, vm4, vm5]
        }
        mockDependency.getLocalChatsBuilder = { ids -> [String: Chat] in
            let chat1 = buildChat()
            chat1.id = "1"
            let chat2 = buildChat()
            chat2.id = "2"
            let chat3 = buildChat()
            chat3.id = "3"
            let chat4 = buildChat()
            chat4.id = "4"
            let chat5 = buildChat()
            chat5.id = "5"
            return ["1": chat1,
                    "2": chat2,
                    "3": chat3,
                    "4": chat4,
                    "5": chat5]
        }

        let chats = dispatchService.topInboxChats(by: 10, chatType: nil, needChatBox: false)
        let chatIds = chats.map({ $0.id })
        XCTAssert(chatIds == ["4", "3", "2", "1"])
    }

    /// case 4: 只返回chat类型和非密聊类型
    func test_topInboxChats_4() {
        // 自定义返回值
        mockDependency.feedCellViewModelsBuilder = {
            let vm1 = self.buildCellViewModel(id: 1)
            let vm2 = self.buildCellViewModel(id: 2)
            let vm3 = self.buildCellViewModel(id: 3)
            let vm4 = self.buildCellViewModel(id: 4)
            vm4.feedCardPreview.isCrypto = true // 密聊类型，被过滤
            let vm5 = self.buildCellViewModel(id: 5)
            vm5.feedCardPreview.type = .docFeed // doc类型，被过滤
            return [vm1, vm2, vm3, vm4, vm5]
        }
        mockDependency.getLocalChatsBuilder = { ids -> [String: Chat] in
            let chat1 = buildChat()
            chat1.id = "1"
            let chat2 = buildChat()
            chat2.id = "2"
            let chat3 = buildChat()
            chat3.id = "3"
            let chat4 = buildChat()
            chat4.id = "4"
            let chat5 = buildChat()
            chat5.id = "5"
            return ["1": chat1,
                    "2": chat2,
                    "3": chat3,
                    "4": chat4,
                    "5": chat5]
        }

        let chats = dispatchService.topInboxChats(by: 10, chatType: nil, needChatBox: false)
        let chatIds = chats.map({ $0.id })
        XCTAssert(chatIds == ["3", "2", "1"])
    }

    /// case 5: 根据传入chatType返回指定类型chatType
    func test_topInboxChats_5() {
        // 自定义返回值
        mockDependency.feedCellViewModelsBuilder = {
            let vm1 = self.buildCellViewModel(id: 1)
            vm1.feedCardPreview.chatMode = .default
            let vm2 = self.buildCellViewModel(id: 2)
            vm2.feedCardPreview.chatMode = .thread
            let vm3 = self.buildCellViewModel(id: 3)
            vm3.feedCardPreview.chatMode = .unknown
            return [vm1, vm2, vm3]
        }
        mockDependency.getLocalChatsBuilder = { ids -> [String: Chat] in
            let chat1 = buildChat()
            chat1.id = "1"
            let chat2 = buildChat()
            chat2.id = "2"
            let chat3 = buildChat()
            chat3.id = "3"
            let chat4 = buildChat()
            chat4.id = "4"
            let chat5 = buildChat()
            chat5.id = "5"
            return ["1": chat1,
                    "2": chat2,
                    "3": chat3,
                    "4": chat4,
                    "5": chat5]
        }

        let chats = dispatchService.topInboxChats(by: 10, chatType: [.default, .thread], needChatBox: false)
        let chatIds = chats.map({ $0.id })
        XCTAssert(chatIds == ["2", "1"])
    }

    /// 内部特化使用
    private func buildCellViewModel(id: Int) -> BaseFeedTableCellViewModel {
        var feed = buildFeedPreview()
        feed.type = .chat
        feed.feedType = .inbox
        feed.isCrypto = false
        feed.id = "\(id)"
        feed.rankTime = id
        return BaseFeedTableCellViewModel(feedCardPreview: feed, bizType: .inbox)!
    }

    // MARK: - topInboxData

    /// case 1: 获取chat和thread类型的信息（包括Chat和Message）
    func test_topInboxData_1() {
        // 自定义返回值
        mockDependency.feedCellViewModelsBuilder = {
            let vm1 = self.buildCellViewModel(id: 1)
            let vm2 = self.buildCellViewModel(id: 2)
            let vm3 = self.buildCellViewModel(id: 3)
            let vm4 = self.buildCellViewModel(id: 4)
            vm4.feedCardPreview.type = .thread
            let vm5 = self.buildCellViewModel(id: 5)
            vm5.feedCardPreview.type = .thread
            return [vm1, vm2, vm3, vm4, vm5]
        }
        mockDependency.fetchMessagesMapBuilder = { ids, needTryLocal -> Observable<[String: Message]> in
            // 参数校验
            XCTAssert(ids == ["5", "4"])
            XCTAssert(needTryLocal == false)

            let msg1 = buildMessage()
            msg1.channel.id = "5"
            let msg2 = buildMessage()
            msg2.channel.id = "4"

            return .just(["5": msg1, "4": msg2])
        }
        mockDependency.fetchChatsBuilder = { ids, forceRemote -> Observable<[String: Chat]> in
            // 参数校验
            XCTAssert(ids.count == 5)
            XCTAssert(forceRemote == false)

            var chats = [String: Chat]()
            ids.forEach { id in
                let chat = buildChat()
                chat.id = id
                chats[id] = chat
            }
            return .just(chats)
        }

        dispatchService.topInboxData(by: 10).subscribe(onNext: { forwardMsgs in
            let ids = forwardMsgs.map({ $0.0.id })
            // 按照rankTime降序排列
            XCTAssert(ids == ["5", "4", "3", "2", "1"])
            // chat类型的Message为nil
            XCTAssert(forwardMsgs[2].message == nil)
            XCTAssert(forwardMsgs[3].message == nil)
            XCTAssert(forwardMsgs[4].message == nil)
            // thread类型Message非nil
            XCTAssert(forwardMsgs[0].message != nil)
            XCTAssert(forwardMsgs[1].message != nil)
        }).disposed(by: disposeBag)

        mainWait()
    }

    // MARK: - currentAllStaffChatId

    /// case 1: 返回第一个tenantChat = true的feedId
    func test_currentAllStaffChatId() {
        mockDependency.feedCellViewModelsBuilder = {
            let vm1 = self.buildCellViewModel(id: 1)
            let vm2 = self.buildCellViewModel(id: 2)
            vm2.feedCardPreview.tenantChat = true
            let vm3 = self.buildCellViewModel(id: 3)
            let vm4 = self.buildCellViewModel(id: 4)
            return [vm1, vm2, vm3, vm4]
        }

        let id = dispatchService.currentAllStaffChatId()

        XCTAssert(id == "2")
    }
}
