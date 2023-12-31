//
//  CleanTask.swift
//  LarkCache
//
//  Created by Supeng on 2020/8/11.
//

import Foundation

/// 清理结果
public struct TaskResult {
    /// 清理结果计量
    public enum Size {
        /// 数目（行数，用于统计数据库清理结果）
        case count(Int)
        /// 字节数（存储空间大小，用于计量文件）
        case bytes(Int)

        var bytes: Int {
            switch self {
            case .bytes(let value):
                return value
            default:
                return 0
            }
        }

        var count: Int {
            switch self {
            case .count(let value):
                return value
            default:
                return 0
            }
        }
    }

    /// 是否完成
    public var completed: Bool
    /// 清理耗时（ms）
    public var costTime: Int
    /// 清理大小
    public var sizes: [Size]

    /// 构造方法
    /// - Parameters:
    ///   - completed: 是否完成
    ///   - costTime: 耗时
    ///   - size: 清理大小
    public init(
        completed: Bool = true,
        costTime: Int = 0,
        size: Size = .count(0)
    ) {

        self.completed = completed
        self.costTime = costTime
        self.sizes = [size]
    }

    /// 构造方法
   /// - Parameters:
   ///   - completed: 是否完成
   ///   - costTime: 耗时
   ///   - sizes: 清理大小数组
   public init(
       completed: Bool = true,
       costTime: Int = 0,
       sizes: [Size]
   ) {

       self.completed = completed
       self.costTime = costTime
       self.sizes = sizes
   }
}
/// 清理任务，业务方实现这个协议，并且注册TaskRegistry中
public protocol CleanTask {
    /// 完成回调
    typealias Completion = (TaskResult) -> Void

    /// 任务名称的唯一标识符
    var name: String { get }

    /// 执行清理
    /// - Parameters:
    ///   - config: 全局任务配置
    ///   - completion: 完成回调，返回 metrics 数据
    func clean(config: CleanConfig, completion: @escaping Completion)

    /// 当前缓存大小
    /// - Parameters:
    ///   - config: 全局任务配置
    ///   - completion: 完成回调，返回缓存 size
    func size(config: CleanConfig, completion: @escaping Completion)

    /// 取消清理
    func cancel()

    /// 全部缓存任务结束回调，可以用于重建缓存路径
    func allCacheTaskDidCompleted()
}

public extension CleanTask {
    /// 取消任务执行
    func cancel() {}

    /// 全部缓存任务结束回调，可以用于重建缓存路径
    func allCacheTaskDidCompleted() {}

    /// 当前缓存大小
    func size(config: CleanConfig, completion: @escaping Completion) {
        completion(
            TaskResult(
                completed: true,
                costTime: 0,
                size: .bytes(0)
            )
        )
    }
}

extension Array where Element == TaskResult.Size {
    /// 获取清理缓存 bytes 大小
    public var cleanBytes: Int {
        return self.map(\.bytes).reduce(0, +)
    }
    /// 获取清理缓存 count 大小
    public var cleanCount: Int {
        return self.map(\.count).reduce(0, +)
    }
}
