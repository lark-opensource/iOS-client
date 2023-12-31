//
//  DisposableLoginConfigAPI.swift
//  LarkAccount
//
//  Created by tangyunfei.tyf on 2021/2/5.
//

import Foundation
import RxSwift

protocol DisposableLoginConfigAPI {
    // 获取免密token相关配置
    func getDisposableLoginConfig() -> Observable<[Int: String]>
}
