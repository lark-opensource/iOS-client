//
//  FoldApproveDataManager.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/10/19.
//

import Foundation
import UIKit
import LarkStorage
import LarkSetting
import LKCommonsLogging
import LarkMessengerInterface
import LarkFeatureGating
import LarkContainer

class FoldApproveDataConfig {
    private static let logger = Logger.log(FoldApproveDataConfig.self, category: "FoldApproveDataConfig")
    static let settingKey = UserSettingKey.make(userKeyLiteral: "messenger_fold_anim_resource")
    var urlStr: String = ""
    init(settingService: SettingService) {
        if let settings = try? settingService.setting(with: Self.settingKey) as? [String: Any] {
            self.urlStr = (settings["url"] as? String) ?? ""
            Self.logger.info("settings key value count\(settings.count) url: \(self.urlStr.isEmpty)")
        } else {
            Self.logger.error("get FoldApproveDataConfig settings fail")
        }
    }
}

/// 该类用来负责资源的下载和维护
public final class FoldApproveDataManager: FoldApproveDataService, UserResolverWrapper {

    /// 是否有可用的数据
    public var dataUsable = false
    public var hasConfigData = false
    public var filePath: IsoPath? {
        guard dataUsable else {
            return nil
        }
        return getCachedDocumentPath()
    }

    let config: FoldApproveDataConfig
    public let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.config = FoldApproveDataConfig(settingService: userResolver.settings)
        self.userResolver = userResolver
    }
    public func configData(exclude: Bool) {
        if exclude {
            return
        }

        /// 如果FG没有打开 表示不展示动画
        guard userResolver.fg.staticFeatureGatingValue(with: "messenger.message.duplicate_card_fireworks") else {
            return
        }

        /// 如果没有URL 不要再进行后续操作
        let url = self.config.urlStr
        if url.isEmpty {
            return
        }

        if hasConfigData {
            return
        }
        hasConfigData = true

        guard let needData = self.needDowloadData() else {
            return
        }
        if needData {
            loadDataWithURLStr(url) { [weak self] data in
                guard let self = self else {
                    return
                }
                if let data = data, !data.isEmpty {
                    self.updateDataUsable(dataUsable: self.createFileIfNeeded(data))
                } else {
                    self.updateDataUsable(dataUsable: false)
                }
            }
        } else {
            self.dataUsable = true
        }
    }

    func updateDataUsable(dataUsable: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.dataUsable = dataUsable
        }
    }

    func getCachedDocumentPath() -> IsoPath {
        let domain = Domain.biz.messenger.child("FoldApprove")
        return IsoPath.global.in(domain: domain).build(.document) + "approve.json"
    }

    func needDowloadData() -> Bool? {
        return !getCachedDocumentPath().exists
    }

    func createFileIfNeeded(_ data: Data) -> Bool {
        let path = getCachedDocumentPath()
        try? path.deletingLastPathComponent.createDirectoryIfNeeded()
        do {
            try path.createFileIfNeeded(with: data)
        } catch {
            print("\(error)")
        }
        return path.exists
    }

    func loadDataWithURLStr(_ urlStr: String, finish: ((Data?) -> Void)?) {
        guard let requestUrl = URL(string: urlStr) else {
            finish?(nil)
            return
        }
        let request = URLRequest(url: requestUrl)
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if error != nil {
                finish?(nil)
            } else {
                finish?(data)
            }
        }
        task.resume()
    }
}
