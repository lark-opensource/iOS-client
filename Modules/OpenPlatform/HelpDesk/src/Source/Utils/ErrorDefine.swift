//
//  ErrorDefine.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/31.
//

import Foundation
import ECOProbe
import LKCommonsLogging

private let logger = Logger.oplog(HelpDeskError.self, category: "HelpDeskError")

enum ErrorKind: String {
    case invalidResourceActionOrConfirm
    case noValidWindow
    case contextReleased
    case invalidAction
    case responseCodeError
    case invalidResponse
    case invalidClient
    case unsupportedViewType
    case stringToDataError
}

class HelpDeskError: Error, CustomStringConvertible {
    
    let kind: ErrorKind?
    let error: Error?
    let monitorCode: OPMonitorCodeProtocol?
    
    let message: String?

    let fileName: String
    let functionName: String
    let line: Int
    
    var hasReported: Bool = false
    
    init(_ kind: ErrorKind, message: String? = nil, fileName: String = #fileID, functionName: String = #function, line: Int = #line) {
        self.kind = kind
        self.error = nil
        self.monitorCode = nil
        self.message = message
        self.fileName = NSString(string: fileName).lastPathComponent
        self.functionName = functionName
        self.line = line
        
        logger.error(description)
    }
    
    init(_ error: Error, message: String? = nil, fileName: String = #fileID, functionName: String = #function, line: Int = #line) {
        self.kind = nil
        self.error = error
        self.monitorCode = nil
        self.message = message
        self.fileName = NSString(string: fileName).lastPathComponent
        self.functionName = functionName
        self.line = line
        
        logger.error(description)
    }
    
    init(_ monitorCode: OPMonitorCodeProtocol, message: String? = nil, fileName: String = #fileID, functionName: String = #function, line: Int = #line) {
        self.kind = nil
        self.error = nil
        self.monitorCode = monitorCode
        self.message = message
        self.fileName = NSString(string: fileName).lastPathComponent
        self.functionName = functionName
        self.line = line
        
        logger.error(description)
    }
    
    deinit {
        // deinit 内不要在任何 block 内调用 self，仅允许同步调用 self
        if !hasReported {
            // 补充上报
            let errorMsg = description
            OPMonitor(EPMClientHelpdeskCode.fail)
                .setErrorMessage(errorMsg)
                .flush()
        }
    }
    
    var description: String {
        var str: String = "HelpDeskError [\(fileName)(\(line))] [\(functionName)]"
        
        if let message = message {
            str = str + " " + message
        }
        
        if let error = error {
            str = str + " " + error.localizedDescription
        } else if let monitorCode = monitorCode {
            str = str + " " + monitorCode.description
        } else if let kind = kind {
            str = str + " " + kind.rawValue
        }
        
        return str
    }
}
