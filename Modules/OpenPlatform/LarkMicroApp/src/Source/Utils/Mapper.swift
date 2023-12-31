//
//  LarkMicroAppFoundation.swift
//  LarkMicroApp
//
//  Created by 刘洋 on 2021/4/7.
//

import Foundation
import LKCommonsLogging

// downside code from SKFoundation Mapper.swift

private func spaceAssertionFailure(
    _ message: @autoclosure () -> String = "",
    file: StaticString = #fileID,
    line: UInt = #line) {

    assertionFailure(message())
    errorLog("LarkMicroAppFoundation AssertionFailure ", message: message(), file: file, line: line)
}

private func errorLog(
    _ title: String,
    message: @autoclosure () -> String,
    file: StaticString,
    line: UInt) {
    LarkMicroApp.logger.error(title + message() + " in file: \(file)" + " in line: \(line)")
}

extension Array {

    func op_toJSONString() -> String? {
        if !JSONSerialization.isValidJSONObject(self) {
            spaceAssertionFailure("Array is invalid JSONObject!")
            return nil
        }
        if let newData: Data = try? JSONSerialization.data(withJSONObject: self, options: []) {
            let JSONString = NSString(data: newData as Data, encoding: String.Encoding.utf8.rawValue)
            return JSONString as String?
        }
        spaceAssertionFailure("To JSONString failed!")
        return nil
    }

}
