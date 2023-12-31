//
//  NoticeContext.swift
//  Moment
//
//  Created by liluobin on 2021/3/8.
//

import Foundation
import UIKit
import LarkMessageBase
import LarkMessageCore
import EENavigator

protocol NoticeDataSourceAPI: AnyObject {
    func reloadDataForFollowStatusChange(userID: String, hadFollow: Bool)
}
protocol NoticePageAPI: UIViewController {
    /// 宿主页面宽度
    var hostSize: CGSize { get }
}

final class NoticeContext: RichTextAbilityParserDependency {
    weak var pageAPI: NoticePageAPI?
    weak var navFromForPad: NavigatorFrom? //用于ipad上push其他vc
    weak var dataSourceAPI: NoticeDataSourceAPI?
    private let colorService: ColorConfigService
    init() {
        self.colorService = ChatColorConfig()
    }
    var targetVC: UIViewController? {
        return self.pageAPI
    }
    var maxWidth: CGFloat {
        return self.pageAPI?.hostSize.width ?? 0
    }
    func getColor(for key: ColorKey, type: Type) -> UIColor {
         return colorService.getColor(for: key, type: type)
    }
}
