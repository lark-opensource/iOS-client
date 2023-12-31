//
//  Compile.swift
//  Calendar_Cloud
//
//  Created by Rico on 2021/4/20.
//

import Foundation
import ArgumentParser
import Just

let compile_url = "https://cloudapi.bytedance.net/faas/services/tt7ngm/invoke/hello"

@discardableResult
func postCompileMetrics(time: Int) -> HTTPResult {
    let r = Just.post(
        compile_url,
        json: ["user" : Git.userName(),
               "compile_metrics": [
                "time" : time,
                "xcode": Xcode.xcodeVersion()
               ]]
    )
    return r
}

struct Compile: ParsableCommand {
    static var configuration = CommandConfiguration(
        // Optional abstracts and discussions are used for help output.
        abstract: "Calendar iOS 编译",

        // Commands can define a version for automatic '--version' support.
        version: "1.0.0",

        // Pass an array to `subcommands` to set up a nested tree of subcommands.
        // With language support for type-level introspection, this could be
        // provided by automatically finding nested `ParsableCommand` types.
        subcommands: [PreBuild.self, PostBuild.self, PreRun.self, PostRun.self])

}

struct PreBuild: ParsableCommand {

    @Argument(help: "SRC_ROOT Path")
    var srcRootPath: String

    func run() throws {
        /// 记录Build开始时间
        let f = FileManager(srcRootPath: srcRootPath)
        let ts = Int(Date().timeIntervalSince1970)
        f.write(String(ts))

    }
}

struct PostBuild: ParsableCommand {

    @Argument(help: "SRC_ROOT Path")
    var srcRootPath: String

    func run() throws {
        let f = FileManager(srcRootPath: srcRootPath)
        let buildStartTs = Int(f.read())!
        let nowTs = Int(Date().timeIntervalSince1970)
        let duration = nowTs - buildStartTs
        print("上报编译时间：\(duration)")
        let result = postCompileMetrics(
            time: duration
        )
        if !result.ok {
            print("上报出错：\(result)")
        }
    }
}

struct PreRun: ParsableCommand {

    @Argument(help: "SRC_ROOT Path")
    var srcRootPath: String

    func run() throws {
        /// 记录Run开始时间
//        let ts = Int(Date().timeIntervalSince1970)
//        FileManager.write(String(ts))
    }
}

struct PostRun: ParsableCommand {

    @Argument(help: "SRC_ROOT Path")
    var srcRootPath: String
    
}
