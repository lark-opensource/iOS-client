//
//  AbsPathTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

class AbsPathTests: XCTestCase {

    lazy var rootDir: AbsPath = { AbsPath.builtInPath(for: .library) + typeName }()
    var sandbox = SandboxBase<AbsPath>()

    override func setUpWithError() throws {
        try super.setUpWithError()
        if rootDir.exists {
            try sandbox.removeItem(atPath: rootDir)
        }
        try sandbox.createDirectory(atPath: rootDir)
    }
    
    func testAbsolute() {
        let checkAbs = { (path: AbsPath) in
            XCTAssert(path.stdValue.starts(with: "/"))
        }
        checkAbs("a/b/c")
        checkAbs("/")
        checkAbs("~")
        checkAbs(" ")
        checkAbs("")
    }

    func testUrl() {
        let raw = "/a/b/c"
        let url = URL(fileURLWithPath: raw)
        let path1 = AbsPath(raw)
        let path2 = AbsPath(url: url)!
        let path3 = AbsPath(url.absoluteString)
        let path4 = AbsPath("file://\(raw)")
        XCTAssert(path1.stdValue == raw)
        XCTAssert(path2.stdValue == raw)
        XCTAssert(path3.stdValue == raw)
        XCTAssert(path4.stdValue == raw)
    }

    func testStringLiteral() {
        let a  = "/Users" as AbsPath
        let b: AbsPath = "/Users"
        let c = AbsPath("/Users")
        XCTAssertEqual(a.stdValue, b.stdValue)
        XCTAssertEqual(a.stdValue, c.stdValue)
        XCTAssertEqual(b.stdValue, c.stdValue)
    }

    func testAppendingRelativePath() {
        do {
            let abs = AbsPath("/a/b")
            assertPath(abs, "/a/b")
            assertPath(abs.appendingRelativePath("file"), "/a/b/file")
            assertPath(abs + "file", "/a/b/file")
        }
        do {
            let abs = AbsPath("/a/b/c/")
            assertPath(abs, "/a/b/c/")
            assertPath(abs.appendingRelativePath("file"), "/a/b/c/file")
            assertPath(abs + "file", "/a/b/c/file")
        }
    }

    func testDeletingLastPathComponent() {
        assertPath(AbsPath("/a/b").deletingLastPathComponent, "/a")
        assertPath(AbsPath("/a/b/").deletingLastPathComponent, "/a")
        assertPath(AbsPath("/a").deletingLastPathComponent, "/")
        assertPath(AbsPath("/a/").deletingLastPathComponent, "/")
        assertPath(AbsPath("/").deletingLastPathComponent, "/")
    }

    func testIsolatable() {
        do {
            let root = "/a/b/c" as AbsPath
            assertPath(root, "/a/b/c")

            let space = Space.global

            let spacePath = root.appendingComponent(with: space)
            assertPath(spacePath, "\(root)/Space-Global")

            let domainPath1 = spacePath.appendingComponent(with: Domain("D1"))
            assertPath(domainPath1, "\(root)/Space-Global/Domain-D1")

            let domainPath2 = spacePath.appendingComponent(with: Domain("D1").child("D2"))
            assertPath(domainPath2, "\(root)/Space-Global/Domain-D1-D2")
        }
    }

    func testIsSame() {
        do {
            XCTAssertTrue(AbsPath("/a/b").isSame(as: AbsPath("/a/b")))
            XCTAssertTrue(AbsPath("/a/b").isSame(as: AbsPath("/a/b/")))
            XCTAssertTrue(AbsPath("/a/b").isSame(as: AbsPath("/a/b/c/..")))
            XCTAssertTrue(AbsPath("./a").isSame(as: AbsPath("a")))
            XCTAssertTrue(AbsPath("/a/b").isSame(as: AbsPath("/a/B"), caseSensitive: false))

            XCTAssertFalse(AbsPath("/a/b").isSame(as: AbsPath("/a/")))
            XCTAssertFalse(AbsPath("/a/b").isSame(as: AbsPath("/a/c")))
            XCTAssertFalse(AbsPath("/a/b").isSame(as: AbsPath("/a/b/c")))
            XCTAssertFalse(AbsPath("/a/b").isSame(as: AbsPath("/a/B")))
        }
    }

    private func assertPath(_ path: AbsPath, _ str: String) {
        XCTAssert(path.absoluteString == str, "path: \(path.absoluteString), str: \(str)")
    }

    func testFixingHomeDirectory() {
        /// refImpl 是 Messenger 业务之前的实现，这个实现 bug 比较多，各种边界都没考虑到，仅供一般情况下的参考。
        ///     其中 `VideoCacheConfig.relativePath` 的值为 `"/Library/Caches"`
        ///
        /// ```swift
        ///     /// 将路径中 HomeDirectory 替换为 当前 HomeDirectory
        ///     ///
        ///     /// - Parameter path: 绝对路径
        ///     /// - Returns: 替换后的路径，替换失败返回nil
        ///     static func replacePathHomeDirectory(with path: String?) -> String? {
        ///         guard let path = path, !path.isEmpty else { return nil }
        ///         let key = VideoCacheConfig.relativePath
        ///         if let range = path.range(of: key) {
        ///             return path.replacingOccurrences(of: path[..<range.lowerBound], with: NSHomeDirectory())
        ///         }
        ///         return nil
        ///    }
        ///
        /// ```
        let refImpl = { (testPath: String, typeRelativePath: String) -> String? in
            guard !testPath.isEmpty else { return nil }
            guard let range = testPath.range(of: typeRelativePath) else {
                return nil
            }
            return testPath.replacingOccurrences(of: testPath[..<range.lowerBound], with: NSHomeDirectory())
        }

        let stdImpl = { (path: String, type: RootPathType.Normal) -> AbsPath? in
            return path.fixingHomeDirectory(withRootType: type)
        }

        let checkEqual = { (ret1: String?, ret2: AbsPath?) in
            XCTAssert((ret1 == nil && ret2 == nil) || (ret1 != nil && ret2 != nil))
            if let ret1, let ret2 {
                XCTAssert(ret1 == ret2.absoluteString, "\(ret1) != \(ret2.absoluteString)")
            }
        }

        do {
            let testPath = "/a/b/c/Library/Caches/d/e"
            let ret1 = refImpl(testPath, "/Library/Caches")
            XCTAssert(ret1 != nil)
            let ret2 = stdImpl(testPath, .cache)
            XCTAssert(ret2 != nil)
            checkEqual(ret1, ret2)
        }

        do {
            let testPath = "abc/Library/Caches/d/e"
            let ret1 = refImpl(testPath, "/Library/Caches")
            XCTAssert(ret1 != nil)
            let ret2 = stdImpl(testPath, .cache)
            XCTAssert(ret2 != nil)
            checkEqual(ret1, ret2)
        }
    }
}
