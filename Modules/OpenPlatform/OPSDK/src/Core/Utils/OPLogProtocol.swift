//
//  OPLogProtocol.swift
//  OPSDK
//
//  Created by bytedance on 2021/12/1.
//

import Foundation
import ECOProbe

public protocol OPLogProtocol {
    var trace: OPTraceProtocol { get }
}
