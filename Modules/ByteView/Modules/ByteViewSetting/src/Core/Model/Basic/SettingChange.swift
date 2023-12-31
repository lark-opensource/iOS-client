//
//  SettingChange.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/27.
//

import Foundation
import ByteViewNetwork

public struct SettingChange<Value> {
    public let value: Value
    public let oldValue: Value?
}

public struct NetworkSettingChange<Request: NetworkRequestWithResponse> {
    public let request: Request
    public let value: Request.Response
    public let oldValue: Request.Response?
}

//extension SettingChange: Equatable where Value: Equatable {}
//extension NetworkSettingChange: Equatable where Request: Equatable, Request.Response: Equatable {}
