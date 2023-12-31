//
//  OPBlockLogProtocol.swift
//  OPBlock
//
//  Created by bytedance on 2021/12/1.
//

import Foundation
import OPSDK

public protocol OPBlockLogProtocol: OPLogProtocol {
    func info(_ message: String,
                 tag: String,
                 additionalData params: [String: String]?,
                 error: Error?,
                 file: String,
                 function: String,
                 line: Int)
        
        func error(_ message: String,
                   tag: String,
                   additionalData params: [String: String]?,
                   error: Error?,
                   file: String,
                   function: String,
                   line: Int)
}
