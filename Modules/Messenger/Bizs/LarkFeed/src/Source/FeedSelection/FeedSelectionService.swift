//
//  FeedSelectionService.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/8/19.
//

import Foundation
import RxSwift
import LarkUIKit
import RustPB
import LarkMessengerInterface

var FeedSelectionEnable: Bool {
    return Display.pad
}

/// iPad选中态
protocol FeedSelectionService {
    /// 设置Feed选中
    func setSelected(feedId: String?)
    /// 切到对应分组+锚定到Feed+设置Feed选中
    func setSelectedFeed(selection: FeedSelection)

    /// 获取当前选中Feed的FeedId
    func getSelected() -> String?

    /// 返回上/下一次选中的 FeedID 记录
    func selectedRecordID(prev: Bool) -> String?

    /// 监听选中Feed变化
    func observeSelect() -> Observable<String?>
    var selectFeedObservable: Observable<FeedSelection?> { get }
}
