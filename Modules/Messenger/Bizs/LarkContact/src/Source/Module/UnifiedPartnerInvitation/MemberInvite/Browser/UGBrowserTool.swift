//
//  UGBrowserTool.swift
//  LarkContact
//
//  Created by aslan on 2022/2/22.
//

import Foundation
import LKCommonsLogging
import LarkAccountInterface
import Swinject
import LarkContainer

final class UGBrowserTool {
    static private let logger = Logger.log(UGBrowserTool.self, category: "LarkContact.UGBrowserTool")
    @Provider var accountServiceUG: AccountServiceUG //Global
    @Provider var passportService: PassportService //Global

    public static func checkURLReceivable(url: String, complete: @escaping ((Bool) -> Void)) {
        guard let URL = URL(string: url) else {
            complete(false)
            Self.logger.warn("link error >>> \(url)")
            return
        }
        let request: URLRequest = URLRequest(url: URL, timeoutInterval: 5)
        let queue: OperationQueue = OperationQueue()

        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: URLResponse?, _: Data?, error: Error?) -> Void in
            DispatchQueue.main.async {
                if let error = error {
                    complete(false)
                    Self.logger.warn("link request error >>> \(error.localizedDescription)")
                } else {
                    if let statusCode = response?.statusCode {
                        let receivable = !(statusCode >= 400 || statusCode >= 500)
                        complete(receivable)
                    } else {
                        complete(true)
                    }
                    Self.logger.info("link request statusCode >>> \(response?.statusCode)")
                }
            }
        })
    }

    public func log(_ info: String) {
        if passportService.foregroundUser != nil { //Global
            Self.logger.info(info)
        } else {
            accountServiceUG.log(info)
        }
    }

    public func error(_ info: String) {
        if passportService.foregroundUser != nil { //Global
            Self.logger.error(info)
        } else {
            accountServiceUG.log(info)
        }
    }

    public func warn(_ info: String) {
        if passportService.foregroundUser != nil { //Global
            Self.logger.warn(info)
        } else {
            accountServiceUG.log(info)
        }
    }
}
