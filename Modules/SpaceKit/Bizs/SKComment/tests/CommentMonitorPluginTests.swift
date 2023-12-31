//
//  CommentMonitorPluginTests.swift
//  SKCommon-Unit-Tests
//
//  Created by huayufan on 2023/3/6.
//  


@testable import SKCommon
@testable import SKUIKit
@testable import SKComment
import XCTest
import RxSwift
import RxCocoa
@testable import SKFoundation
@testable import SpaceInterface


class CommentMonitorPluginTests: XCTestCase, TestCommentDataSource {

    
    var disposeBag = DisposeBag()
    
    var testScheduler: CommentSchedulerServer?
    
    var states: [CommentState] = []
    
    var pattern: CommentModulePattern = .float

    lazy var monitorPlugin: CommentMonitorPlugin = {
        return CommentMonitorPlugin()
    }()
    
    lazy var testPlugin: TestPlugin = {
        return TestPlugin()
    }()
    
    
    override func setUp() {
        super.setUp()
        
        let scheduler = CommentSchedulerServer()
        
        scheduler.connect(plugins: [CommentFloatDataPlugin(),
                                    monitorPlugin,
                                    CommentFloatInteractionPlugin(),
                                    CommentDraftPlugin(),
                                    testPlugin])
        scheduler.apply(context: self)
        self.testScheduler = scheduler
        testScheduler?.state.skip(1).subscribe(onNext: { [weak self] (state) in
            self?.states.append(state)
        }).disposed(by: disposeBag)
    }

    override func tearDown() {
        super.tearDown()
        disposeBag = DisposeBag()
        self.scheduler?.plugin(with: CommentFloatDataPlugin.self)?.commentSections = []
        states.removeAll()
        pattern = .float
        
        testPlugin.editPerformanceRecord = false
        testPlugin.renderPerformanceRecord = false
        testPlugin.fpsPerformanceRecord = false
    }
    
    class TestPlugin: CommentPluginType {
        weak var context: CommentServiceContext?
        
        static let identifier: String = "TestPlugin"

        func apply(context: CommentServiceContext) {
            self.context = context
        }
        
        func mutate(action: CommentAction) {
            switch action {
            case let .tea(event):
                handleUIAction(event: event)
            default:
                break
            }
        }
        
        var fpsPerformanceRecord = false
        var renderPerformanceRecord  = false
        var editPerformanceRecord = false

        func handleUIAction(event: CommentAction.Tea) {
            switch event {
            case .fpsPerformance:
                fpsPerformanceRecord = true
            case .renderPerformance:
                renderPerformanceRecord = true
            case .editPerformance:
                editPerformanceRecord = true
            default:
                break
            }
        }
    }

    func testStoreImage() {
        let commentData = initData()
        let noImageItem = commentData.comments[1].commentList[1]
        let imageItem1 = commentData.comments[3].commentList[3] // 9
        let imageItem2 = commentData.comments[23].commentList[1] // 1
        let plugin = CommentMonitorPlugin()
        
        plugin.storeImageCount([noImageItem], isMonitoring: true)
        XCTAssertEqual(plugin.calculateImage(), 0)
        
        plugin.storeImageCount([imageItem1], isMonitoring: true)
        XCTAssertEqual(plugin.calculateImage(), 9)
        
        plugin.storeImageCount([imageItem2], isMonitoring: false)
        XCTAssertEqual(plugin.calculateImage(), 9)
        
        plugin.storeImageCount([imageItem2], isMonitoring: true)
        XCTAssertEqual(plugin.calculateImage(), 10)
        
        plugin.storeImageCount([imageItem2], isMonitoring: true)
        XCTAssertEqual(plugin.calculateImage(), 10)
    }
    
    func testStatsExtra() {
        guard let commentData = testComment() else {
            XCTFail("commentData is nil")
            return
        }
        let now = Date().timeIntervalSince1970 * 1000
        commentData.statsExtra = CommentStatsExtra(clickTime: now,
                                                    clickFrom: .bubble,
                                                    receiveTime: now + 800)
        commentData.comments[0].quote = "111"
        scheduler?.dispatch(action: .updateData(commentData))
        
        scheduler?.dispatch(action: .ipc(.resetDataCache(nil, .render), nil))
        scheduler?.dispatch(action: .ipc(.fetchCommentDataDesction, { [weak self] response, _ in
            if let description = response as? CommentDiffDataPlugin.CommentDescription {
                XCTAssertNotNil(description.statsExtra)
            } else {
                XCTFail("fetchCommentDataDesction error")
            }
            self?.scheduler?.dispatch(action: .ipc(.resetDataCache(nil, .render), nil))
        }))
        
        guard let plugin = scheduler?.plugin(with: CommentFloatDataPlugin.self) else {
            XCTFail("plugin fail")
            return
        }
        XCTAssertNotNil(plugin.statsExtra)
        scheduler?.dispatch(action: .ipc(.resetDataCache(nil, .edit), nil))
        XCTAssertNil(plugin.statsExtra)
    }

    
    func testRender() {
        guard let commentData = testComment() else {
            XCTFail("commentData is nil")
            return
        }
        commentData.comments[0].quote = "222"
        let now = Date().timeIntervalSince1970 * 1000
        commentData.statsExtra = CommentStatsExtra(clickTime: now,
                                                    clickFrom: .bubble,
                                                    receiveTime: now + 800)
        commentData.statsExtra?.markRecordedEdit() // 没有edit事件
        scheduler?.dispatch(action: .updateData(commentData))
        
        scheduler?.dispatch(action: .interaction(.renderEnd))
        // render上报是异步的，需要延时检查
        let renderExpectation = expectation(description: "renderPerformanceRecord expectation")
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1) {
            XCTAssertTrue(self.testPlugin.renderPerformanceRecord)
            renderExpectation.fulfill()
        }
        wait(for: [renderExpectation], timeout: 3)
        XCTAssertFalse(testPlugin.editPerformanceRecord)
    }

    func testEdit() {
        guard let commentData = testComment() else {
            XCTFail("commentData is nil")
            return
        }
        commentData.comments[0].quote = "333"
        let now = Date().timeIntervalSince1970 * 1000
        commentData.statsExtra = CommentStatsExtra(clickTime: now,
                                                    clickFrom: .bubble,
                                                    receiveTime: now + 800)

        scheduler?.dispatch(action: .updateData(commentData))

        scheduler?.dispatch(action: .interaction(.clickInputBarView))
        
        var userInfo: [AnyHashable : Any] = [:]
        let testRect = CGRect(x: 0, y: 0, width: 375, height: 250)
        userInfo[UIResponder.keyboardFrameEndUserInfoKey] = NSValue(cgRect: testRect)
        userInfo[UIResponder.keyboardFrameBeginUserInfoKey] = NSValue(cgRect: testRect)
        userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] = UIView.AnimationCurve.linear.rawValue
        userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] = 0.0
        let option = Keyboard().keyboardOptions(fromNotificationDictionary: userInfo, event: Keyboard.KeyboardEvent.didShow)
        scheduler?.dispatch(action: .interaction(.keyboardChange(options: option)))

        XCTAssertFalse(testPlugin.renderPerformanceRecord)
        XCTAssertTrue(testPlugin.editPerformanceRecord)
    }


    func testRenderAndEdit() {
        guard let commentData = testComment() else {
            XCTFail("commentData is nil")
            return
        }
        commentData.comments[0].quote = "444"
        let now = Date().timeIntervalSince1970 * 1000
        commentData.statsExtra = CommentStatsExtra(clickTime: now,
                                                    clickFrom: .bubble,
                                                    receiveTime: now + 800)

        scheduler?.dispatch(action: .updateData(commentData))
        
        scheduler?.dispatch(action: .interaction(.renderEnd))
         
        var userInfo: [AnyHashable : Any] = [:]
        let testRect = CGRect(x: 0, y: 0, width: 375, height: 250)
        userInfo[UIResponder.keyboardFrameEndUserInfoKey] = NSValue(cgRect: testRect)
        userInfo[UIResponder.keyboardFrameBeginUserInfoKey] = NSValue(cgRect: testRect)
        userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] = UIView.AnimationCurve.linear.rawValue
        userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] = 0.0
        let option = Keyboard().keyboardOptions(fromNotificationDictionary: userInfo, event: Keyboard.KeyboardEvent.didShow)
        scheduler?.dispatch(action: .interaction(.keyboardChange(options: option)))

        // render上报是异步的，需要延时检查
        let renderExpectation = expectation(description: "renderPerformanceRecord expectation")
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1) {
            XCTAssertTrue(self.testPlugin.renderPerformanceRecord)
            renderExpectation.fulfill()
        }
        wait(for: [renderExpectation], timeout: 3)

        XCTAssertTrue(testPlugin.editPerformanceRecord)
    }
    
    func testFPS() {
        guard let commentData = testComment() else {
            XCTFail("commentData is nil")
            return
        }
        commentData.comments[0].quote = "555"
        scheduler?.dispatch(action: .updateData(commentData))
        let item1 = commentData.comments[3].commentList[2]
        scheduler?.dispatch(action: .interaction(.willBeginDragging(items: [item1])))
        let item2 = commentData.comments[3].commentList[3]
        XCTAssertFalse(testPlugin.fpsPerformanceRecord)
        let fpsExpectation = expectation(description: "testFPS")
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 2) {
            self.scheduler?.dispatch(action: .interaction(.didEndDragging))
            XCTAssertTrue(self.testPlugin.fpsPerformanceRecord)
            fpsExpectation.fulfill()
        }
        wait(for: [fpsExpectation], timeout: 5)
    }

}

extension CommentMonitorPluginTests: CommentServiceContext {
    var businessDependency: DocsCommentDependency? {
        return self
    }
    
    var topMost: UIViewController? {
        return nil
    }
    
    var commentPluginView: UIView {
        return UIView()
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


extension CommentMonitorPluginTests: DocsCommentDependency {
    var commentDocsInfo: CommentDocsInfo {
        return testDocsInfo
    }
    
    var businessConfig: CommentBusinessConfig {
        let monitorConfig = CommentBusinessConfig.MonitorConfig(fpsEnable: true, editEnable: true, loadedEnable: true)
        return CommentBusinessConfig(canOpenURL: false,
                                     canOpenProfile: false,
                                     canCopyCommentLink: true,
                                     monitorConfig: monitorConfig)
    }
    
}

