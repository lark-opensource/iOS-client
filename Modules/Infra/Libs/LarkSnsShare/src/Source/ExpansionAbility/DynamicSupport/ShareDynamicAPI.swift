//
//  DynamicConfigurationAPI.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/11/21.
//

import Foundation
import RxSwift

protocol ShareDynamicAPI {
    func fetchDynamicConfigurations(fields: [String]) -> Observable<[String: String]>
}
