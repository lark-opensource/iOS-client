//
//  MonitorTest.swift
//  LarkPrivacyMonitor-Unit-Tests
//
//  Created by yifan on 2023/8/1.
//

import XCTest
import LarkSnCService
@testable import LarkPrivacyMonitor

extension Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static var LPMTestBundle: Bundle? = {
        let bundleName = "LarkPrivacyMonitorTest"
        
        let candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,
            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: MonitorTest.self).resourceURL
        ]
        
        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        return nil
    }()
    
    func dataOfPath(forResource name: String, ofType ext: String) -> Data? {
        let path = path(forResource: name, ofType: ext)
        guard let path = path else {
            return nil
        }
        let url = URL(fileURLWithPath: path)
        do {
            return try Data(contentsOf: url)
        } catch {
            print(error)
        }
        return nil
    }
    
    class func localJsonDict(forResource name: String) -> [String: Any]? {
        let localData = Bundle.LPMTestBundle?.dataOfPath(forResource: name, ofType: "json")
        guard let localData = localData else {
            return nil
        }
        
        var jsonObj: Any?
        do {
            jsonObj = try JSONSerialization.jsonObject(with: localData, options: .mutableContainers)
        } catch {
            // do nothing
        }
        
        return jsonObj as? [String: Any]
    }
}

private final class BundleFileReader {
    /// 读取内置文件的缓存
    private static var dictCache: [String: [String: Any]] = [:]
    
    /// 从Bundle读取配置文件
    static func readConfigFromBundle(forResource name: String, ofType ext: FileType, forKey key: String? = nil) throws -> [String: Any] {
        // 有缓存时从缓存中取数据
        if let key = key, let cachedDict = dictCache[name] {
            return (cachedDict[key] as? [String: Any]) ?? [:]
        }
        let dict = try Bundle.LPMTestBundle?.readFileToDictionary(forResource: name, ofType: ext) ?? [:]
        print("PrivacyMonitor reads config file successfully.")
        
        // 当读取需要解压的文件时，缓存内容
        if let key = key {
            dictCache[name] = dict
            return dict[key] as? [String: Any] ?? [:]
        } else {
            return dict
        }
    }
}

class MonitorTest: XCTestCase {
    
    func testReadBundleFiles() throws {
        // 测试新旧读取逻辑内容是否一致
        let dict1Old = Bundle.localJsonDict(forResource: "low_machine_monitor_setting")
        let dict2Old = Bundle.localJsonDict(forResource: "monitor_setting_config")
        let dict3Old = Bundle.localJsonDict(forResource: "rule_strategy_config")
        guard let bundle = Bundle.LPMTestBundle else {
            XCTFail("无法获取到bundle")
            return
        }
        let dict1New = try? BundleFileReader.readConfigFromBundle(forResource: "low_machine_monitor_setting", ofType: .json)
        let dict2New = try? BundleFileReader.readConfigFromBundle(forResource: "monitor_settings", ofType: .zip, forKey: "monitor_setting_config")
        let dict3New = try? BundleFileReader.readConfigFromBundle(forResource: "monitor_settings", ofType: .zip, forKey: "rule_strategy_config")
        XCTAssertEqual(dict1Old as? NSDictionary, dict1New as? NSDictionary)
        XCTAssertEqual(dict2Old as? NSDictionary, dict2New as? NSDictionary)
        XCTAssertEqual(dict3Old as? NSDictionary, dict3New as? NSDictionary)
        
        XCTAssertThrowsError(try BundleFileReader.readConfigFromBundle(forResource: "unknown_file_path", ofType: .zip)) { error in
            if let error = error as? SnCReadFileError {
                if error != SnCReadFileError.bundlePathNotFound {
                    XCTFail("error type is not matched")
                }
            } else {
                XCTFail("error type is not matched")
            }
        }
    }
}
