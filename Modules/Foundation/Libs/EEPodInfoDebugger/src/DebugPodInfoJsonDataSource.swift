//
//  DebugPodInfoJsonDataSource.swift
//  EEPodInfoDebugger
//
//  Created by tefeng liu on 2019/9/7.
//

import Foundation
import CryptoSwift

final class BundleConfig: NSObject {
    static let SelfBundle = Bundle(for: BundleConfig.self)
    private static let BundleURL = SelfBundle.url(forResource: "EEPodInfoDebugger", withExtension: "bundle")!
    static let PodInfoBundle = Bundle(url: BundleURL)!
}

public final class DebugPodInfoJsonDataSource {
    private let key: String = "thisIsPodInfoFromLarkkkkkkkkkkkk" // 不要修改！如果修改了请关注/script/中对应的脚本
    private let iv: String = "thisIsIvForPodIn" // 不要修改！如果修改了请关注/script/中对应的脚本

    public var podInfoArray: [(String, String)] = []

    public init() {
        loadJsonFromBundle()
    }

    private func loadJsonFromBundle() {
        // load json from bundle
        if let filePath = BundleConfig.PodInfoBundle.path(forResource: "temp", ofType: "data") {
            do {
                let encryData = try Data(contentsOf: URL(fileURLWithPath: filePath), options: .mappedIfSafe)
                let decodeData = decode(data: encryData)
                let data = decodeData
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? [String: AnyObject], let data = jsonResult["data"] as? [[String: String]] {
                    podInfoArray = data.map({ (dataItem) -> (String, String) in
                        return (dataItem["name"] ?? "", dataItem["version"] ?? "")
                    })
                }
            } catch {
                // handle error
            }
        }
    }
}

extension DebugPodInfoJsonDataSource: DebugInfoDataSource {
    var podVersionInfos: [(String, String)] {
        return podInfoArray
    }
}

extension DebugPodInfoJsonDataSource {
    func decode(data: Data) -> Data {
        do {
            let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
            let dec = try aes.decrypt([UInt8](data))
            return Data(bytes: dec, count: Int(dec.count))
        } catch {
            // handle error
        }
        return data
    }
}
