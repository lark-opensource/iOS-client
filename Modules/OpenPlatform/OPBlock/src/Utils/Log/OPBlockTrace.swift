//
//  OPBlockTrace.swift
//  OPBlock
//
//  Created by chenziyi on 2021/10/19.
//

import Foundation
import OPSDK
import ECOProbe
import LKCommonsLogging
import TTMicroApp

typealias BlockTrace = OPBlockTrace

class OPBlockTrace: OPBlockLogProtocol {
    public var bdpTracing: BDPTracing
    private let prefix = "[Block] "
    public let uniqueID: OPAppUniqueID
    public var trace: OPTraceProtocol { bdpTracing }

    init(trace: BDPTracing, uniqueID: OPAppUniqueID) {
        self.bdpTracing = trace
        self.uniqueID = uniqueID
    }
    
    func info(_ message: String,
              tag: String = "",
              additionalData params: [String: String]? = nil,
              error: Error? = nil,
              file: String = #fileID,
              function: String = #function,
              line: Int = #line) {
        bdpTracing.info(prefix + "uniqueID: \(uniqueID) " + message,
                        tag: tag,
                        additionalData: params,
                        error: error,
                        file: file,
                        function: function,
                        line: line)
    }
    
    func error(_ message: String,
               tag: String = "",
               additionalData params: [String: String]? = nil,
               error: Error? = nil,
               file: String = #fileID,
               function: String = #function,
               line: Int = #line) {
        bdpTracing.error(prefix + "uniqueID: \(uniqueID) " + message,
                         tag: tag,
                         additionalData: params,
                         error: error,
                         file: file,
                         function: function,
                         line: line)
    }
}
