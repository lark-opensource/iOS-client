//  Created by Songwen on 2018/8/22.
// ref https://juejin.im/post/5a31f000518825585132b566

import Foundation

extension DispatchQueue {
    private static var _onceTracker = [String]()

    public func once(file: String = #fileID, function: String = #function, line: Int = #line, block: () -> Void) {
        let token = file + ":" + function + ":" + String(line)
        self.once(token: token, block: block)
    }

    public func once(token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if DispatchQueue._onceTracker.contains(token) {
            return
        }
        DispatchQueue._onceTracker.append(token)
        block()
    }
}
