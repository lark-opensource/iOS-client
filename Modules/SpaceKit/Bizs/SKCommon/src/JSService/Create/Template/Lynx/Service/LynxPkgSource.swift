//
//  LynxPkgSource.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/1.
//  swiftlint:disable file_length


import SKFoundation
import RxSwift
import SSZipArchive
import LibArchiveKit
import LarkReleaseConfig
import SKInfra

enum LynxPkgSourceError: Error {
    case pkgNotExist
}

protocol LynxPkgSource {
    typealias FetchPkgCompletion = (LynxResourcePkg?) -> Void
    
    func fetchPkg(completion: @escaping FetchPkgCompletion)
}

extension LynxPkgSource {
    
    func fetchPkg() -> Observable<LynxResourcePkg> {
        return Observable.create { observer in
            self.fetchPkg { pkg in
                if let pkg = pkg {
                    observer.onNext(pkg)
                    observer.onCompleted()
                } else {
                    observer.onError(LynxPkgSourceError.pkgNotExist)
                }
            }
            return Disposables.create()
        }
    }
}

class LynxBuildInPkgSource: LynxPkgSource {
    private let bizId: String
    private let channel: String
    private let buildInZipURL: SKFilePath?
    private let buildInVersionURL: SKFilePath?
    private let bag = DisposeBag()
    
    init(bizId: String, channel: String, buildInZipURL: SKFilePath?, buildInVersionURL: SKFilePath?) {
        self.bizId = bizId
        self.channel = channel
        self.buildInZipURL = buildInZipURL
        self.buildInVersionURL = buildInVersionURL
    }
    
    func fetchPkg(completion: @escaping FetchPkgCompletion) {
        DocsLogger.info("LynxBuildInPkgSource fetchPkg...", component: LogComponents.lynx)
        guard let buildInVersionURL = buildInVersionURL else {
            DocsLogger.info("buildIn version url is nil", component: LogComponents.lynx)
            completion(nil)
            return
        }

        let versionRelativePath = "current_revision"
        let unzipBundleVersionPath = LynxIOHelper.Path.getFilePath_(for: bizId, channel: channel, type: .bundle, relativePath: versionRelativePath)
        let getBundleVersion = LynxIOHelper.getVersion(from: buildInVersionURL).materialize()
        let getUnzipBundleVersion = LynxIOHelper.getVersion(from: unzipBundleVersionPath)
            .materialize()
        Observable.zip(getBundleVersion, getUnzipBundleVersion) { ($0, $1) }
            .filter {
                if case .completed = $0.0, case .completed = $0.1 {
                    DocsLogger.info("LynxBuildInPkgSource filter false", component: LogComponents.lynx)
                    return false
                }
                DocsLogger.info("LynxBuildInPkgSource filter true", component: LogComponents.lynx)
                return true
            }
            .map { (event0, event1) -> Bool in
                if case let .next(bundleVersion) = event0, case let .next(unzipBundleVersion) = event1 {
                    let notEqual = !bundleVersion.isEqual(to: unzipBundleVersion)
                    DocsLogger.info("LynxBuildInPkgSource notEqual:\(notEqual)", component: LogComponents.lynx)
                    return notEqual
                } else if case .next(_) = event0, case .error(_) = event1 {
                    DocsLogger.info("LynxBuildInPkgSource map error, use `true`", component: LogComponents.lynx)
                    return true
                }
                DocsLogger.info("LynxBuildInPkgSource map, use `false`", component: LogComponents.lynx)
                return false
            }
            .subscribe(onNext: { [weak self] needUnzip in
                guard let self = self else { return }
                DocsLogger.info("LynxBuildInPkgSource needUnzip = \(needUnzip)", component: LogComponents.lynx)
                if needUnzip {
                    self.unzipBundlePkg(completion: completion)
                    return
                }
                let rootRath = LynxIOHelper.Path.getPkgFolder_(for: self.bizId, channel: self.channel, type: .bundle)
                DocsLogger.info("LynxBuildInPkgSource bundle rootRath = [\(rootRath.pathString)]", component: LogComponents.lynx)
                let pkg = LynxResourcePkg(rootPath: rootRath, type: .bundle)
                completion(pkg)
            }, onError: { _ in
                completion(nil)
            })
            .disposed(by: bag)
    }
    
    private func unzipBundlePkg(completion: @escaping FetchPkgCompletion) {
        let unzipFolder = LynxIOHelper.Path.getSourceFolder_(for: bizId, type: .bundle)
        DocsLogger.info("LynxBuildInPkgSource unzipFolder = [\(unzipFolder.pathString)]", component: LogComponents.lynx)
        guard let srcPath = buildInZipURL else {
            DocsLogger.error("LynxBuildInPkgSource buildInZipURL buildInZipURL?.path error ", component: LogComponents.lynx)
            completion(nil)
            return
        }
        DocsLogger.info("LynxBuildInPkgSource srcPath = [\(srcPath.pathString)]", component: LogComponents.lynx)
        LynxIOHelper.unzip(srcPath: srcPath, dstFolderPath: unzipFolder) { _ in
            let rootRath = LynxIOHelper.Path.getPkgFolder_(for: self.bizId, channel: self.channel, type: .bundle)
            DocsLogger.info("LynxBuildInPkgSource bundle rootRath = [\(rootRath.pathString)]", component: LogComponents.lynx)
            let pkg = LynxResourcePkg(rootPath: rootRath, type: .bundle)
            completion(pkg)
        }
    }
}

class LynxHotfixPkgSource: LynxPkgSource {
    private let bizId: String
    private let channel: String
    private let accessKey: String
    private var geckoAgent: TTGeckoAbility?
    
    init(bizId: String, channel: String, accessKey: String) {
        self.bizId = bizId
        self.channel = channel
        self.accessKey = accessKey
        if !ReleaseConfig.isPrivateKA {
            geckoAgent = DocsSDK.isInDocsApp ? TTGeckoRawImpl() : TTGeckoLarkImpl()
            let bizConfig = GeckoBizConfig(identifier: bizId, key: accessKey, channel: channel)
            geckoAgent?.registerBiz(bizConfig)
        }
    }
    
    func fetchPkg(completion: @escaping FetchPkgCompletion) {
        DocsLogger.info("LynxHotfixPkgSource fetchPkg...", component: LogComponents.lynx)
        guard let agent = geckoAgent else {
            DocsLogger.info("geckoAgent==nil,maybe private KA")
            completion(nil)
            return
        }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        agent.fetchResource(
            by: bizId,
            resourceVersion: version ?? "",
            customParams: nil,
            completed: { [weak self] (finish, result) in
                guard let self = self else { return }
                DispatchQueue.global().async {
                    self.fetchCallback(finish: finish, result: result, completion: completion)
                }
            }
        )
    }
    
    private func fetchCallback(finish: Bool, result: GeckoFetchResult, completion: FetchPkgCompletion) {
        let rootRath = LynxIOHelper.Path.getPkgFolder_(for: self.bizId, channel: channel, type: .hotfix)
        guard finish, result.isSuccess,
              let geckoPkgPath = geckoAgent?.resourceRootFolderPath(identifier: bizId),
              SKFilePath(absPath: geckoPkgPath).exists else {
            let pkg = LynxResourcePkg(rootPath: rootRath, type: .hotfix)
            completion(pkg)
            return
        }
        let isMoveSuccess = self.moveGeckoPkg()
        if !isMoveSuccess {
            DocsLogger.error("lynx gecko pkg move fail")
        }
        let pkg = LynxResourcePkg(rootPath: rootRath, type: .hotfix)
        completion(pkg)
    }
    
    private func moveGeckoPkg() -> Bool {
        guard let agent = geckoAgent else {
            DocsLogger.info("geckoAgent==nil,maybe private KA")
            return false
        }
        guard let geckoPkgPath = agent.resourceRootFolderPath(identifier: bizId) else {
            DocsLogger.info("\(bizId) gecko pkg doesn't exist")
            return false
        }
        let hotfixSourceFolder = LynxIOHelper.Path.getSourceFolder_(for: bizId, type: .hotfix)
        let dstFolder = hotfixSourceFolder.appendingRelativePath(channel)
        hotfixSourceFolder.createDirectoryIfNeeded()
        try? dstFolder.removeItem()
    
        var result = false
        guard let url = URL(string: geckoPkgPath) else {
            DocsLogger.info("move gecko pkg, fail => \(result); from: [\(geckoPkgPath)] to [\(dstFolder.pathString)]")
            return result
        }
        
        do {
            try dstFolder.moveItemFromUrl(from: url)
            result = true
            DocsLogger.info("move gecko pkg, succ => \(result); from: [\(geckoPkgPath)] to [\(dstFolder.pathString)]")
        } catch {
            DocsLogger.info("move gecko pkg, error => \(error); from: [\(geckoPkgPath)] to [\(dstFolder.pathString)]")
        }
        return result
    }
}

class SKLynxHotfixPkgSource: LynxPkgSource {
    private let bizId: String
    private let channel: String
    private let accessKey: String
    private let loadStrategy: LynxGeckoLoadStrategy
    private var geckoAgent: TTGeckoAbility?
    
    init(bizId: String, channel: String, accessKey: String, loadStrategy: LynxGeckoLoadStrategy = .localFirstOrWaitRemote) {
        self.bizId = bizId
        self.channel = channel
        self.accessKey = accessKey
        self.loadStrategy = loadStrategy
        if !ReleaseConfig.isPrivateKA {
            geckoAgent = TTGeckoLarkImpl()
            let bizConfig = GeckoBizConfig(identifier: bizId, key: accessKey, channel: channel)
            geckoAgent?.registerBiz(bizConfig)
        }
    }
    
    func fetchPkg(completion: @escaping FetchPkgCompletion) {
        DocsLogger.info("SKLynxHotfixPkgSource fetchPkg...", component: LogComponents.lynx)
        switch loadStrategy {
        case .onlyLocal:
            completion(getLocalPkg())
        case .localFirstOrWaitRemote:
            if let pkg = getLocalPkg() {
                completion(pkg)
            } else {
                requestGecko { [weak self] (finish, result) in
                    guard let self = self else { return }
                    DocsLogger.info("\(self.bizId), localFirstOrWaitRemote: fetchCallback")
                    self.fetchCallback(finish: finish, result: result, completion: completion)
                }
            }
        case .onlyRemote:
            requestGecko { [weak self] (finish, result) in
                guard let self = self else { return }
                DocsLogger.info("\(self.bizId), onlyRemote: fetchCallback")
                self.fetchCallback(finish: finish, result: result, completion: completion)
            }
        case .localFirstNotWaitRemote:
            completion(getLocalPkg())
            requestGecko { [weak self] (finish, result) in
                guard let self = self else { return }
                DocsLogger.info("\(self.bizId), localFirstNotWaitRemote: fetchCallback")
                self.fetchCallback(finish: finish, result: result, completion: nil)
            }
        }
    }
    
    private func requestGecko(completed: @escaping GeckoFetchSingleFinishBlock) {
        
        //KA审核被拒，屏蔽lynx下载
        DocsLogger.info("KA audit rejected，Forbid downloading lynx")
        let config = GeckoBizConfig(identifier: bizId, key: accessKey, channel: channel)
        let failResult = GeckoFetchResult(config: config, status: .notReady)
        completed(false, failResult)
        return
        
        guard let agent = geckoAgent else {
            DocsLogger.info("geckoAgent==nil,maybe private KA")
            let config = GeckoBizConfig(identifier: bizId, key: accessKey, channel: channel)
            let failResult = GeckoFetchResult(config: config, status: .notReady)
            completed(false, failResult)
            return
        }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        agent.fetchResource(
            by: bizId, resourceVersion: version ?? "",
            customParams: nil, completed: completed
        )
    }
    
    private func fetchCallback(finish: Bool, result: GeckoFetchResult, completion: FetchPkgCompletion?) {
        let rootRath = LynxIOHelper.Path.getPkgFolder_(for: self.bizId, channel: channel, type: .hotfix)
        guard finish, result.isSuccess,
              let geckoPkgPath = geckoAgent?.resourceRootFolderPath(identifier: bizId),
              SKFilePath(absPath: geckoPkgPath).exists else {
            DocsLogger.error("lynx gurd pkg fail, finish：\(finish)，syncStatus：\(result.syncStatus)")
            completion?(nil)
            return
        }
        DispatchQueue.global().async {
            let isMoveSuccess = self.moveGeckoPkg()
            if !isMoveSuccess {
                DocsLogger.error("lynx gecko pkg move fail")
                completion?(nil)
                return
            }
            let pkg = LynxResourcePkg(rootPath: rootRath, type: .hotfix)
            completion?(pkg)
        }
    }

    private func getLocalPkg() -> LynxResourcePkg? {
        let rootRath = LynxIOHelper.Path.getPkgFolder_(for: self.bizId, channel: channel, type: .hotfix)
        return LynxResourcePkg(rootPath: rootRath, type: .hotfix)
    }
    
    private func moveGeckoPkg() -> Bool {
        guard let agent = geckoAgent else {
            DocsLogger.info("geckoAgent==nil,maybe private KA")
            return false
        }
        guard let geckoPkgPath = agent.resourceRootFolderPath(identifier: bizId) else {
            DocsLogger.info("\(bizId) gecko pkg doesn't exist")
            return false
        }
        let hotfixSourceFolder = LynxIOHelper.Path.getSourceFolder_(for: bizId, type: .hotfix)
        let dstFolder = hotfixSourceFolder.appendingRelativePath(channel)
        hotfixSourceFolder.createDirectoryIfNeeded()
        try? dstFolder.removeItem()
        
        var result = false
        guard let url = URL(string: geckoPkgPath) else {
            DocsLogger.info("move gecko pkg, fail => \(result); from: [\(geckoPkgPath)] to [\(dstFolder.pathString)]")
            return result
        }
        do {
            try dstFolder.moveItemFromUrl(from: url)
            result = true
            DocsLogger.info("move gecko pkg, succ => \(result); from: [\(geckoPkgPath)] to [\(dstFolder.pathString)]")
        } catch {
            DocsLogger.info("move gecko pkg, error => \(error); from: [\(geckoPkgPath)] to [\(dstFolder.pathString)]")
        }
        return result
    }
}

class LynxCustomPkgSource: LynxPkgSource {
    let localURL: SKFilePath?
    init(localURL: SKFilePath?) {
        self.localURL = localURL
    }
    func fetchPkg(completion: @escaping FetchPkgCompletion) {
        guard let localURL = localURL else {
            DocsLogger.info("localURL is nil", component: LogComponents.lynx)
            completion(nil)
            return
        }
        let pkg = LynxResourcePkg(rootPath: localURL, type: .custom)
        completion(pkg)
    }
}

class LynxResourcePkg: CustomStringConvertible {
    enum PkgType: String {
        case bundle // 内嵌包
        case hotfix // 热更包
        case custom // debug面板指定包
    }
    
    let rootPath: SKFilePath
    let version: String
    let type: PkgType
    init?(rootPath: SKFilePath, type: PkgType) {
        let versionFilePath = rootPath.appendingRelativePath("current_revision")
        guard let version = LynxIOHelper.syncGetVersion(from: versionFilePath) else {
            return nil
        }
        self.version = version
        self.rootPath = rootPath
        self.type = type
    }
    func getData(from relativePath: String) -> Observable<Data> {
        let filePath = rootPath.appendingRelativePath(relativePath)
        return LynxIOHelper.getData(from: filePath)
    }
    func getAbsolutePath(with relativePath: String) -> SKFilePath {
        return rootPath.appendingRelativePath(relativePath)
    }
    var description: String {
        return "type: \(type)\nversion: \(version)"
    }
}

class LynxIOHelper {
    enum IOError: Error {
        case itemNotExist
        case versionContentNotExist
    }
    
    private static let decompressQueue = DispatchQueue(label: "com.ccm.lynx.iohelper.decompress")
    
    typealias LynxUnzipCompletion = (Bool) -> Void
    
    static func syncGetVersion(from path: SKFilePath) -> String? {
        guard path.exists else {
            return nil
        }
        do {
            let content = try String.read(from: path)
            guard let version = DocsStringUtil.getValue(from: content, of: "version") else {
                return nil
            }
            return version
        } catch let error {
            DocsLogger.error("read version file fail", error: error)
        }
        return nil
    }
    
    static func getVersion(from path: SKFilePath) -> Observable<String> {
        return Observable.create { observer in
            guard path.exists else {
                observer.onError(IOError.itemNotExist)
                return Disposables.create()
            }
            do {
                let content = try String.read(from: path)
                guard let version = DocsStringUtil.getValue(from: content, of: "version") else {
                    observer.onError(IOError.versionContentNotExist)
                    return Disposables.create()
                }
                observer.onNext(version)
                observer.onCompleted()
            } catch let error {
                DocsLogger.error("read version file fail", error: error)
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
    
    static func unzip(srcPath: SKFilePath, dstFolderPath: SKFilePath, completion: @escaping LynxUnzipCompletion) {
        DocsLogger.info("do unzip, srcPath:\(srcPath), dstFolderPath:\(dstFolderPath), thread:\(Thread.current)")
        if !dstFolderPath.exists || !dstFolderPath.isDirectory {
            do {
                try dstFolderPath.createDirectoryIfNeeded(withIntermediateDirectories: true)
            } catch let error {
                DocsLogger.error("create folder fail", error: error)
            }
        }
        if srcPath.pathString.hasSuffix(".zip") {
            decompressZip(srcPath: srcPath, dstFolderPath: dstFolderPath, completion: completion)
        } else if srcPath.pathString.hasSuffix(".7z") {
            decompress7z(srcPath: srcPath, dstFolderPath: dstFolderPath, completion: completion)
        } else {
            spaceAssertionFailure("unsupported compressed format")
            completion(false)
        }
    }
    
    private static func decompress7z(srcPath: SKFilePath, dstFolderPath: SKFilePath, completion: @escaping LynxUnzipCompletion) {
        decompressQueue.async {
            do {
                let file = try LibArchiveFile(path: srcPath.pathString)
                try file.extract7z(toDir: URL(fileURLWithPath: dstFolderPath.pathString))
                completion(true)
            } catch {
                DocsLogger.error("decompress 7z fail", error: error, component: LogComponents.lynx)
                completion(false)
            }
        }
    }
    private static func decompressZip(srcPath: SKFilePath, dstFolderPath: SKFilePath, completion: @escaping LynxUnzipCompletion) {
        do {
            try SSZipArchive.unzipFile(
                atPath: srcPath.pathString,
                toDestination: dstFolderPath.pathString,
                overwrite: true,
                password: nil
            )
            completion(true)
        } catch let error {
            DocsLogger.error("decompress zip fail", error: error, component: LogComponents.lynx)
            completion(false)
        }
    }
    
    static func getData(from path: SKFilePath) -> Observable<Data> {
        return Observable.create { observer in
            do {
                let data = try Data.read(from: path)
                observer.onNext(data)
                observer.onCompleted()
            } catch let error {
                DocsLogger.error("read data fail", error: error)
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
}

extension LynxIOHelper {
    class Path {
        class func getRootFolder_() -> SKFilePath {
            return SKFilePath.globalSandboxWithLibrary.appendingRelativePath("lynx")
        }
        
        
        class func getRootFolder_(for bizID: String) -> SKFilePath {
            let path = getRootFolder_().appendingRelativePath("\(bizID)")
            return path
        }
        
        
        class func getSourceFolder_(for bizID: String, type: LynxResourcePkg.PkgType) -> SKFilePath {
            let path = getRootFolder_(for: bizID).appendingRelativePath("\(type.rawValue)")
            return path
        }
        
        
        class func getPkgFolder_(for bizID: String, channel: String, type: LynxResourcePkg.PkgType) -> SKFilePath {
            let path = getRootFolder_(for: bizID)
                .appendingRelativePath("\(type.rawValue)")
                .appendingRelativePath("\(channel)")
            return path
        }
        
        class func getFilePath_(for bizID: String, channel: String, type: LynxResourcePkg.PkgType, relativePath: String) -> SKFilePath {
            let pkgFolder = getPkgFolder_(for: bizID, channel: channel, type: type)
            return pkgFolder.appendingRelativePath("\(relativePath)")
        }
        
        
        class func getEncryptDBFolderPath_(for bizID: String) -> SKFilePath {
            let root = getRootFolder_(for: bizID)
            return root.appendingRelativePath("db")
        }
        
        
        class func getEncryptDBFilePath_(for bizID: String) -> SKFilePath {
            let folder = getEncryptDBFolderPath_(for: bizID)
            return folder.appendingRelativePath("encrypt.sqlite")
        }
        //------------新方法---------------------//
    }
}

extension String {
    func isBig(than otherVersion: String) -> Bool {
        return self.compare(otherVersion, options: .numeric) == .orderedDescending
    }
    func isEqual(to otherVersion: String) -> Bool {
        return self.compare(otherVersion, options: .numeric) == .orderedSame
    }
}
