//
//  ShareDynamicConfigurationParser.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/11/14.
//

import Foundation
import LarkContainer
import RxSwift
import LKCommonsLogging
import LarkReleaseConfig

private enum ParserRequestAgreement {
    static let field = "lark_share_configuration_v2"
}

private enum ParserResponseAgreement {
    static let multiChannel = "multiChannel"
    static let items = "items"
    static let contentType = "content_type"
    static let answerTypes = "answer_types"
}

enum DynamicConfParseError: Error {
    case parseFailed
    case illegalConfigurationStruct
    case traceIdNotFound
    case fetchFailed
}

/// 内置的分享配置获取和解析类
final class ShareDynamicConfigurationParser: ShareConfigurationProvider {
    private let shareDynamicAPI: ShareDynamicAPI?
    private typealias _Self = ShareDynamicConfigurationParser
    private static let logger = Logger.log(ShareDynamicConfigurationParser.self, category: "LarkSnsShare")

    init(shareDynamicAPI: ShareDynamicAPI?) {
        self.shareDynamicAPI = shareDynamicAPI
    }

    func parse(traceId: String) -> Observable<ShareDynamicConfiguration> {
        if traceId.isEmpty {
            return .error(DynamicConfParseError.traceIdNotFound)
        }
        return fetchDynamicConfigurations(traceId: traceId).flatMap { [weak self] (traceId2conf) -> Observable<ShareDynamicConfiguration> in
            guard let dynamicConfiguration = traceId2conf[traceId] else {
                return .error(DynamicConfParseError.traceIdNotFound)
            }

            var new = dynamicConfiguration
            // 如果被 ban，则自动删除对应的 item
            let bans = new.answerTypeMapping.filter { (keyValue) -> Bool in
                return keyValue.value == .ban
            }
            var filterItems = new.items.filter { (item) -> Bool in
                return !bans.contains(where: { (kv) -> Bool in
                    return kv.key == item
                })
            }
            // 约定：如果只有 systemShare 一项，直接置空，让上层走兜底逻辑
            if filterItems.count == 1 && filterItems.contains(.systemShare) {
                filterItems = []
            }
            new.items = filterItems

            guard self?.checkConfiguration(new) ?? false else {
                return .error(DynamicConfParseError.illegalConfigurationStruct)
            }

            // 应用瘦身要求，海外跟国内依赖的分享SDK不同，所以这里需要额外过滤掉包环境内不支持的sns渠道
            self?.filterByShareSlimming(&new)

            return .just(new)
        }
        .observeOn(MainScheduler.instance)
        .do(onNext: { (conf) in
            _Self.logger.info("[LarkSnsShare] traceId = \(traceId), dynamicConfiguration = \n\(conf)")
        }, onError: { (error) in
            _Self.logger.error(
                """
                [LarkSnsShare] parse dynamic share configuration failed,
                err = \(error.localizedDescription)
                """
            )
        })
    }
}

private extension ShareDynamicConfigurationParser {
    func fetchDynamicConfigurations(traceId: String) -> Observable<[String: ShareDynamicConfiguration]> {
        _Self.logger.info("LarkSnsShare start fetch dynamic configuration")

        return shareDynamicAPI?.fetchDynamicConfigurations(fields: [ParserRequestAgreement.field])
            .do(onNext: { (fieldGroups) in
                _Self.logger.info("[LarkSnsShare] raw settings v3 sns share configuration = \n\(fieldGroups)")
            })
            .catchError({ (_) -> Observable<[String: String]> in
                return .error(DynamicConfParseError.fetchFailed)
            })
            .flatMap { (fieldGroups) -> Observable<[String: ShareDynamicConfiguration]> in
                var traceId2confs: [String: ShareDynamicConfiguration] = [:]
                // 这里不做复杂过滤和限制，只做解析工作
                guard let jsonString = fieldGroups[ParserRequestAgreement.field],
                   let data = jsonString.data(using: .utf8),
                   let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    return .error(DynamicConfParseError.parseFailed)
                }

                for (key, value) in jsonDict {
                    guard var configurationDict = value as? [String: Any] else {
                        return .error(DynamicConfParseError.parseFailed)
                    }

                    // 需要判断 KA 多渠道
                    let currReleaseChannel = ReleaseConfig.releaseChannel
                    if let hasMultiChannel = configurationDict[ParserResponseAgreement.multiChannel] as? Bool,
                       hasMultiChannel {
                        configurationDict = configurationDict[currReleaseChannel] as? [String: Any] ?? [:]
                    }

                    let panelItems: [PanelItem] = (configurationDict[ParserResponseAgreement.items] as? [String] ?? []).map { return .transform(rawValue: $0) }
                    var answerTypeMapping: [PanelItem: AnswerType] = [:]
                    if let item2answers = configurationDict[ParserResponseAgreement.answerTypes] as? [String: String] {
                        for (k, v) in item2answers {
                            if k.isEmpty || v.isEmpty {
                                continue
                            }
                            answerTypeMapping[PanelItem.transform(rawValue: k)] = AnswerType.bestMatch(k, v)
                        }
                    }

                    let dynamicConf = ShareDynamicConfiguration(
                        traceId: key,
                        items: panelItems,
                        answerTypeMapping: answerTypeMapping
                    )
                    traceId2confs[key] = dynamicConf
                }

                return .just(traceId2confs)
            }
            .do(onNext: { (traceId2confs) in
                _Self.logger.info("[LarkSnsShare] raw traceId2dynamicConfigurations = \n\(traceId2confs)")
            }, onError: { (error) in
                _Self.logger.error(
                    """
                    [LarkSnsShare] fetch dynamic share configuration failed,
                    err = \(error.localizedDescription)
                    """
                )
            }) ?? .empty()
    }

    func checkConfiguration(_ conf: ShareDynamicConfiguration) -> Bool {
        return
            !Array(conf.answerTypeMapping.values).contains(.unknown)
            &&
            !conf.items.map { $0.toShareItem() }.contains(.unknown)
    }

    func filterByShareSlimming(_ conf: inout ShareDynamicConfiguration) {
        conf.items = conf.items.filter { (panelItem) -> Bool in
            ShareSlimming.currentWhitelist().contains(panelItem.toShareItem())
        }
    }
}

extension AnswerType {
    // 由于配置平台支持`或`运算操作符，这里需要匹配到最优策略
    static func bestMatch(_ rawItem: String, _ rawAnswerType: String) -> AnswerType {
        if rawAnswerType.contains("|") {
            var answerTypes = rawAnswerType.components(separatedBy: "|").map { (raw) -> AnswerType in
                return AnswerType.transform(rawValue: raw.replacingOccurrences(of: " ", with: "", options: .regularExpression))
            }
            // 特例：目前 iOS weibo SDK 暂不支持直接唤醒
            // 但为了兼容安卓，组件在内部会自动转换成`系统分享`的降级策略
            if PanelItem.transform(rawValue: rawItem) == .weibo {
                answerTypes = answerTypes.map { (type) -> AnswerType in
                    if type == .downgradeToWakeupByTip {
                        return .downgradeToSystemShare
                    }
                    return type
                }
            }
            return answerTypes.first { (type) -> Bool in
                return type != .unknown
            } ?? .unknown
        } else {
            // 特例：目前 iOS weibo SDK 暂不支持直接唤醒
            // 但为了兼容安卓，组件在内部会自动转换成`系统分享`的降级策略
            if PanelItem.transform(rawValue: rawItem) == .weibo {
                let type = AnswerType.transform(rawValue: rawAnswerType)
                if type == .downgradeToWakeupByTip {
                    return .downgradeToSystemShare
                }
            }
            return AnswerType.transform(rawValue: rawAnswerType)
        }
    }
}
