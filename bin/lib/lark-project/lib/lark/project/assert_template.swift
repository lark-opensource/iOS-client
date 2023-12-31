/// 本代码端用于swift模块内，拦截hook断言相关的方法，避免打断源码程序运行
// TODO: 拦截的assert进行上报消费
// NOTE: 可以断点所有或者部分库的assertionFailure进行本地调试消费

// swiftlint:disable all

#if ALPHA
import Foundation

@inlinable @inline(__always)
func assertionFailure(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    let flag = UserDefaults.standard.bool(forKey: "AssertDebugItemCloseKey")
    if !flag {
        NotificationCenter.default.post(name: .init("CustomAssertNotification"),
                                        object: nil,
                                        userInfo: [
                                            "message": message(),
                                            "file": file,
                                            "line": line
                                        ])
    }
    print("[ERROR][ASSERT]\(file):\(line): \(message())")
}

@inlinable
func assert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    if _slowPath(!condition()) {
        assertionFailure(message(), file: file, line: line)
    }
}

// swiftlint:enable all
#endif
