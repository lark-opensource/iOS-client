//
//  LarkDiskMonitorTest.swift
//  LarkFileSystemDevEEUnitTest
//
//  Created by PGB on 2020/3/23.
//

import Foundation
import XCTest
import LarkFileSystem
@testable import LarkFileSystem

class LarkDiskMonitorTest: XCTestCase {
    // swiftlint:disable line_length
    let testJSONString = """
           {
               "configs": [
                   {
                       "config_name": "integrated_monitor",
                       "max_level": 4,
                       "classifications": {
                           "known": [
                               {
                                   "regex": "Library/(Caches|WebKit|Preferences|SplashBoard|OfflineResource|Heimdallr|Application Support|SuiteLogin|Cookies|Saved Application State|MailSDK|Timor|SyncedPreferences|DocsSDK|Sounds|WebCache|SplashBoard|ConfigCenter)"
                               },
                               {
                                   "regex": "Documents/(sdk_storage|stickerSet|DomainSettings.plist|_bdauto_tracker_docu)"
                               },
                               {
                                   "regex": "Documents/LarkUser_[^/]*",
                                   "item_name": "Documents/LarkUser_[^/]*"
                               },
                               {
                                   "regex": "tmp|Documents|Library",
                                   "type": "all"
                               }
                           ],
                           "all": [
                               {
                                   "regex": "Library/[^/]*",
                                   "type": "all"
                               },
                               {
                                   "regex": "Documents/[^/]*",
                                   "type": "all"
                               }
                           ]
                       },
                       "operations": {
                           "known": "slardar_event",
                           "all,subtracting,known": "custom_exception"
                       }
                   },
                   {
                       "config_name": "problem_solving",
                       "classifications": {
                           "valid": [
                               {
                                   "regex": "([^/]*/?){0,3}"
                               }
                           ]
                       },
                       "operations": {
                           "valid": "log_file"
                       }
                   },
                   {
                       "config_name": "detailed_monitor",
                       "classifications": {
                           "monitored": [
                               {
                                   "regex": "Documents/sdk_storage/[^/]*"
                               }
                           ]
                       },
                       "operations": {
                           "monitored": "slardar_event"
                       }
                   }
               ]
           }
       """
    // swiftlint:enable line_length
    func testJSONConvertion() {
        guard let data = testJSONString.data(using: String.Encoding.utf8),
            let dict = try? JSONSerialization.jsonObject(
                with: data,
                options: [JSONSerialization.ReadingOptions.init(rawValue: 0)]) as? [String:Any],
            let rawConfigModel = try? JSONDecoder().decode(RawConfig.self, from: data)
            else { return }
        UserDefaults.standard.set(0, forKey: LarkDiskMonitor.latestMonitoredTimestampKey)
        let monitorFromModel = LarkDiskMonitor(rawConfig: rawConfigModel)
        let monitorFromDict = LarkDiskMonitor(configDict: dict)
        let configsFromModel = monitorFromModel.monitorConfigs.sorted{ $0.configName > $1.configName }
        let configsFromDict = monitorFromDict.monitorConfigs.sorted{ $0.configName > $1.configName }
        XCTAssertEqual(configsFromModel.count, configsFromDict.count)
        print("=====", configsFromModel.count)
        for i in 0 ..< configsFromModel.count {
            print("testing config: \(configsFromModel[i].configName) and \(configsFromDict[i].configName)")
            XCTAssertEqual(configsFromModel[i].description, configsFromDict[i].description)
        }
    }

    func testCase() {
        guard let data = testJSONString.data(using: String.Encoding.utf8),
            let rawConfigModel = try? JSONDecoder().decode(RawConfig.self, from: data)
            else { return }
        UserDefaults.standard.set(0, forKey: LarkDiskMonitor.latestMonitoredTimestampKey)
        LarkDiskMonitor(rawConfig: rawConfigModel).run()
    }
}

