//
//  CommentDriveDataPluginTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/11/3.
//  


@testable import SKCommon
@testable import SKComment
import XCTest
import RxSwift
import RxCocoa
import SpaceInterface

class CommentDriveDataPluginTests: XCTestCase, TestCommentDataSource {
    var disposeBag = DisposeBag()
    
    var testScheduler: CommentSchedulerServer?
    
    var states: [CommentState] = []
    
    override func setUp() {
        super.setUp()
        let scheduler = CommentSchedulerServer()
        scheduler.connect(plugins: [CommentDriveDataPlugin(),
                                    CommentDriveInteractionPlugin(),
                                    CommentMenuPlugin()])
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
    }
    
    // 正常对齐
    func testAlign() {
        let commentData = testComment()
        XCTAssertNotNil(commentData)
        guard let data = commentData else {
            return
        }
        testScheduler?.dispatch(action: .updateData(data))
        let expect1 = expectation(description: "updateTitle")
        let expect2 = expectation(description: "updateDocsInfo")
        let expect3 = expectation(description: "updatePermission")
        let expect5 = expectation(description: "syncData")
        let expect6 = expectation(description: "reload")
        let expect7 = expectation(description: "foucus")
        for state in states {
            switch state {
            case .updateTitle:
                expect1.fulfill()
            case .updateDocsInfo:
                expect2.fulfill()
            case .updatePermission:
                expect3.fulfill()
            case .syncData:
                expect5.fulfill()
            case .reload:
                expect6.fulfill()
            case let .foucus(indexPath, _, _):
                XCTAssertTrue(indexPath.section == 87)
                expect7.fulfill()
            default:
                break
            }
        }
        wait(for: [expect1, expect2, expect3, expect5, expect6, expect7], timeout: 5, enforceOrder: false)
        states.removeAll()
    }
    
    func testSwitch() {
        let commentData = testComment()
        XCTAssertNotNil(commentData)
        guard let data = commentData else {
            return
        }
        testScheduler?.dispatch(action: .updateData(data))
        states.removeAll()
        
        testScheduler?.dispatch(action: .switchComment(commentId: "7143120258331656193"))
        let expect = expectation(description: "foucus")
        for state in states {
            switch state {
            case let .foucus(indexPath, _, _):
                XCTAssertTrue(indexPath.section == 2)
                expect.fulfill()
            default:
                break
            }
        }
        wait(for: [expect], timeout: 2, enforceOrder: false)
        let id = testScheduler?.fastState.activeCommentId ?? ""
        XCTAssertEqual(id, "7143120258331656193")
    }
    
    func testSnapshoot() {
        let commentData = testComment()
        XCTAssertNotNil(commentData)
        guard let data = commentData else {
            return
        }
        testScheduler?.dispatch(action: .updateData(data))
        let expect = expectation(description: "testSnapshoot")
        let action = CommentAction.ipc(.fetchSnapshoot, { (result, _) in
            guard let snapshoot = result as? CommentSnapshootType else {
                return
            }
            XCTAssertEqual(snapshoot.commentId, "7143058997388558340")
            expect.fulfill()
        })
        scheduler?.dispatch(action: action)
        wait(for: [expect], timeout: 2, enforceOrder: false)
    }
}
 
extension CommentDriveDataPluginTests: CommentServiceContext {
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
        return .float
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
