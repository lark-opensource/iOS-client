//
//  MultiAccountDataCenter.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2022/5/9.
//

import Foundation
import RxSwift

/// 支持三方共存的改造 https://bytedance.sg.feishu.cn/docx/doxcnpRiOBvgiKNc7SadEZwmmjf
protocol MultiAccountDataCenter {
    var fgValue: Bool { get set }
    // 获取全量的 account list
    func getAccountList(fetchDb: Bool) -> Observable<(currentAccountId: String, accountList: [MailAccount])>
    func getCachedAccountList() -> [MailAccount]?
    func handleAccountChange(change: MailAccountChange)
    func handleShareAccountChange(change: MailSharedAccountChange)
}
