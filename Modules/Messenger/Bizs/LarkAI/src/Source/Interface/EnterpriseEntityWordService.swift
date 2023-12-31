//
//  EnterpriseEntityWordService.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/1/12.
//

import Foundation

/// 企业实体词卡片的代理
public protocol EnterpriseEntityWordDelegate: AnyObject {

    /// 展示企业实体词卡片，锁定会话列表
    func lockForShowEnterpriseEntityWordCard()
    /// 隐藏企业实体词卡片，解锁会话列表
    func unlockForHideEnterpriseEntityWordCard()
}
