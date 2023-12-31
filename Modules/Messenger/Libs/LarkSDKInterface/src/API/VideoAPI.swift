//
//  VideoAPI.swift
//  LarkSDKInterface
//
//  Created by zc09v on 2019/6/4.
//

import Foundation
import RxSwift

public protocol VideoAPI {
    func fetchVideoSourceUrl(url: String) -> Observable<String>
}
