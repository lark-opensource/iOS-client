//
//  MentionHeaderViewTest.swift
//  ViewTests
//
//  Created by Yuri on 2023/1/5.
//

import Foundation
@testable import LarkIMMention

// swiftlint:disable all
final class MentionHeaderViewTest: ViewTestCase {
    
    var view: IMMentionHeaderView!

    override func setUp() {
        super.setUp()
        view = IMMentionHeaderView()
        view.frame = CGRect(x: 0, y: 0, width: 320, height: 64)
//        recordMode = true
    }
    
    /// 头部
    func testHeaderView() {
        verify(view)
    }
    
    /// 关闭按钮
    func testHeaderViewClose() {
        view.changeToCloseBtn()
        verify(view)
    }
    
    /// 返回按钮
    func testHeaderViewBack() {
        view.changeToLeftBtn()
        verify(view)
    }
    
    /// 还原状态
    func testHeaderViewClear() {
        view.multiClear()
        verify(view)
    }
    
    /// 多选蓝色状态
    func testHeaderViewEnableMulti() {
        view.multiEnableClick()
        verify(view)
    }
}
// swiftlint:enable all
