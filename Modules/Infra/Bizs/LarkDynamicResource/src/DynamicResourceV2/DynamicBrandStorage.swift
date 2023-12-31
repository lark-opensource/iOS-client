//
//  DynamicBrandStorage.swift
//  LarkDynamicResource
//
//  Created by 王元洵 on 2023/4/3.
//

import LKCommonsLogging
import LarkEnv
import SSZipArchive
import LarkResource
import LarkAccountInterface
import LarkContainer
import LarkStorage
import LarkSetting

// lint:disable lark_storage_migrate_check - 已治理，灰度中

// 用于灰度：old(URL) -> new(IsoPath)，后续全量后删掉
private enum Path {
    case old(URL)
    case new(IsoPath)

    func appendingPathComponent(_ pathComponent: String) -> Path {
        switch self {
        case .old(let url): return .old(url.appendingPathComponent(pathComponent))
        case .new(let iso): return .new(iso.appendingRelativePath(pathComponent))
        }
    }
}

private extension Data {
    static func read(from path: Path) throws -> Data {
        switch path {
        case .old(let url): return try Data(contentsOf: url)
        case .new(let iso): return try Data.read(from: iso)
        }
    }
}

enum DynamicBrandStorage {
    static let domain = Domain.biz.infra.child("DynamicBrand")
    private static let logger = Logger.log(DynamicBrandStorage.self, category: "Module.LarkDynamicResource")

    static let useLarkStorage = FeatureGatingManager.shared.featureGatingValue(
        with: .init(stringLiteral: "ios.lark_storage.sandbox.lark_dynamic_resource")
    ) // Global
    
    private static var currentResourceDir: Path? {
        @Injected var passport: PassportService
        guard let tenantID = passport.foregroundUser?.tenant.tenantID, let taskID = latestTaskID(of: tenantID),
              let resourceUrl = tenantDir(of: tenantID)?.appendingPathComponent(taskID + "/ka_\(tenantID)") else {
            logger.error("[DynamicBrand] fetch current resource dir failed")
            return nil
        }
        
        return resourceUrl
    }

    private static func tenantDir(of tenantID: String) -> Path? {
        if useLarkStorage {
            return tenantDirNew(for: tenantID).map { .new($0) }
        } else {
            return tenantDirOld(of: tenantID).map { .old($0) }
        }
    }
    
    private static func tenantDirOld(of tenantID: String) -> URL? {
        guard let libDir = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first else { return nil }
        
        return URL(fileURLWithPath: libDir + "/DynamicBrand/\(EnvManager.env.type)_\(EnvManager.env.unit)/\(tenantID)")
    }

    private static func tenantDirNew(for tenantID: String) -> IsoPath? {
        return IsoPath.in(space: .global, domain: domain).build(
            forType: .library,
            relativePart: "DynamicBrand/\(EnvManager.env.type)_\(EnvManager.env.unit)/\(tenantID)"
        )
    }
}

// MARK: Internal interfaces
extension DynamicBrandStorage {
    static var defaultResourceIndexTable: ResourceIndexTable? {
        let backupResourcePath = Bundle.main.bundleURL.appendingPathComponent("dynamic_resource.bundle").path
        return ResourceIndexTable(name: "backupdResouce", indexFilePath: backupResourcePath + "/res-index.plist",
                                  bundlePath: backupResourcePath)
    }
    
    static var latestFeatureSwitch: [String: Any] {
        guard let resourceDir = currentResourceDir else { return [:] }
        
        do {
            let data = try Data.read(from: resourceDir.appendingPathComponent(ResourceManager.get(key: "Feature_Switch", type: "file") ?? "Feature_Switch.json"))
            return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        } catch {
            logger.error("[DynamicBrand] fetch latest FeatureSwitch failed, error: \(error)")
            return [:]
        }
    }
    
    static func latestTaskID(of tenantID: String) -> String? {
        guard let tenantDir = tenantDir(of: tenantID) else {
            return nil
        }
        do {
            switch tenantDir {
            case .old(let tenantDir):
                return try FileManager.default.contentsOfDirectory(atPath: tenantDir.path).sorted().reversed().first
            case .new(let tenantDir):
                return try tenantDir.contentsOfDirectory_().sorted().reversed().first
            }
        } catch {
            logger.error("[DynamicBrand] find latest taskID of \(tenantID), error: \(error)")
            return nil
        }
    }
    
    static func resourceIndexTable(of tenantID: String, and taskID: String) -> ResourceIndexTable? {
        let identifier = "ka_\(tenantID)"
        guard let tenantDir = tenantDir(of: tenantID) else { return nil }
        let resourceDir: String
        switch tenantDir {
        case .old(let tenantDir):
            resourceDir = tenantDir.appendingPathComponent(taskID + "/\(identifier)").path
        case .new(let tenantDir):
            resourceDir = (tenantDir + "\(taskID)/\(identifier)").absoluteString
        }
        return ResourceIndexTable(name: identifier, indexFilePath: resourceDir + "/res-index.plist", bundlePath: resourceDir)
    }
    
    static func copyResource(with src: Data?, taskID: String, tenantID: String) {
        guard let src = src, let dst = tenantDir(of: tenantID)?.appendingPathComponent(taskID) else { return }
        
        logger.info("[DynamicBrand] start copy resource to dst: \(dst)")
        do {
            switch dst {
            case .old(let dst):
                if !FileManager.default.fileExists(atPath: dst.path) {
                    try FileManager.default.createDirectory(at: dst, withIntermediateDirectories: true)
                }
                
                let zipPath = NSTemporaryDirectory().appendingPathComponent(taskID)
                try src.write(to: URL(fileURLWithPath: zipPath))
                SSZipArchive.unzipFile(atPath: zipPath, toDestination: dst.path)
            case .new(let dst):
                try dst.createDirectoryIfNeeded()
                let zipPath = IsoPath.temporary() + taskID
                try src.write(to: zipPath)
                try dst.unzipFile(fromPath: zipPath)
            }
        } catch { logger.error("[DynamicBrand] copy resource failed, dst: \(dst), error: \(error)") }
    }
    
    static func deleteResource(of tenantID: String, current: String) {
        guard let resourceDir = tenantDir(of: tenantID), let latest = latestTaskID(of: tenantID) else { return }
        
        logger.info("[DynamicBrand] delete resource of \(tenantID), current: \(current)")
        do {
            switch resourceDir {
            case .old(let resourceDir):
                try FileManager.default.contentsOfDirectory(atPath: resourceDir.path).filter { $0 != latest && $0 != current }
                    .forEach { try FileManager.default.removeItem(at: URL(fileURLWithPath: resourceDir.appendingPathComponent($0).path)) }
            case .new(let resourceDir):
                try resourceDir.contentsOfDirectory_()
                    .filter { $0 != latest && $0 != current }
                    .forEach { try (resourceDir + $0).removeItem() }
            }
            
        } catch { logger.error("[DynamicBrand] delete resource of \(tenantID), current: \(current), error: \(error)") }
    }
    
    static func fetchFeatureConfig(relativePath: String) -> String? {
        guard let currentResourceDir else {
            logger.error("[DynamicBrand] fetchFeatureConfig failed of: \(relativePath)")
            return nil
        }
        switch currentResourceDir {
        case .old(let resourceDir):
            guard let data = (try? Data(contentsOf: resourceDir.appendingPathComponent(relativePath)))
                    ?? (try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.bundleURL.appendingPathComponent("dynamic_resource.bundle").path.appending(relativePath)))) else {
                logger.error("[DynamicBrand] fetchFeatureConfig failed of: \(relativePath)")
                return nil
            }
            
            return String(data: data, encoding: .utf8)
        case .new(let resourceDir):
            let dataPath = resourceDir + relativePath
            let dataBundlePath = Bundle.main.bundleAbsPath + "dynamic_resource.bundle" + relativePath
            guard let data = (try? Data.read(from: dataPath)) ?? (try? Data.read(from: dataBundlePath)) else {
                logger.error("[DynamicBrand] fetchFeatureConfig failed of: \(relativePath)")
                return nil
            }
            return String(data: data, encoding: .utf8)
        }
    }
}
