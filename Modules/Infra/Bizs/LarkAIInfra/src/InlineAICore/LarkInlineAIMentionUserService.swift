//
//  LarkInlineAIMentionUserService.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/9/27.
//

import Foundation
import LarkModel
import RxSwift
import RxCocoa

/// 浮窗组件@ 人服务，实现目前放在LarkAI中，因为LarkAIInfra无法直接依赖Messenger组件里的picker组件
public protocol InlineAIMentionUserService {
    
    /// 点击了@ 用户，进入picker
    /// - Parameters:
    ///   - title: 标题
    ///   - callback: 回调，[PickerItem] 表示@ 用户的数组，取消或异常情况会返回nil
    func showMentionUserPicker(title: String, callback: @escaping ([PickerItem]?) -> Void)
    
    /// 点击了@ 的用户，进入profile页
    func onClickUser(chatterId: String, fromVC: UIViewController)
    
    /// 设置推荐人员列表加载器
    /// - Parameters:
    ///   - firstPageLoader: 首页加载器
    ///   - moreLoader: 更多页加载器
    func setRecommendUsersLoader(firstPageLoader: Observable<PickerRecommendResult>,
                                 moreLoader: Observable<PickerRecommendResult>)
}
