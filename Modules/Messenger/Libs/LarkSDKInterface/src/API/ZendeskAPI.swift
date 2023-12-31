//
//  OncallAPI.swift
//  LarkSDKInterface
//
//  Created by maozhenning on 2019/05/07.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift

public protocol ZendeskAPI {

    func getGetLinkExtraData(link: String) -> Observable<Bool>
}
