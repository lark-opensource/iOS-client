//
//  LKStringFix.swift
//  LKContentFix
//
//  Created by 李勇 on 2020/9/6.
//

import UIKit
import Foundation
import EEAtomic
import RxSwift
import LarkContainer
import LarkRustClient
import RustPB

/// 字符串修复服务实现
public final class LKStringFix {
    /// 做成单例，方便使用
    public static let shared = LKStringFix()

    private let disposeBag = DisposeBag()

    /// 用来封装只执行一次的操作
    private let onceToken = AtomicOnce()
    /// 所有处理内容的工厂实例
    private var factories: [StringFixFactory] = []

    /// 重新设置下发的配置
    func reloadConfig(_ config: StringFixConfig) {
        // 构造所有的工厂实例
        self.onceToken.once { self.factories = StringFixFactoryRegistery.getFactories() }

        // 重置所有的工厂配置
        self.factories.forEach({ $0.reset() })
        // 让所有的工厂实例获取配置信息
        config.config.forEach { (str, configs) in
            self.factories.forEach { (factory) in
                // 需要根据key把对应的config传入对应的factory
                guard let config = configs[factory.key] else { return }
                factory.loadConfig(str, config)
            }
        }
    }

    /// 从远端拉取最新的配置
    func fetchStringFixConfig(rustService: () -> RustService?) {
        // 该请求SDK返回的是本地settings数据
        var request = Settings_V1_GetSettingsRequest()
        request.fields = [StringFixConfig.key]
        let transform: (Settings_V1_GetSettingsResponse) -> Void  = { [weak self] res in
            guard let `self` = self else { return }
            guard let config = StringFixConfig(fieldGroups: res.fieldGroups) else { return }

            self.reloadConfig(config)
        }
        rustService()?.sendAsyncRequest(request, transform: transform).subscribe().disposed(by: self.disposeBag)
    }

    /// 修复内容
    public func fix(_ attrStr: NSAttributedString) -> NSAttributedString {
        guard !self.factories.isEmpty else { return attrStr }

        let attrStr = NSMutableAttributedString(attributedString: attrStr)
        return self.factories.reduce(attrStr) { $1.fix($0) }
    }
}
