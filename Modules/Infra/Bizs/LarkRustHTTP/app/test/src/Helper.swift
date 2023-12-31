//
//  Helper.swift
//  LarkRustClientTests
//
//  Created by SolaWing on 2018/12/21.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import UIKit
import Foundation
import LarkRustClient
import LarkFoundation
import RxSwift
import RustPB
@testable import LarkRustHTTP
@testable import HTTProtocol

class AtomicInt {
    var lock = DispatchSemaphore(value: 1)
    var val: Int
    init(_ val: Int = 0) {
        self.val = val
    }
}

extension AtomicInt {
    @inline(__always)
    public func load() -> Int {
        lock.wait(); defer { lock.signal() }
        return val
    }

    @discardableResult @inline(__always)
    public func add(_ value: Int) -> Int {
        lock.wait(); defer { lock.signal() }
        val += value
        return val
    }

    @discardableResult @inline(__always)
    public func sub(_ value: Int) -> Int {
        lock.wait(); defer { lock.signal() }
        val -= value
        return val
    }
}

func runUntil(condition: @autoclosure () -> Bool) {
    while !condition() {
        RunLoop.current.run(until: Date() + 0.02)
    }
}
func runUntil(timeout: Date, condition: @autoclosure () -> Bool) -> Bool {
    while !condition() {
        let date = Date()
        if date > timeout {
            return false
        }
        RunLoop.current.run(until: date + 0.02)
    }
    return true
}

let settings: [String: Any] = {
    let path = Bundle.main.bundleURL.appendingPathComponent("lark_settings")
    if let data = try? Data(contentsOf: path),
        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return obj
        }
    return [:]
}()

/// global init test rustClient
/// rustClient init dependency
import LarkTTNetInitializor
func ttnetinit() {
    let tncConfig = settings["ttnet_tnc_config"]
    // TTNetInitializor.setupTracker(TTNetLogger(log: logger))

    // let domainSetting = DomainSettingManager.shared.currentSetting
    let domainSetting = settings["release_eu_nc_feishu_biz_domain_config"] as? [String: [String]] ?? [:]

    // 零信任SDK证书配置
    var certLists: [Data]?
    // cert & private key
    // if let security = CertTool.read(with: ZeroTrustConfig.fixedSaveP12Label) {
    //     certLists = security.certificates.map({ CertTool.data(from: $0) })
    // }
    var tncConfigJSON = ""
    if let tncConfig = tncConfig,
    let tncConfigData = try? JSONSerialization.data(withJSONObject: tncConfig, options: []),
    let tncConfigJSONString = String(data: tncConfigData, encoding: .utf8) {
        tncConfigJSON = tncConfigJSONString
    }
    // let uaConfig = LarkFeatureGating.shared.getFeatureBoolValue(for: "messenger.ttnet.ua.config")
    let userAgent = ""
    // if uaConfig {
    //     userAgent = LarkFoundation.Utils.userAgent
    // }
    let config = TTNetInitializor.Configuration(
        userAgent: userAgent,
        deviceID: "",
        session: "",
        tenentID: "",
        uuid: "",
        envType: .release,
        envUnit: "eu_nc",
        tncConfig: tncConfigJSON,
        tncDomains: domainSetting["ttnet_tnc"] ?? [],
        httpDNS: domainSetting["ttnet_httpdns"] ?? [],
        netlogDomain: domainSetting["ttnet_netlog"] ?? [],
        certificateList: certLists
    )
    TTNetInitializor.initialize(config)
}

import Swinject
import LarkContainer
import LarkAccountAssembly
import AppContainer
import LKLoadable

func assembly() {
    LKLoadableManager.run(appMain)
    _ = Assembler(assemblies: [], assemblyInterfaces: [
        LarkAccountAssembly()
    ], container: BootLoader.container)
    BootLoader.assemblyLoaded = true
}

import OfflineResourceManager
// auto load without setup will crash
func gurdAssembly() {
    let config = OfflineResourceConfig(appId: "1161",
                                       appVersion: "3.14.0",
                                       deviceId: "",
                                       domain: "",
                                       cacheRootDirectory: NSHomeDirectory() + "/Documents/OfflineResource")
    OfflineResourceManager.setConfig(config)
}

var rustClient: RustClient = {
    assembly()
    ttnetinit()
    gurdAssembly()
    #if targetEnvironment(simulator)
    let url = URL(fileURLWithPath: "/tmp/rust/")
    #else
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("rust")
    #endif

    var domainInitConfig = DomainInitConfig()
    domainInitConfig.channel = "Release"
    domainInitConfig.kaInitConfigPath = Bundle.main.bundlePath
    domainInitConfig.isCustomizedKa = false

    var env = RustClientConfiguration.EnvV2()
    env.type = .release
    env.unit = "eu_nc"
    env.brand = "feishu"

    let version = "5.1.0"
    let systemVersion = UIDevice.current.systemVersion
    let deviceVersion = systemVersion.replacingOccurrences(of: ".", with: "_")
    let locale = "zh_CN"
    let userAgent = "Mozilla/5.0 "
                + "(iPhone; CPU iPhone OS \(deviceVersion) like Mac OS X) "
                + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(systemVersion) "
                + "Mobile/15E148 Safari/604.1 Feishu/\(version) LarkLocale/\(locale)"

    let configuration = RustClientConfiguration(
        identifier: "AuthRustClient",
        storagePath: url,
        version: version,
        osVersion: UIDevice.current.systemVersion,
        userAgent: userAgent, envV2: env,
        // appId: "com.bytedance.ee.inhouse.larkone.larkdev",
        appId: "com.bytedance.feishu",
        localeIdentifier: locale,
        clientLogStoragePath: url.path.appending("logs"),
        dataSynchronismStrategy: .subscribe,
        deviceModel: LarkFoundation.Utils.machineType,
        userId: nil,
        domainInitConfig: domainInitConfig,
        appChannel: "internal-dev",
        // frontierConfig: frontierConfig,
        // certConfig: certConfig,
        domainConfigPath: Bundle.main.bundlePath,

        basicMode: false,
        preReleaseStressTag: "",
        preReleaseFdValue: [],
        preReleaseMockTag: "",
        xttEnv: "", boeFd: [],
        isAnywhereDoorEnable: true,
        settingsQuery: [:]
    )

    // 可能抛出SIGPIPE错误，主工程把他隐藏了
    // 这个信号在一般APP中也没什么用，忽略不会有什么影响. 下面有一个猜测的解释
    // https://stackoverflow.com/questions/8369506/why-does-sigpipe-exist
    signal(SIGPIPE, { v in
        print("RECEIVE SIGPIPE \(v)")
    })

    let client = RustClient(configuration: configuration)
    RustHttpManager.rustService = { client }
    RustHttpManager.globalProxyURL = nil
    let ready = DispatchSemaphore(value: 0)
    client.wait {
        RustHttpManager.ready = true
        ready.signal()
    }
    ready.wait()

    #if DEBUG
    HTTProtocol.shouldShowDebugMessage = true
    #endif

    return client
}()


// MARK: - Extenstion Observable
extension ObservableType {
    /// return nil to filter, else to map
    func compactMap<R>(_ transform: @escaping (Self.Element) throws -> R?) -> Observable<R> {
        return self.map(transform).compact()
    }
    /// filter nil and unwrap value
    func compact<R>() -> Observable<R> where Self.Element == R? {
        // swiftlint:disable identifier_name
        return Observable.create({ (o) -> Disposable in
            self.subscribe({ (e) in
                switch e {
                case .next(let data?):  o.on(.next(data))
                case .completed:        o.on(.completed)
                case .error(let error): o.on(.error(error))
                case .next(.none):      break // filterd
                }
            })
        })
        // swiftlint:enable identifier_name
    }
}

extension URLCredentialStorage {
    func removeAll() {
        self.allCredentials.forEach {
            for (_, v) in $1 {
                self.remove(v, for: $0, options: nil)
            }
        }
    }
}

extension NSObject {
    final func printMethods(withRoot: Bool) {
        func pclass(_ cls: AnyClass) {
            var count: UInt32 = 0
            print("\(cls) methods:")
            if let methods = class_copyMethodList(cls, &count) {
                for i in 0..<count {
                    let desc = method_getDescription( methods[Int(i)] )
                    print("\t\(desc.pointee.name?.description ?? "") - \(String(cString: desc.pointee.types!))")
                }
                free(methods)
            }
        }

        guard var cls = object_getClass(self) else { return }
        pclass(cls)
        while let v = class_getSuperclass(cls), withRoot || v != NSObject.self {
            print("")
            pclass(v)
            cls = v
        }
    }
    @objc
    func printMethods() { printMethods(withRoot: false) }
    @objc
    func printMethodsWithRoot() { printMethods(withRoot: true) }

    @objc
    func printIvars() {
        // swiftlint:disable line_length
        func pclass(_ cls: AnyClass) {
            print("\(cls) ivars: {")
            var count: UInt32 = 0
            let emptyCString = ""
            emptyCString.withCString { emptyCString in
                if let ivars = class_copyIvarList(cls, &count) {
                    for i in 0..<count {
                        let ivar = ivars[Int(i)]
                        let encoding = String(cString: ivar_getTypeEncoding(ivar) ?? emptyCString)
                        var vdesc = ""
                        var offset = -1
                        if let enc = encoding.first {
                            offset = ivar_getOffset(ivar)
                            let v = Unmanaged.passUnretained(self).toOpaque().advanced(by: offset)
                            switch enc {
                            case "@", "#":
                                if let obj = v.load(as: AnyObject?.self) {
                                    vdesc = "\(ObjectIdentifier(obj)): \(obj)"
                                } else {
                                    vdesc = "nil"
                                }
                            case "c", "B": vdesc = v.load(as: Int8.self).description
                            case "i", "l": vdesc = v.load(as: Int32.self).description
                            case "s": vdesc = v.load(as: Int16.self).description
                            case "q": vdesc = v.load(as: Int64.self).description

                            case "C": vdesc = v.load(as: UInt8.self).description
                            case "I", "L": vdesc = v.load(as: UInt32.self).description
                            case "S": vdesc = v.load(as: UInt16.self).description
                            case "Q": vdesc = v.load(as: UInt64.self).description

                            case "f": vdesc = v.load(as: Float.self).description
                            case "d": vdesc = v.load(as: Double.self).description
                            case ":": vdesc = String(cString: v.load(as: UnsafePointer<UInt8>.self))
                            case "*", "^": vdesc = v.load(as: UnsafeRawPointer?.self).debugDescription
                            case "v": vdesc = "void address: \(v)"
                            default: vdesc = "address: \(v)"
                            }
                        }
                        print("\t[\(offset)]\(String(cString: ivar_getName(ivar) ?? emptyCString)):\(encoding) => \(vdesc)")
                    }
                    free(ivars)
                }
            }
            print("}")
        }
        // swiftlint:enable line_length
        guard var cls = object_getClass(self) else { return }
        pclass(cls)
        while let v = class_getSuperclass(cls), v != NSObject.self {
            print("")
            pclass(v)
            cls = v
        }
    }
}

struct Weak<T: AnyObject> {
    weak var value: T?
}
