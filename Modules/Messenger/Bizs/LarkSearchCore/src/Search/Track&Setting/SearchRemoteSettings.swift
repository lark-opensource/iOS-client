//
//  SearchRemoteSettings.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/6/1.
//

import Foundation
import LarkRustClient
import LarkContainer
import RustPB
import RxSwift
import LKCommonsLogging
import EEAtomic

/// 该类负责封装远端的一些配置项，方便调用方获取. 并做缓存
public final class SearchRemoteSettings {
    public static var shared: SearchRemoteSettings {
        // Injected will do preload once
        return Injected().wrappedValue
    }
    static let logger = Logger.log(SearchRemoteSettings.self, category: "Search")

    /// 使用Provider每次都去重新获取，避免切换租户时rustService被释放
    private var rustService: RustService
    init(rustService: RustService) {
        self.rustService = rustService
    }

    private var syncing: Bool = false
    private var _cachedSettings: [String: Any]?
    var cachedSettings: [String: Any]? {
        lock.withLocking(action: { _cachedSettings })
    }
    private var hasFirstPreload: Bool = false
    private var lock = UnfairLock()
    private let bag = DisposeBag()
    /// 同步数据，NOTE: 可能有延迟, 首次马上使用只有默认值
    public func preload() {
        settings(callback: { _ in })
    }
    private enum SettingResponseError: Error {
        case invalidRepsonse(message: String?)
    }
    private func settings(callback: @escaping ([String: Any]) -> Void) {
        if let cached = cachedSettings {
            callback(cached)
            return
        }
        if syncing { return }
        syncing = true

        // https://cloud.bytedance.net/appSettings/config/119896/detail/status
        var request = Settings_V1_GetSettingsRequest()
        request.fields = ["suite_search_client_config"]
        rustService.async(message: request).asSingle()
        .map { (response: Settings_V1_GetSettingsResponse) in
            if let settings = response.fieldGroups["suite_search_client_config"],
               let data = settings.data(using: .utf8),
               let obj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return obj
            }
            throw SettingResponseError.invalidRepsonse(message: response.fieldGroups["suite_search_client_config"])
        }
        .subscribe { [weak self] (event: SingleEvent<[String: Any]>) in
            self?.syncing = false
            switch event {
            case .success(let response):
                if let self = self {
                    self.lock.withLocking {
                        self._cachedSettings = response
                    }
                }
                callback(response)
            case .error(let error):
                Self.logger.warn("get suite_search_client_config error: \(error)")
                callback([:])
            @unknown default:
                fatalError("shouldn't enter")
            }
        }.disposed(by: bag)
    }

    // MARK: - biz keys
    // following section is specific keys, should preload before get it

    public var minLengthForLocalEmptyBackup: Int {
        if let value = cachedSettings?["search_in_chat_messages_empty_char_length"] as? Int {
            return value
        }
        return 0
    }
    /// 防闪屏的等待时间，等待时间内只有按顺序的远端请求可以上屏
    public var onScreenWaitingTime: TimeInterval {
        if let value = cachedSettings?["search_main_onscreen_waiting_time"] as? Int {
            // unit ms
            return TimeInterval(value) / 1000
        }
        return 0.4 // nolint: magic_number
    }

    public var searchDebounce: TimeInterval {
        if let value = cachedSettings?["search_debounce_ms"] as? Int {
            // unit ms
            return TimeInterval(value) / 1000
        }
        return 0.3 // nolint: magic_number
    }

    public var searchDebounceMs: Int {
        if let value = cachedSettings?["search_debounce_ms"] as? Int {
            // unit ms
            return value
        }
        return 300 // nolint: magic_number
    }

    public var searchLoadingShowDelayMS: Int {
        if let value = cachedSettings?["search_loadingShow_delay_ms"] as? Int {
            // unit ms
            return value
        }
        return 300 // nolint: magic_number
    }
    public var enablePostStableTracker: Bool {
        if let value = cachedSettings?["enable_post_stable_tracker"] as? Bool {
            return value
        } else if !hasFirstPreload {
            preload()
            self.hasFirstPreload = true
        }
        return true
    }
}
