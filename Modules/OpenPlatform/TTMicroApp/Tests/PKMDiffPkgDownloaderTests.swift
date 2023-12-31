//
//  File.swift
//  TTMicroApp-Unit-Tests
//
//  Created by laisanpin on 2023/1/16.
//

import Foundation
import XCTest
@testable import TTMicroApp

class PKMDiffPackageDownloadTaskTests: XCTestCase {
    private let uniqueIDOne = BDPUniqueID(appID: "cli_mock_01", identifier: nil, versionType: .current, appType: .gadget)
    private let uniqueIDTwo = BDPUniqueID(appID: "cli_mock_01", identifier: nil, versionType: .current, appType: .gadget)

    func test_hashable_equal() {
        // Arrange
        let trace = BDPTracingManager.sharedInstance().generateTracing()
        let pkgCtxOne = BDPPackageContext(uniqueID: uniqueIDOne, version: "0.0.1", urls: [], packageName: "mock_pkg_name", packageType: .pkg, md5: nil, trace: trace)

        let pkgCtxTwo = BDPPackageContext(uniqueID: uniqueIDTwo, version: "0.0.1", urls: [], packageName: "mock_pkg_name", packageType: .pkg, md5: nil, trace: trace)

        // Act
        let taskOne = PKMDiffPackageDownloadTask(packageContext: pkgCtxOne, downloadPriority: 0, callbacks: nil)
        let taskTwo = PKMDiffPackageDownloadTask(packageContext: pkgCtxTwo, downloadPriority: 0, callbacks: nil)

        // Assert
        XCTAssertEqual(taskOne, taskTwo)
    }

    func test_hashable_notEqual() {
        // Arrange
        let trace = BDPTracingManager.sharedInstance().generateTracing()
        let pkgCtxOne = BDPPackageContext(uniqueID: uniqueIDOne, version: "0.0.1", urls: [], packageName: "mock_pkg_name", packageType: .pkg, md5: nil, trace: trace)

        let pkgCtxTwo = BDPPackageContext(uniqueID: uniqueIDTwo, version: "0.0.1", urls: [], packageName: "mock_pkg_name_x", packageType: .pkg, md5: nil, trace: trace)

        // Act
        let taskOne = PKMDiffPackageDownloadTask(packageContext: pkgCtxOne, downloadPriority: 0, callbacks: nil)
        let taskTwo = PKMDiffPackageDownloadTask(packageContext: pkgCtxTwo, downloadPriority: 0, callbacks: nil)

        // Assert
        XCTAssertNotEqual(taskOne, taskTwo)
    }

    func test_appendNeedCallbacks_success() {
        // Arrange
        let trace = BDPTracingManager.sharedInstance().generateTracing()
        let pkgCtxOne = BDPPackageContext(uniqueID: uniqueIDOne, version: "0.0.1", urls: [], packageName: "mock_pkg_name", packageType: .pkg, md5: nil, trace: trace)

        let pkgCtxTwo = BDPPackageContext(uniqueID: uniqueIDTwo, version: "0.0.1", urls: [], packageName: "mock_pkg_name", packageType: .pkg, md5: nil, trace: trace)


        let callbackOne: PKMDiffPkgDownloadCompletion = { success, reader in
            debugPrint("callbackOne")
        }

        let callbackTwo: PKMDiffPkgDownloadCompletion = { success, reader in
            debugPrint("callbackOne")
        }

        // Act
        let taskOne = PKMDiffPackageDownloadTask(packageContext: pkgCtxOne, downloadPriority: 0, callbacks: [callbackOne])
        let taskTwo = PKMDiffPackageDownloadTask(packageContext: pkgCtxTwo, downloadPriority: 0, callbacks: [callbackTwo])
        taskOne.appendNeedCallbacks(from: taskTwo)

        // Assert
        XCTAssertEqual(taskOne.needCallbacks.count, 2)
    }

    func test_appendNeedCallbacks_failed() {
        // Arrange
        let trace = BDPTracingManager.sharedInstance().generateTracing()
        let pkgCtxOne = BDPPackageContext(uniqueID: uniqueIDOne, version: "0.0.1", urls: [], packageName: "mock_pkg_name", packageType: .pkg, md5: nil, trace: trace)

        let callbackOne: PKMDiffPkgDownloadCompletion = { success, reader in
            debugPrint("callbackOne")
        }

        // Act
        let taskOne = PKMDiffPackageDownloadTask(packageContext: pkgCtxOne, downloadPriority: 0, callbacks: [callbackOne])
        taskOne.appendNeedCallbacks(from: taskOne)

        // Assert
        XCTAssertEqual(taskOne.needCallbacks.count, 1)
    }
}
