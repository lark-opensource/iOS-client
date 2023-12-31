//
//  LarkMagicConfigAPI.swift
//  LarkMagic
//
//  Created by mochangxing on 2020/11/3.
//

import Foundation
import RxSwift

protocol LarkMagicConfigAPI {
    /// 获取字节云平台指定key对应的value
    func fetchSettingsRequest(fields: [String]) -> Observable<[String: String]>
}
