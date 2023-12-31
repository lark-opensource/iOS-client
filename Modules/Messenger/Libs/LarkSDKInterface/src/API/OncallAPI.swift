//
//  OncallAPI.swift
//  LarkSDKInterface
//
//  Created by liuwanlin on 2018/5/30.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel

public protocol OncallAPI {
    //创建自己的值班号会话,返回chatId
    func putOncallChat(userId: String, oncallId: String, additionalData: AdditionalData?) -> Observable<String>

    func finishOncallChat(chatId: String, oncallId: String) -> Observable<Void>

    func getHomePageOncalls(fromLocal: Bool) -> Observable<[Oncall]>
}

public typealias OncallAPIProvider = () -> OncallAPI
