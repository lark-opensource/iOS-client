//
//  CommentImagePluginTests.swift
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
import SKInfra

final class CommentImagePluginTests: XCTestCase, TestCommentDataSource {
    
    var content = CommentAPIContent([:])
    
    var disposeBag = DisposeBag()
    
    var testScheduler: CommentSchedulerServer?
    
    var states: [CommentState] = []
    
    var activeContent = CommentAPIContent([:])
    
    class TestDocCommonDownload: DocCommonDownloadProtocol {
        init() {}
        func download(with context: DocCommonDownloadRequestContext) -> Observable<DocCommonDownloadResponseContext> {
            return .just(DocCommonDownloadResponseContext.initailResponseContext(with: testContext, key: ""))
        }
        
        var testContext: DocCommonDownloadRequestContext {
            return DocCommonDownloadRequestContext.init(fileToken: "", mountNodePoint: "", mountPoint: "", priority: .default, downloadType: .image, localPath: "", isManualOffline: false)
        }
        
        func download(with contexts: [DocCommonDownloadRequestContext]) -> Observable<DocCommonDownloadResponseContext> {
            
            return .just(DocCommonDownloadResponseContext.initailResponseContext(with: testContext, key: ""))
        }

        func downloadNormal(remoteUrl: String, localPath: String, priority: DocCommonDownloadPriority) -> Observable<DocCommonDownloadResponseContext> {
            return .just(DocCommonDownloadResponseContext.initailResponseContext(with: testContext, key: ""))
        }

        func cancelDownload(key: String) -> Observable<Bool> {
            return .just(true)
        }
    }
    
    
    class DocCommonCacheTest: SpaceDownloadCacheProtocol {
        func save(request: DocCommonDownloadRequestContext, completion: ((_ success: Bool) -> Void)?) {
            
        }
        func data(key: String, type: DocCommonDownloadType) -> Data? {
            return nil
        }
        func dataWithVersion(key: String, type: DocCommonDownloadType, dataVersion: String?) -> Data? {
            return nil
        }
        func addImagesToManualCache(infos: [(String, DocCommonDownloadType)]) {
            
        }
        func removeImagesFromManualCache(infos: [(String, DocCommonDownloadType)]) {
            
        }
    }

    
    var commentImagePlugin: CommentImagePlugin?
    
    override func setUp() {
        super.setUp()
        DocsContainer.shared.register(DocCommonDownloadProtocol.self) { _ in
            return TestDocCommonDownload()
        }.inObjectScope(.container)
        
        DocsContainer.shared.register(SpaceDownloadCacheProtocol.self) { _ in
            return DocCommonCacheTest()
        }.inObjectScope(.container)

        let imagePlugin = CommentImagePlugin()
        commentImagePlugin = imagePlugin
        let scheduler = CommentSchedulerServer()
        scheduler.connect(plugins: [CommentFloatDataPlugin(),
                                    imagePlugin,
                                    CommentAPIPlugin(api: self)])
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
    }
    
    func testLoadImagefailed() {
        let commentData = initData()
        let item = commentData.comments[3].commentList[3]
        
        scheduler?.dispatch(action: .interaction(.loadImagefailed(item)))
        
        let refreshExpect = expectation(description: "refresh")
        for state in states {
            if case let .updateItems(indexPath) = state {
                refreshExpect.fulfill()
                // 增加了header数据源，下标加一位
                XCTAssertEqual([IndexPath(row: 3, section: 0)], indexPath)
            }
        }
        wait(for: [refreshExpect], timeout: 1, enforceOrder: false)
        states.removeAll()
        
        // aside drive场景section不为0
        scheduler?.uninstall(plugins: [CommentFloatDataPlugin.self])
        scheduler?.connect(plugins: [CommentAsideDataPlugin()])
        scheduler?.apply(context: self)
        
        let commentData2 = initData()
        let item2 = commentData2.comments[3].commentList[3]
        
        scheduler?.dispatch(action: .interaction(.loadImagefailed(item2)))
        
        let refreshExpect2 = expectation(description: "refresh2")
        for state in states {
            if case let .updateItems(indexPath) = state {
                refreshExpect2.fulfill()
                // 增加了header数据源，下标加一位
                XCTAssertEqual([IndexPath(row: 3, section: 3)], indexPath)
            }
        }
        wait(for: [refreshExpect2], timeout: 1, enforceOrder: false)
        
    }
    
    func testhandleOpenImage() {
        let commentData = initData()
        let item = commentData.comments[3].commentList[3]
        
        scheduler?.dispatch(action: .interaction(.openImage(item: item, imageInfo: item.imageList[0])))
        let replyId: String? = self.activeContent[.replyId]
        let index: Int? = self.activeContent[.index]
        XCTAssertEqual(item.replyID, replyId)
        XCTAssertEqual(index, 0)
        states.removeAll()

        // close
        scheduler?.dispatch(action: .removeAllMenu)
    }

}

extension CommentImagePluginTests: CommentServiceContext {
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


extension CommentImagePluginTests: CommentAPIAdaper {
    func clickQuoteMenu(_ content: CommentAPIContent) {
    
    }
    
    func anchorLinkSwitch(_ content: CommentAPIContent) {

    }
    
    var apiType: CommentAPIAdaperType {
        return.webview
    }
    
    func addComment(_ content: CommentAPIContent) {
        
    }
    
    func addReply(_ content: CommentAPIContent) {
        
    }
    
    func updateReply(_ content: CommentAPIContent) {
        
    }
    
    func deleteReply(_ content: CommentAPIContent) {
        
    }
    
    func resolveComment(_ content: CommentAPIContent) {
        
    }
    
    func retry(_ content: CommentAPIContent) {
        
    }
    
    func translate(_ content: CommentAPIContent) {
        
    }
    
    func addReaction(_ content: CommentAPIContent) {
        
    }
    
    func removeReaction(_ content: CommentAPIContent) {
        
    }
    
    func setDetailPanel(_ content: CommentAPIContent) {
        
    }
    
    func getReactionDetail(_ content: CommentAPIContent) {
        
    }
    
    func readMessage(_ content: CommentAPIContent) {
        
    }
    
    func readMessageByCommentId(_ content: CommentAPIContent) {
        
    }
    
    func scrollComment(_ content: CommentAPIContent) {
        
    }
    
    func activeCommentInvisible(_ content: CommentAPIContent) {
        
    }
    
    func addContentReaction(_ content: CommentAPIContent) {
        
    }
    
    func removeContentReaction(_ content: CommentAPIContent) {
        
    }
    
    func getContentReactionDetail(_ content: CommentAPIContent) {
        
    }
    
    func close(_ content: CommentAPIContent) {
        
    }
    
    func cancelActive(_ content: CommentAPIContent) {
        
    }
    
    func switchCard(_ content: CommentAPIContent) {
        
    }
    
    func panelHeightUpdate(_ content: CommentAPIContent) {
        
    }
    
    func onMention(_ content: CommentAPIContent) {
        
    }
    
    func activateImageChange(_ content: CommentAPIContent) {
        self.activeContent = content
    }
    
    func retryAddNewComment(_ content: CommentAPIContent) {
        
    }
}
