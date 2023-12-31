//
//  PassportFalconInterceptor.swift
//  LarkContact
//
//  Created by zhaoKejie on 2023/9/1.
//

import Foundation
import BDWebKit
import IESGeckoKit
import LKCommonsLogging
import EEAtomic

class PassportFalconGurdMetaData: NSObject, IESFalconMetaData {
    /// 从文件中获得的data数据
    var falconData: Data?

    /// 描述falcon数据的模型
    var statModel: IESFalconStatModel

    /// 本地文件的路径
    var filePaths: [String]?

    init(statModel: IESFalconStatModel) {
        self.statModel = statModel
    }
}

@objc
class PassportFalconInterceptor: NSObject, IESFalconCustomInterceptor {

    private let logger = Logger.log(PassportFalconInterceptor.self, category: "PassportFalconInterceptor")

    /// 注册accesskey和正则表达式的对应关系
    func register(pattern: String, for accessKey: String) {
        self.accessKeyPatternDictionary[pattern] = accessKey
    }

    @AtomicObject
    var accessKeyPatternDictionary: [String: String] = [:]

    /// 实现IESFalconCustomInterceptor获取FalconMetaData的方法
    @objc
    func falconMetaData(for request: URLRequest) -> IESFalconMetaData? {
        let startTime = CFAbsoluteTimeGetCurrent()
        guard let url = request.url else {
            return nil
        }
        guard let metaData = self._gurdMetaData(with: url.absoluteString) else {
            return nil
        }

        // 使用第一个bundle path作为内置包的文件路径
        // passport/LarkGlobal场景下不会使用combo合并请求文件
        let resourcePath = metaData.statModel.bundles?.first
        if let resourcePath = resourcePath {
            metaData.falconData = IESGurdKit.data(forPath: resourcePath,
                                                  accessKey: metaData.statModel.accessKey,
                                                  channel: metaData.statModel.channel)
        }

        let falconDataLength = metaData.falconData?.count ?? 0
        let statModel = metaData.statModel
        statModel.offlineStatus = (falconDataLength > 0) ? 1 : 0

        statModel.falconDataLength = falconDataLength
        metaData.statModel.readDuration = CFAbsoluteTimeGetCurrent() - startTime

        if falconDataLength > 0 {
            logger.info("get falcon offlineData succ, url: \(url.withoutQueryAndFragment), duration: \(Int(1_000_000 * metaData.statModel.readDuration))μs")
        } else {
            logger.info("get falcon offlineData fail, url: \(url.withoutQueryAndFragment), duration: \(Int(1_000_000 * metaData.statModel.readDuration))μs")
        }

        return metaData
    }

    // 拦截器优先级, 默认
    var falconPriority: UInt = 0

    /// 实现IESFalconCustomInterceptor判断是否拦截的方法
    @objc
    func shouldIntercept(for request: URLRequest) -> Bool {
        guard let urlString = request.url?.absoluteString else {
            return false
        }
        return accessKeyPatternDictionary.contains { regex, _  in
            let prefix = BDWebKitUtil.prefixMatches(in: urlString, withPattern: regex)
            if !prefix.isEmpty {
                return true
            }
            return false
        }
    }

    // MARK: - 内部实现
    func _gurdMetaData(with urlString: String) -> PassportFalconGurdMetaData? {
        var metaData: PassportFalconGurdMetaData?
        // 使用第一个正则匹配上的accesskey映射本地数据
        for (regex, accessKey) in accessKeyPatternDictionary {
            let prefix = BDWebKitUtil.prefixMatches(in: urlString, withPattern: regex)
            if !prefix.isEmpty {
                metaData = self._gurdMetaData(with: urlString, ignorePrefix: prefix, accessKey: accessKey, regex: regex)
                if metaData != nil {
                    break
                }
            }
        }
        return metaData
    }

    func _gurdMetaData(with urlString: String, ignorePrefix prefix: String, accessKey: String, regex: String) -> PassportFalconGurdMetaData? {
        guard !(prefix.isEmpty || prefix.count == urlString.count) else {
            logger.error("prefix:\(prefix) is error")
            return nil
        }

        guard !(prefix.count > urlString.count) else {
            logger.error("prefix:\(prefix) is error")
            return nil
        }

        var absolutePath = urlString.substring(from: prefix.count)
        absolutePath = absolutePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        // 拆分合并的文件请求，例如 'www.xxx.com/{channel}/test1.js,{channel}/test2.css'会被转换成[{channel}/test1.js, {channel}/test2.css]
        let comboPaths: [String] = absolutePath.ies_comboPaths()
        logger.info("get combo path: \(comboPaths)")
        if comboPaths.isEmpty {
            return nil
        }

        guard let channel = URL(string: absolutePath)?.pathComponents.first else {
            return nil
        }
        // 获取内置包目录
        let geckoInternalChannelPath = IESGurdKit.internalRootDirectory(forAccessKey: accessKey, channel: channel)

        // 本地文件的绝对路径
        var filePaths: [String] = []
        // pathExtension
        var mimeTypes: [String] = []
        // 文件的相对路径（资源标识符）
        var bundles: [String] = []

        @discardableResult
        func addFilePath(filePath: String, resourcePath: String) -> Bool {
            if IESGurdKit.hasCache(forPath: resourcePath, accessKey: accessKey, channel: channel) {
                filePaths.append(filePath)
                mimeTypes.append(URL(string: filePath)?.pathExtension ?? "unknown")
                bundles.append(resourcePath)
                return true
            }
            return false
        }

        comboPaths.forEach { path in
            if path.count <= channel.count {
                return
            }

            let searchPath = path.substring(from: channel.count + 1)
            let filePath = geckoInternalChannelPath.appendingPathComponent(searchPath)
            if addFilePath(filePath: filePath, resourcePath: searchPath) {
                return
            }
            // 可能query和fragmen会导致离线文件获取不了，去除后再尝试获取一次
            if let withoutFragmenAndQuarytPath = URL(string: filePath)?.withoutQueryAndFragment {
                _ = addFilePath(filePath: withoutFragmenAndQuarytPath,
                                resourcePath: withoutFragmenAndQuarytPath.replacingOccurrences(of: geckoInternalChannelPath, with: ""))
            }
        }

        let statModel = IESFalconStatModel()
        statModel.accessKey = accessKey
        statModel.channel = channel
        statModel.offlineRule = regex
        statModel.mimeType = mimeTypes.joined(separator: "+")
        statModel.packageVersion = IESGurdKit.packageVersion(forAccessKey: accessKey, channel: channel)

        let metaData = PassportFalconGurdMetaData(statModel: statModel)

        if filePaths.count == comboPaths.count {
            metaData.statModel.bundles = [String](bundles)
            metaData.filePaths = [String](filePaths)
        }

        return metaData
    }
}
