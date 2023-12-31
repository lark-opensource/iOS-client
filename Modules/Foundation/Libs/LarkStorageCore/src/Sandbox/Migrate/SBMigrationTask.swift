//
//  SBMigrationTask.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import EEAtomic
import LKCommonsLogging

// MARK: - Migration Result

/// 描述文件迁移任务的错误
enum SBMigrationError: Error {

    /// sourcePath errors
    case sourcePathNotExists
    // case sourcePathNotDirectory

    /// targetPath errors
    case cannotResolveTargetPath
    case targetRootPathAlreadyExists

    /// partial errors
    case partialFailure(errors: [Error], total: Int)

    case unknown(Error)
}

typealias SBMigrationResult = Result<Void, SBMigrationError>
extension SBMigrationResult {
    // NOTE: code 值会写到 KV 中，记录迁移结果，不要轻易变更
    enum Code: Int {
        case sourcePathNotExists = 101
        case cannotResolveTargetPath = 201
        case targetRootPathAlreadyExists = 202
        case partialFailure = 301
        case unknown = 999
    }

    var code: Int {
        guard case .failure(let err) = self else {
            return 0
        }
        let code: Code
        switch err {
        case .sourcePathNotExists: code = .sourcePathNotExists
        // case .sourcePathNotDirectory: return 102
        case .cannotResolveTargetPath: code = .cannotResolveTargetPath
        case .targetRootPathAlreadyExists: code = .targetRootPathAlreadyExists
        case .partialFailure:  code = .partialFailure
        case .unknown: code = .unknown
        }
        return code.rawValue
    }
}

// MARK: - Migration Seed

typealias SBMigrationSeed = IsolatePathConfig
extension SBMigrationSeed: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.space.isolationId == rhs.space.isolationId
            && lhs.domain.isSame(as: rhs.domain)
            && lhs.rootType == rhs.rootType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(space.isolationId)
        hasher.combine(domain.asComponents().map(\.isolationId).joined(separator: "."))
        hasher.combine(rootType)
    }

    var key: String {
        let spacePart = "space_" + space.isolationId
        let domainPart = "domain_" + domain.isolationChain(with: "_")
        let typePart = "type_" + rootType.description
        let versPart = "version_v1"
        return "\(spacePart).\(domainPart).\(typePart).\(versPart)"
    }
}

// MARK: - Migration Task

/// 迁移任务
final class SBMigrationTask {

    /// idle -> cancelled
    /// idle -> running -> finished
    enum Status: CustomDebugStringConvertible {
        // swiftlint:disable nesting
        enum CancelReason: Int {
            /// 已经被迁移
            case migrated = 1
            /// 重定向（不需要迁移）
            case redirect
            /// 不允许
            case disallowed
        }
        // swiftlint:enable nesting
        case idle
        case running    // 表示正在迁移（移动文件）
        case finished
        case cancelled(reason: CancelReason)

        var debugDescription: String {
            switch self {
            case .idle: return "idle"
            case .running: return "running"
            case .finished: return "finished"
            case .cancelled(let reason): return "cancelled(\(reason.rawValue))"
            }
        }
    }

    private enum MigrationScene: String {
        case isResolvingRootPath
        case appDidEnterBackground
    }

    typealias Seed = SBMigrationSeed
    typealias Config = SBMigrationConfig

    var seed: Seed
    var config: Config

    // protect `status` & `runningWaiters` & `isActived`
    private var lock = UnfairLock()
    private var status: Status
    private var runningWaitters = [DispatchSemaphore]()
    private var isActived = false // 表示进入使用状态

    required init(seed: Seed, config: Config) {
        self.seed = seed
        self.config = config
        self.status = .idle
    }

    /// 响应后台通知
    /// - Returns: 返回值表示是否执行了后台任务
    func respondsToBackgroundNotification() -> Bool {
        lock.lock()
        guard
            // 1. 配置必须满足后台迁移要求
            case .moveOrDrop(let allows) = config.strategy,
            allows.contains(.background),
            // 2. task 还没激活（避免用户已经使用到了该 task 导致在 App 生命周期内解析路径的逻辑不一致
            case .idle = status,
            !isActived,
            // 3. 之前没有迁移过
            !checkResult()
        else {
            lock.unlock()
            return false
        }
        self.status = .running
        lock.unlock()

        doMigrate(scene: .appDidEnterBackground) {
            self.lock.withLocking {
                self.status = .finished
                self.runningWaitters.forEach { $0.signal() }
            }
        }
        return true
    }

    func resolveRootPath() -> IsolateSandboxPath? {
        log("will resolve rootPath")
        lock.lock()
        isActived = true
        log("current status: \(status.debugDescription)")

        switch status {
        case .idle:
            let nextStatus = nextStatusFromIdleForResolveRootPath()
            self.status = nextStatus
            log("status: idle -> \(nextStatus.debugDescription)")
            lock.unlock()

            if case .running = nextStatus {
                // case 1: idle -> running -> finished
                doMigrate(scene: .isResolvingRootPath) {
                    self.lock.withLocking {
                        self.status = .finished
                        self.runningWaitters.forEach { $0.signal() }
                    }
                }
                return innerResolveRootPath(with: .finished)
            } else {
                // case 2: idle -> cancelled
                return innerResolveRootPath(with: nextStatus)
            }

        case .running:
            log("migration is running now")
            let sema = DispatchSemaphore(value: 0)
            runningWaitters.append(sema)
            lock.unlock()

            log("start waiting migration result")
            let ret = sema.wait(timeout: .now() + .milliseconds(1000 * 2))
            log("end waiting migration result. ret: \(ret)")

            return innerResolveRootPath(with: .finished)

        case .finished, .cancelled:
            let tempStatus = self.status
            lock.unlock()

            return innerResolveRootPath(with: tempStatus)
        }
    }

    private func innerResolveRootPath(with status: Status) -> IsolateSandboxPath? {
        switch status {
        case .idle, .running:
            SBUtils.assertionFailure("unexpected logic")
            return stdRootPath().map { IsolateSandboxPath(rootPart: $0, type: .standard, config: seed) }
        case .finished:
            return stdRootPath().map { IsolateSandboxPath(rootPart: $0, type: .standard, config: seed) }
        case .cancelled(let reason):
            switch reason {
            case .migrated:
                return stdRootPath().map { IsolateSandboxPath(rootPart: $0, type: .standard, config: seed) }
            case .redirect, .disallowed:
                let root = AbsPath(config.fromRoot.absoluteString)
                return .init(rootPart: root, type: .custom, config: seed)
            }
        }
    }

    // 状态机，返回 `idle` 的下一个 status
    private func nextStatusFromIdleForResolveRootPath() -> Status {
        switch config.strategy {
        case .redirect:
            return .cancelled(reason: .redirect)
        case .moveOrDrop(let allows):
            if checkResult() {
                return .cancelled(reason: .migrated)
            } else {
                if allows.contains(.intialization) {
                    return .running
                } else {
                    return .cancelled(reason: .disallowed)
                }
            }
        }
    }

    /// 说明
    /// - 目标：将 `{fromRoot}` rename 为 `{stdRootPath}`
    /// - 只进行一次
    /// - 可能的结果：
    ///     - success. code = 0
    ///     - failure:
    ///       - sourcePathNotExists: 原路径不存在
    ///       - cannotResolveTargetPath: 目标路径获取失败
    ///       - targetRootPathAlreadyExists: 目标路径已经存在文件/目录
    ///       - unknown: 未知/譬如迁移失败
    private func doMigrate(scene: MigrationScene, completion: () -> Void) {
        log("start migrating. scene: \(scene)")
        let start = CFAbsoluteTimeGetCurrent()
        let logAndRecord = { (result: SBMigrationResult) in
            let end = CFAbsoluteTimeGetCurrent()
            let code = result.code
            if case .failure(let err) = result {
                switch err {
                case .unknown(let e):
                    self.log("end migrating. scene: \(scene), unknown error: \(e)")
                case let .partialFailure(errors, total):
                    let completed = "\(total - errors.count)/\(total)"
                    self.log("end migrating. scene: \(scene), partial errors: \(errors), completed: \(completed)")
                default:
                    self.log("end migrating. scene: \(scene), code: \(code)")
                }
            } else {
                self.log("end migrating. succeed. scene: \(scene)")
            }
            let isMainThread = Thread.isMainThread
            DispatchQueue.global(qos: .utility).async {
                self.saveResult(result)
                self.trackResult(result, cost: end - start, scene: scene, isMainThread: isMainThread)
            }
        }

        guard let toRoot = stdRootPath() else {
            completion()
            logAndRecord(.failure(.cannotResolveTargetPath))
            return
        }

        var error: SBMigrationError?
        switch config.pathMatcher {
        case .whole:
            error = wholeMigrate(fromRoot: config.fromRoot, toRoot: toRoot)
        case .partial(let items):
            error = partialMigrate(fromRoot: config.fromRoot, toRoot: toRoot, items: items)
        }

        completion()
        if let err = error {
            logAndRecord(.failure(err))
        } else {
            logAndRecord(.success(()))
        }
    }

    private func wholeMigrate(fromRoot: AbsPath, toRoot: AbsPath) -> SBMigrationError? {
        var error: SBMigrationError?
        if !fromRoot.exists {
            error = .sourcePathNotExists
        } else if toRoot.exists {
            error = .targetRootPathAlreadyExists
        } else {
            do {
                let toParent = (toRoot.absoluteString as NSString).deletingLastPathComponent
                let fm = FileManager()
                if !fm.fileExists(atPath: toParent) {
                    try fm.createDirectory(atPath: toParent, withIntermediateDirectories: true)
                }
                try fm.moveItem(atPath: fromRoot.absoluteString, toPath: toRoot.absoluteString)
            } catch let e {
                error = .unknown(e)
            }
        }
        return error
    }

    private func partialMigrate(
        fromRoot: AbsPath,
        toRoot: AbsPath,
        items: [Config.PathMatcher.PartialItem]
    ) -> SBMigrationError? {
        var errors = [Error]()
        var total = 0
        for item in items {
            let fromPath = fromRoot + item.relativePart
            let toPath = toRoot + item.relativePart
            guard fromPath.exists && !toPath.exists else {
                continue
            }
            do {
                total += 1
                let toParent = (toPath.absoluteString as NSString).deletingLastPathComponent
                let fm = FileManager()
                if !fm.fileExists(atPath: toParent) {
                    try fm.createDirectory(atPath: toParent, withIntermediateDirectories: true)
                }
                try fm.moveItem(atPath: fromPath.absoluteString, toPath: toPath.absoluteString)
            } catch let e {
                errors.append(e)
            }
        }
        if errors.isEmpty {
            return nil
        } else {
            return .partialFailure(errors: errors, total: total)
        }
    }

    private func log(_ msg: String) {
        sandboxLogger.info("\(msg), space: \(seed.space), domain: \(seed.domain), type: \(seed.rootType)")
    }

    // 上报有效的迁移，用以后续下掉迁移逻辑的依据
    private func trackResult(
        _ result: Result<Void, SBMigrationError>,
        cost: CFTimeInterval,
        scene: MigrationScene,
        isMainThread: Bool
    ) {
        let matcherStr: String
        switch config.pathMatcher {
        case .whole: matcherStr = "whole"
        case .partial: matcherStr = "partial"
        }
        let event = TrackerEvent(
            name: "lark_storage_sandbox_migration",
            metric: [
                "latency": cost * 1000
            ],
            category: [
                "root_domain": seed.domain.root.isolationId,
                "scene": scene.rawValue,
                "result": result.code,
                "matcher": matcherStr,
                "is_main_thread": isMainThread
            ],
            extra: [:]
        )
        DispatchQueue.global(qos: .utility).async {
            Dependencies.post(event)
        }
    }

    // 标准的 rootPath
    private func stdRootPath() -> AbsPath? {
        switch seed.rootType {
        case .normal(let type):
            return IsolateSandbox.standardRootPath(
                withSpace: seed.space,
                domain: seed.domain,
                type: type
            )
        case .shared(let type):
            return IsolateSandbox.standardRootPath(
                withSpace: seed.space,
                domain: seed.domain,
                type: type
            )
        }
    }

    // MARK: Save/Load Migration Result in KVStore

    static let config = KVStoreConfig(space: .global, domain: Domain.sandbox.child("Migration"))

    private func checkResult() -> Bool {
        let store = KVStores.udkv(config: Self.config, proxies: [.track, .rekey, .log])
        return store.contains(key: seed.key)
    }

    private func saveResult(_ result: SBMigrationResult) {
        let store = KVStores.udkv(config: Self.config, proxies: [.track, .rekey, .log])
        store.set(result.code, forKey: seed.key)
        store.synchronize()
    }

}
