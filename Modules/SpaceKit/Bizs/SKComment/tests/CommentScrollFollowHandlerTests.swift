//
//  CommentScrollFollowHandlerTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/4/27.
//  


import XCTest
import UIKit
@testable import SKCommon
import SpaceInterface
@testable import SKComment
import SpaceInterface

class CommentScrollFollowHandlerTests: XCTestCase {
    
    class MockData {
        init(hilightIndex: Int,
             anchorTop: CGFloat = 0,
             conferenceInfo: CommentConference,
             commentItem: CommentItem = CommentItem(),
             detectOffScreen: Bool,
             checkNotice: Bool,
             commentCount: Int,
             tableViewContentOffset: CGPoint,
             tableViewBounds: CGRect,
             cellRectInTableView: CGRect,
             sectionRectInTableView: CGRect,
             sectionRectInContainer: CGRect,
             pointIndexPath: IndexPath,
             convertRsult: CGRect) {
            self.hilightIndex = hilightIndex
            self.conferenceInfo = conferenceInfo
            self.commentItem = commentItem
            self.detectOffScreen = detectOffScreen
            self.checkNotice = checkNotice
            self.commentCount = commentCount
            self.tableViewContentOffset = tableViewContentOffset
            self.tableViewBounds = tableViewBounds
            self.cellRectInTableView = cellRectInTableView
            self.sectionRectInTableView = sectionRectInTableView
            self.sectionRectInContainer = sectionRectInContainer
            self.pointIndexPath = pointIndexPath
            self.convertRsult = convertRsult
            self.anchorTop = anchorTop
            self.commentItem.commentId = "ABC"
            self.commentItem.isNewInput = false
            self.commentItem.replyID = "DEF"
        }
        
        var hilightIndex: Int
        var conferenceInfo: CommentConference
        var commentItem: CommentItem
        var detectOffScreen: Bool
        var checkNotice: Bool
        var commentCount: Int
        var tableViewContentOffset: CGPoint
        var tableViewBounds: CGRect
        var cellRectInTableView: CGRect
        var sectionRectInTableView: CGRect
        var sectionRectInContainer: CGRect
        var pointIndexPath: IndexPath
        var convertRsult: CGRect
        var anchorTop: CGFloat
        
    }
    
    var receiveInfo: CommentScrollInfo?
    
    var offSscreenInfo: CommentScrollInfo?
    
    var mockData: MockData?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        receiveInfo = nil
        mockData = nil
        offSscreenInfo = nil
    }

    func generateMockData() -> MockData {
        let conference = CommentConference(inConference: true, followRole: .presenter, context: nil)
        return MockData(hilightIndex: 0,
                            conferenceInfo: conference,
                            detectOffScreen: true,
                            checkNotice: true,
                            commentCount: 10,
                            tableViewContentOffset: CGPoint(x: 0, y: 60),
                            tableViewBounds: CGRect(x: 0, y: 0, width: 375, height: 664),
                            cellRectInTableView: CGRect(x: 0, y: 10, width: 375, height: 100),
                            sectionRectInTableView: CGRect(x: 0, y: 10, width: 375, height: 300),
                            sectionRectInContainer: CGRect(x: 0, y: -10, width: 375, height: 300),
                            pointIndexPath: IndexPath(row: 0, section: 1),
                            convertRsult: .zero)
    }

    func testPresenterScrollInfo() throws {
        let handler = CommentScrollFollowHandler(commentView: self, commentScrollDelegate: self)
        handler.updateDocsInfo(DocsInfo(type: DocsType.doc, objToken: "123"))
        mockData = generateMockData()
        handler.beginMonitoring()
        
        // 未激活滚动
        mockData?.anchorTop = 0
        mockData?.convertRsult = CGRect(x: 0, y: -30, width: 375, height: 300)
//        handler.commentViewWillBeginDragging()
//        handler.commentViewDidScroll()
//        handler.commentViewDidEndScrolling()
//        XCTAssertNotNil(receiveInfo)
//        XCTAssertTrue(receiveInfo?.replyPercentage == (CGFloat(30) / CGFloat(300)))
//        receiveInfo = nil
        var anchoPoint = CGPoint(x: 0, y: self.anchorPointHeightFromTop)
        var info = handler.caculateScrollInfo(commentView: self, commentItem: mockData!.commentItem, anchoPoint: anchoPoint, indexPath: mockData!.pointIndexPath)
        XCTAssertTrue(info.replyPercentage == (CGFloat(30) / CGFloat(300)))
        
        // 激活滚动
        mockData?.anchorTop = 40
        mockData?.convertRsult = CGRect(x: 0, y: -20, width: 375, height: 300)
        handler.commentViewDidScroll()
//        XCTAssertNotNil(receiveInfo)
//        XCTAssertTrue(receiveInfo?.replyPercentage == (CGFloat(60) / CGFloat(300)))
//        receiveInfo = nil
        anchoPoint = CGPoint(x: 0, y: self.anchorPointHeightFromTop)
        info = handler.caculateScrollInfo(commentView: self, commentItem: mockData!.commentItem, anchoPoint: anchoPoint, indexPath: mockData!.pointIndexPath)
        XCTAssertTrue(info.replyPercentage == (CGFloat(60) / CGFloat(300)))
    }
    
    func testFollowerScrollInfo() throws {
        let handler = CommentScrollFollowHandler(commentView: self, commentScrollDelegate: self)
        handler.updateDocsInfo(DocsInfo(type: DocsType.docX, objToken: "123"))
        mockData = generateMockData()
        mockData?.conferenceInfo = CommentConference(inConference: true, followRole: .follower, context: nil)
        handler.beginMonitoring()
        
        // 滚动
        mockData?.anchorTop = 0
        mockData?.convertRsult = CGRect(x: 0, y: -20, width: 375, height: 300)
        handler.commentViewDidScroll()
        XCTAssertNil(receiveInfo)
        receiveInfo = nil
    }
    
    func testOffScreen () throws {
        let handler = CommentScrollFollowHandler(commentView: self, commentScrollDelegate: self)
        handler.updateDocsInfo(DocsInfo.init(type: DocsType.docX, objToken: "123"))
        mockData = generateMockData()
        mockData?.convertRsult = CGRect(x: 0, y: 0, width: 375, height: 60)
        
        handler.beginMonitoring()
        // 不检查
//        mockData?.detectOffScreen = false
//        handler.commentViewDidScroll()
//        XCTAssertNil(offSscreenInfo)
        var isDetect = handler.detectOffScreenEvent(.zero, self)
        XCTAssertFalse(isDetect)
        // 检查
        mockData?.detectOffScreen = true
//        handler.commentViewDidScroll()
//        XCTAssertNotNil(offSscreenInfo)
//        offSscreenInfo = nil
        mockData?.convertRsult = CGRect(x: 0, y: -100, width: 375, height: 60)
        isDetect = handler.detectOffScreenEvent(.zero, self)
        XCTAssertTrue(isDetect)
    }

}

extension CommentScrollFollowHandlerTests: ScrollableCommentViewType {

    var highLightPageIndex: Int? {
        return 0
    }
    
    /// 锚点距离面板顶部的距离
    var anchorPointHeightFromTop: CGFloat {
        return mockData!.anchorTop
    }
    
    var conferenceInfo: CommentConference? {
        return mockData!.conferenceInfo
    }
    
    func getCurrentItemFor(indexPath: IndexPath) -> CommentItem? {
        return mockData!.commentItem
    }
    
    func getCurrentCommentId(at section: Int) -> String? {
        return mockData!.commentItem.commentId
    }
    
    /// 是否需要检测高亮评论滚动处屏幕外事件
    var detectOffScreen: Bool {
        return mockData!.detectOffScreen
    }
    
    /// 是否需要检测滚动并弹出激活评论提示
    var checkNotice: Bool {
        return mockData!.checkNotice
    }
    
    var commentCount: Int {
        return mockData!.commentCount
    }
    
    var footerSectionHeight: CGFloat {
        return 20
    }
    
    var tableViewContentOffset: CGPoint {
        return mockData!.tableViewContentOffset
    }
    
    var tableViewBounds: CGRect {
        return mockData!.tableViewBounds
    }
    
    ///  根据indexPath的到对应cell在tableView的位置
    func commentRectForRow(at indexPath: IndexPath) -> CGRect {
        return mockData!.cellRectInTableView
    }
    
    ///  根据section的到对应section cell在tableView的位置
    func commentRect(forSection section: Int) -> CGRect {
        return mockData!.sectionRectInTableView
    }
    
    /// 根据point得到对应tableViewCell的indexPath
    func commentIndexPathForRow(at point: CGPoint) -> IndexPath? {
        return mockData!.pointIndexPath
    }
    
    /// tabelViewCell rect转换到评论容器的坐标
    func convertToContent(_ rect: CGRect) -> CGRect {
        return mockData!.convertRsult
    }
    
    var docCommentScrollEnable: Bool {
        return true
    }
}


// MARK: - 接收结果
extension CommentScrollFollowHandlerTests: CommentScrollDelegate {
    
    func highlightedCommentBecomeInvisibale(info: CommentScrollInfo) {
        offSscreenInfo = info
    }
    
    func commentViewDidScroll(info: CommentScrollInfo) {
        receiveInfo = info
    }
}
