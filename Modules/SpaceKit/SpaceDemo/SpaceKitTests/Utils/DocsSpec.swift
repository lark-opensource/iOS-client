//
//  DocsSpec.swift
//  DocsTests
//
//  Created by guotenghu on 2019/7/12.
//  Copyright © 2019 Bytedance. All rights reserved.
//一些基本的测试代码写在这里，子类都能用

import Foundation
import Quick
import Nimble
import SwiftyBeaver
@testable import SpaceKit

let testLog: SwiftyBeaver.Type = {
    let log = SwiftyBeaver.self
    let console = ConsoleDestination()  // log to Xcode Console
    log.addDestination(console)
    return log
}()

class DocsSpec: QuickSpec {
    private let consolelog: SwiftyBeaver.Type = {
        let log = SwiftyBeaver.self
        let console = ConsoleDestination()  // log to Xcode Console
        log.addDestination(console)
        return log
    }()

    /// 等一段时间
    ///
    /// - Parameter seconds: 秒数
    func wait(_ seconds: Double) {
        waitUntil(timeout: seconds + 2) { (done) in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds, execute: {
                done()
            })
        }
    }

    func log(_ str: @autoclosure () -> String) {
        consolelog.info(str())
    }

    func initDocsNet() {
        NetConfig.shared.authDelegate = FakeNetWorkDelete.shared
        NetConfig.shared.configWith(baseURL: OpenAPI.docs.baseUrl, additionHeader: [:])
    }
}

final class FakeNetWorkDelete: NetworkAuthDelegate {
    static let shared: FakeNetWorkDelete = FakeNetWorkDelete()
    func handleAuthenticationChallenge() {
//        assertionFailure()
        print("receive AuthenticationChallenge")
    }
}
