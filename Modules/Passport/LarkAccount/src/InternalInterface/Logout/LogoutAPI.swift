//
//  LogoutAPI.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/10.
//

import Foundation
import RxSwift

protocol LogoutAPI {
    /// 登出
    /// 追加 logoutType 参数 https://bytedance.feishu.cn/docx/doxcn8HoM3ipM3jfYJdJ04Wr6Ce?hash=9856644a0723b93a6dc7a59245d6d629
    func logout(sessionKeys: [String], makeOffline: Bool, logoutType: CommonConst.LogoutType, context: UniContextProtocol) -> Observable<Void>

    // 登出栅栏
    func barrier(
        userID: String,
        enter: @escaping (_ leave: @escaping (_ finish: Bool) -> Void) -> Void
    )
    
    func makeOffline() -> Observable<Void>
}

extension LogoutAPI {
    func makeOffline() -> Observable<Void> {
        return .just(())
    }
}
