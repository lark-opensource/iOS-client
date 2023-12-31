//
//  UniversalCardLayoutService.swift
//  UniversalCard
//
//  Created by ByteDance on 2023/8/17.
//

import Foundation
import LarkOPInterface
import LKCommonsLogging
import LarkContainer
import UniversalCardInterface

// 算高通用容器
public class UniversalCardLayoutService: UniversalCardLayoutServiceProtocol {
    private static let logger = Logger.log(UniversalCardLayoutService.self, category: "UniversalCardLayoutService")
    private var _layoutCard: UniversalCard? = nil

    private let lock: NSLock = NSLock()

    private let contextKey = "UniversalCardLayoutService" + UUID().uuidString

    private let resolver: UserResolver

    private func getLayoutCard() -> UniversalCard {
        lock.lock(); defer { lock.unlock() }
        guard let layoutCard = _layoutCard else {
            let layoutCard = UniversalCard.create(resolver: resolver)
            self._layoutCard = layoutCard
            return layoutCard
        }
        return layoutCard
    }

    public init(resolver: UserResolver) {
        self.resolver = resolver
    }

    public func layout(
        layoutConfig: UniversalCardLayoutConfig,
        source: (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig)
    ) -> CGSize {
        var size: CGSize = .zero
        var source = source
        let context = UniversalCardContext(
            key: contextKey,
            trace: OPTraceService.default().generateTrace(),
            sourceData: source.data,
            sourceVC: nil,
            dependency: nil,
            renderBizType: source.context.renderBizType,
            bizContext: nil
        )
        let calculateLayout = { [weak self] in
            source.config.isInformal = true
            source.context = context
            guard let layoutCard = self?.getLayoutCard() else {
                Self.logger.error("layout fail because self is nil")
                return
            }
            layoutCard.render(layout: layoutConfig, source: source, lifeCycle: nil, force: true)
            size = layoutCard.getContentSize()
        }

        if Thread.isMainThread {
            calculateLayout()
        } else {
            DispatchQueue.main.sync { calculateLayout() }
        }
        return size
    }
}
