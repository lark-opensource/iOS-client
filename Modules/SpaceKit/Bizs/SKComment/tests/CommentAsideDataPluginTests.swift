//
//  CommentAsideDataPluginTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/8/25.
//  


@testable import SKCommon
@testable import SKComment
import XCTest
import RxSwift
import RxCocoa
@testable import SKFoundation
import SpaceInterface


typealias DataPrepareClosure = (([String: Any]) -> [String: Any])

protocol TestCommentDataSource {
    var testScheduler: CommentSchedulerServer? { get }
}

extension TestCommentDataSource {
    func loadList() -> [String: Any] {
        // 带Feed来源的有激活评论信息的评论数据
        // cur_comment_id: 7143058997388558340, cur_reply_id: 7156806659918807041
        // page位置：(section: 87, row: 4)
        guard let path = Bundle(for: CommentAsideDataPluginTests.self).path(forResource: "comment_data", ofType: "plist"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
               return [:]
        }
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return [:]
        }
        return plist
    }
    
    /// 构造删除当前的评论
    func deleteComment(params: [String: Any], commentId: String? = nil) -> [String: Any] {
        let curId = commentId ?? "7143058997388558340"
        var newParams = params
        guard let cards = newParams["cards"] as? [[String: Any]] else {
            XCTFail("cards data is nil")
            return params
        }
        
       let newCards = cards.filter { dict in
            let id = (dict["commentId"] as? String) ?? ""
            return id != curId
       }
        newParams["cards"] = newCards
        return newParams
    }
    
    
    /// 只保存range范围内的评论
    func keepRangeComment(params: [String: Any], range: Range<Int>) -> [String: Any] {
        var newParams = params
        guard let cards = newParams["cards"] as? [[String: Any]] else {
            XCTFail("cards data is nil")
            return params
        }
        let newCards = Array(cards[range])
        newParams["cards"] = newCards
        return newParams
    }
    
    var testDocsInfo: DocsInfo {
        let docsInfo = DocsInfo(type: .docX, objToken: "NWbsdIn9cok3Lzxws8ickr7Nn9f")
        docsInfo.commentUser = try? CommentUser(params: ["user": ["id": "123"]])
        return docsInfo
    }
    
    
    /// 返回mock数据
    /// - Parameter permission: 指定后会根据自定义权限返回带有改权限信息的mock评论数据
    /// - Parameter prepare: 修改默认mock数据
    /// - Returns: 评论模型
    func testComment(permission: CommentPermission? = nil, prepare: DataPrepareClosure? = nil) -> CommentData? {
        var dataParams = loadList()
        if let callback = prepare {
            dataParams = callback(dataParams)
        }
        if let permission = permission,
           var permissionMap = dataParams["permission"] as? [String: Any] {
            permissionMap.removeAll()
            if permission.contains(.canCopy) {
                permissionMap["copy"] = true
            }
            if permission.contains(.canNotDelete) {
                permissionMap["delete"] = true
            }
            if permission.contains(.canComment) {
                permissionMap["comment"] = true
            }
            if permission.contains(.canShowMore) {
                permissionMap["show_more"] = true
            }
            if permission.contains(.canResolve) {
                permissionMap["resolve"] = true
            }
            dataParams["permission"] = permissionMap
        }
        return CommentConstructor.constructCommentData(dataParams, docsInfo: testDocsInfo, chatID: "-")
    }
    
    @discardableResult
    func initData() -> CommentData {
        guard let data = testComment() else {
            XCTFail("data is invalid")
            return CommentData.init(comments: [],
                                    currentPage: 0,
                                    style: .normal,
                                    docsInfo: testDocsInfo,
                                    commentType: .card,
                                    commentPermission: [])
        }
        testScheduler?.dispatch(action: .updateData(data))
        return data
    }
}


class CommentAsideDataPluginTests: XCTestCase, TestCommentDataSource {

    var disposeBag = DisposeBag()
    
    var testScheduler: CommentSchedulerServer?
    
    var states: [CommentState] = []
    
    var testTableView = CustomTableView()

    var testAPIPlugin = TestAPIPlugin()

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        let scheduler = CommentSchedulerServer()
        let plugin = CommentAsideDataPlugin()
        scheduler.connect(plugins: [plugin, testAPIPlugin, CommentAsideInteractionPlugin()])
        scheduler.apply(context: self)
        self.testScheduler = scheduler
        
        testScheduler?.state.skip(1).subscribe(onNext: { [weak self] (state) in
            self?.states.append(state)
        }).disposed(by: disposeBag)
    }

    override func tearDown() {
        super.tearDown()
        disposeBag = DisposeBag()
        self.scheduler?.plugin(with: CommentAsideDataPlugin.self)?.commentSections = []
        states.removeAll()
        AssertionConfigForTest.reset()
    }

    
    // 正常对齐
    func testAlign() {
        let commentData = testComment()
        XCTAssertNotNil(commentData)
        guard let data = commentData else {
            return
        }
        testScheduler?.dispatch(action: .updateData(data))
        let expect1 = expectation(description: "loading")
        let expect2 = expectation(description: "updateDocsInfo")
        let expect3 = expectation(description: "updatePermission")
        let expect4 = expectation(description: "locateReference")
        let expect5 = expectation(description: "syncData")
        let expect6 = expectation(description: "reload")
        let expect7 = expectation(description: "align")
        for state in states {
            switch state {
            case .loading:
                expect1.fulfill()
            case .updateDocsInfo:
                expect2.fulfill()
            case .updatePermission:
                expect3.fulfill()
            case .locateReference:
                expect4.fulfill()
            case let .syncData(commentSections):
                // 确保都有header和footer
                XCTAssertTrue(commentSections.first?.items.first?.uiType == .header)
                XCTAssertTrue(commentSections.first?.items.last?.uiType == .footer)
                expect5.fulfill()
            case .reload:
                expect6.fulfill()
            case let .align(index, position):
                XCTAssertTrue(index.section == 87)
                let pos = position ?? 0
                XCTAssertEqual(Int(pos), 400)
                expect7.fulfill()
            default:
                break
            }
        }
        wait(for: [expect1, expect2, expect3, expect4, expect5, expect6, expect7], timeout: 5, enforceOrder: false)
        states.removeAll()
        
    }
    
    func testEditDiff() {
        let commentData = testComment()
        XCTAssertNotNil(commentData)
        guard let data = commentData else {
            return
        }
        
        var states: [CommentState] = []
        testScheduler?.state.skip(1).subscribe(onNext: { (state) in
            states.append(state)
        }).disposed(by: disposeBag)
        scheduler?.dispatch(action: .updateData(data))
        // 设置键盘激活
        scheduler?.dispatch(action: .ipc(.setReplyMode(commentId: nil, becomeResponser: true), nil))
        states.removeAll()
        
        
        // 构造协同数据
        
        guard let data2 = testComment() else {
            XCTFail("data is nil")
            return
        }
        let commentId = data2.currentCommentID ?? ""

        // 删除第一条评论，构造协同数据
        data2.comments.first?.commentList.removeFirst()
        data2.currentCommentPos = nil
        data2.currentReplyID = nil
        testScheduler?.dispatch(action: .updateData(data2))
        var containBatchUpdatesCompletion = false
        var containKeepInputVisiable = false
        for state in states {
            if case .batchUpdatesCompletion = state { // 间接表示走到了diff
                containBatchUpdatesCompletion = true
            }
            if case .reload = state {
                // 不应该有reload
                XCTAssertTrue(false)
            }
            // 确保有保持位置逻辑
            if case .keepInputVisiable = state {
                containKeepInputVisiable = true
            }
        }
        XCTAssertTrue(containBatchUpdatesCompletion)
        XCTAssertTrue(containKeepInputVisiable)

        // 确保键盘没有失去焦点
        let action = CommentAction.ipc(.fetchSnapshoot, { (result, error) in
            guard let snapshoot = result as? CommentSnapshootType else {
                XCTAssertTrue(false)
                return
            }
            XCTAssertNil(error)
            XCTAssertEqual(snapshoot.commentId, commentId)
            XCTAssertEqual(snapshoot.isAcivte, true)
            XCTAssertEqual(snapshoot.viewStatus.isFirstResponser, true)
        })
        scheduler?.dispatch(action: action)
        
        
    }
    
    typealias DataQueue = CommentUpdateDataQueue

    func testDataQueue() {
        let queue = DataQueue<CommentAction>()
        guard let commentData = testComment() else {
            XCTFail("commentData is nil")
            return
        }
        let expect = expectation(description: "test comment data queue")
        
        var count = 0
        queue.actionClosure = { node in
            if count <= 1 {
                count += 1
                node.markFulfill()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
                    count += 1
                    node.markFulfill()
                }
            }
        }

        queue.appendAction(CommentAction.updateData(commentData))
        queue.appendAction(CommentAction.updateData(commentData))
       
        // 没任务排队 会立即处理
        XCTAssertEqual(count, 2)
       
        queue.appendAction(CommentAction.updateData(commentData))
        queue.appendAction(CommentAction.updateData(commentData))
        queue.appendAction(CommentAction.updateData(commentData))
       
        // 繁忙时，会进入队列排队中
        XCTAssertEqual(count, 2)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            // 保证任务都会触发
            XCTAssertEqual(count, 5)
            // 确保队列清空
            XCTAssertTrue(queue.nodes.isEmpty)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }
    
    func testResetActive() {
        initData()
        scheduler?.dispatch(action: .resetActive)
        if let plugin = scheduler?.plugin(with: CommentAsideDataPlugin.self) {
            plugin.commentSections.forEach { section in
                XCTAssertFalse(section.model.isActive)
                section.model.commentList.forEach {
                    if case .normal = $0.viewStatus {
                        XCTAssertTrue(true)
                    } else {
                        XCTFail("testResetActive viewStatus error")
                    }
                 }
            }
        } else {
            XCTFail("testResetActive plugin error")
        }
    }
    
    class TestAPIPlugin: CommentPluginType {
        weak var context: CommentServiceContext?

        static let identifier = "TestAPIPlugin"
        
        var commentId: String?
        
        func apply(context: CommentServiceContext) {
            self.context = context
        }
        
        func mutate(action: CommentAction) {
            switch action {
            case let .api(apiAction, _):
                handleAPIAction(action: apiAction)
            default:
                break
            }
        }
        
        func handleAPIAction(action: CommentAction.API) {
            switch action {
            case let .switchCard(commentId, _):
                self.commentId = commentId
            default:
                break
            }
        }
    }

    func testTapBlank() {
        scheduler?.dispatch(action: .interaction(.tapBlank))
        XCTAssertEqual(testAPIPlugin.commentId, "")
    }
}


extension CommentAsideDataPluginTests: CommentServiceContext {
    var businessDependency: DocsCommentDependency? {
        return nil
    }
    
    var topMost: UIViewController? {
        return nil
    }
    
    var commentPluginView: UIView {
        return UIView()
    }
    
    var pattern: CommentModulePattern {
        .aside
    }
    
    
    var docsInfo: DocsInfo? {
        testDocsInfo
    }
    
    var scheduler: CommentSchedulerType? {
        testScheduler
    }
    
    var tableView: UITableView? { CustomTableView() }
    
    var vcToolbarHeight: CGFloat { 0 }
}

class CustomTableView: UITableView {
    
    override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        completion?(true)
    }
}
