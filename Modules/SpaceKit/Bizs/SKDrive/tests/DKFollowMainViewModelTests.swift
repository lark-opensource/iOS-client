//
//  DKFollowMainViewModelTests.swift
//  SKDrive-Unit-Tests
//
//  Created by ByteDance on 2023/3/6.
//

import XCTest
import SKCommon
import SpaceInterface
@testable import SKDrive

final class DKFollowMainViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testDenintOnExitAttachFileWithCCMPermission() {
        deinitOnExitAttachfile(ccmPermission: true)
    }
    
    func testDenintOnExitAttachFileWithoutCCMPermission() {
        deinitOnExitAttachfile(ccmPermission: false)
    }
    
    private func deinitOnExitAttachfile(ccmPermission: Bool) {
        let followDelegate = MockFollowAPI()
        autoreleasepool {
            let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
            var sut: DKFollowMainViewModel? = DKFollowMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true, isCCMPermission: ccmPermission)
            let config = DriveSDKNaviBarConfig(titleAlignment: .center, fullScreenItemEnable: true)
            let followVC = DKMainViewController(viewModel: sut!, router: DKDefaultRouter(), naviBarConfig: config)
            followVC.fileBlockMountToken = followDelegate.currentFollowAttachMountToken
            sut!.setup(followController: followVC, followAPIDelegate: followDelegate)
            sut = nil
        }
        let expect = expectation(description: "wait for deinit")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1, execute: {
            expect.fulfill()
        })
        waitForExpectations(timeout: 2.0)
        if case let SpaceFollowOperation.onExitAttachFile(isNewAttach) = followDelegate.followOperation! {
            XCTAssertEqual(isNewAttach, !ccmPermission)
        } else {
            XCTFail("")
        }
    }
}


class MockFollowAPI: SpaceFollowAPIDelegate {
    var followOperation: SpaceFollowOperation?
    var meetingID: String? = "mockMeetingID"

    var token: String? = "mockToken"

    var followRole: FollowRole = .presenter

    /// 主 MagicShare 内容是否原生文件
    var isHostNativeContent: Bool = true
    
    /// 当前弹出的预览附件所在文档的位置标记
    var currentFollowAttachMountToken: String? = "mockCurrentTag"
    
    /// 注册 Follow 模块
    func follow(_ followableHost: FollowableViewController?, register content: FollowableContent) {}
    
    /// 反注册 Follow 模块
    func follow(_ followableHost: FollowableViewController?, unRegister content: FollowableContent) {}
    
    /// 添加子 FollowableViewController，如打开附件或者同层附件
    func follow(_ followableHost: FollowableViewController?, add subHost: FollowableViewController) {}

    /// 需要回调给VC的各种操作
    /// - Parameters:
    ///   - operation: 动作信息，key为操作类型，value为动作参数
    func follow(_ followableHost: FollowableViewController?, onOperate operation: SpaceFollowOperation) {
        followOperation = operation
    }

    /// Docs相关js加载完毕
    func followDidReady(_ followableHost: FollowableViewController?) {}

    /// 附件加载完毕，可以开始注册 Follow
    func followAttachDidReady() {}
    
    /// Docs渲染完成
    func followDidRenderFinish(_ followableHost: FollowableViewController?) {}

    /// 用户点击返回按钮，页面即将退出
    func followWillBack(_ followableHost: FollowableViewController?) {}

    /// 前端回调
    func didReceivedJSData(data outData: [String: Any]) {}
    
    // 是否可以设置附件VC
    var canSetAttachFile: Bool { return true }
}
