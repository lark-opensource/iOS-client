//
//  WbTestRunner.swift
//  WbClient
//
//  Created by kef on 2022/7/14.
//

import Foundation

public class WbTestRunner {
    private var ptr: OpaquePointer? = nil
    
    /// WbClient 测试运行器
    ///
    /// # 参数
    /// - testcase: 测试用例 (json 文件)
    public init(_ testcase: [UInt8]) {
        do {
            try testcase.withUnsafeBufferPointer { cByte in
                try wrap_throws { wb_test_runner_new(&ptr, cByte.baseAddress, testcase.count) }
            }
        } catch {
            printError("wb_test_runner_new failed: \(error)")
        }
    }
    
    /// 设置 WbClient 为准备测试状态
    ///
    /// # 参数
    /// - wbClient: 端上所持有的 WbClient
    public func setup(wbClient: WbClient) {
        do {
            try wrap_throws { wb_test_runner_setup(ptr!, wbClient.getCPtr()) }
        } catch {
            printError("wb_test_runner_setup failed: \(error)")
        }
    }
    
    /// 驱动测试运行器播放操作序列 (在UI线程操作)
    ///
    /// 测试用例中的每一个操作包含时间戳, 端上在UI线程定时调用该接口以驱动运行器播放操作序列
    /// 定时的间隔决定了播放精度, 一般可以按 16ms 定时调用 (移动设备输入采样频率60Hz)
    ///
    /// # 参数
    /// - wbClient: 端上所持有的 WbClient
    ///
    /// # 返回
    /// 运行器的进度, 范围 0.0 - 1.0, 1.0 表示完成
    public func replayByNow(wbClient: WbClient) -> Float {
        let cFloat = UnsafeMutablePointer<Float>.allocate(capacity: 1)
        
        do {
            try wrap_throws { wb_test_runner_replay_by_now(ptr!, wbClient.getCPtr(), cFloat) }
        } catch {
            printError("wb_test_runner_replay_by_now failed: \(error)")
            return 1.0
        }
        
        let progress = cFloat.pointee
        free(cFloat)
        return progress
    }
    
    /// 重制 WbClient 到测试前状态
    ///
    /// # 参数
    /// - wbClient: 端上所持有的 WbClient
    public func teardown(wbClient: WbClient) {
        do {
            try wrap_throws { wb_test_runner_teardown(ptr!, wbClient.getCPtr()) }
        } catch {
            printError("wb_test_runner_teardown failed: \(error)")
        }
    }
    
    deinit {
        if ptr == nil {
            printError("WbClientTestRunner deinit failed, not initialised")
            return
        }
        
        wrap { wb_test_runner_destroy(ptr!) }
        ptr = nil
    }
}
