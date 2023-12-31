//
//  CommentAsideInteractionPluginTests.swift
//  SKCommon-Unit-Tests
//
//  Created by huayufan on 2022/12/29.
//
@testable import SKCommon
@testable import SKComment
import XCTest
import RxSwift
import RxCocoa
import SpaceInterface

class CommentAsideInteractionPluginTests: XCTestCase, TestCommentDataSource {
    var disposeBag = DisposeBag()
    
    var testScheduler: CommentSchedulerServer?
    
    var states: [CommentState] = []
    
    override func setUp() {
        super.setUp()
        if self.testScheduler == nil {
            let scheduler = CommentSchedulerServer()
            scheduler.connect(plugins: [CommentAsideDataPlugin(),
                                        CommentAsideInteractionPlugin(),
                                        CommentMenuPlugin()])
            scheduler.apply(context: self)
            self.testScheduler = scheduler
            testScheduler?.state.skip(1).subscribe(onNext: { [weak self] (state) in
                self?.states.append(state)
            }).disposed(by: disposeBag)
        }
    }

    override func tearDown() {
        super.tearDown()
        disposeBag = DisposeBag()
        self.scheduler?.plugin(with: CommentAsideDataPlugin.self)?.commentSections = []
        states.removeAll()
    }
    
    func testSelect() {
        let commentData = initData()
    
        guard let comment = commentData.comments.last else { return }
        scheduler?.dispatch(action: .interaction(.didSelect(comment)))
        
        let fastState = scheduler?.fastState
        let activeCommentId = fastState?.activeCommentId ?? ""
        
        XCTAssertEqual(activeCommentId, comment.commentID)
    }
}
 
extension CommentAsideInteractionPluginTests: CommentServiceContext {
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
