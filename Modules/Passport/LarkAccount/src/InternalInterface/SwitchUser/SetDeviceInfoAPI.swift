//
//  SetDeviceInfoAPI.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/10.
//

import Foundation
import RxSwift

protocol SetDeviceInfoAPI {
    func setDeviceInfo(deviceId: String, installId: String) -> Observable<Void>
}
