//
//  CommentDriveInteractionPluginTests.swift
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

class CommentDriveInteractionPluginTests: XCTestCase, TestCommentDataSource {
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
    
}
 
extension CommentDriveInteractionPluginTests: CommentServiceContext {
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
