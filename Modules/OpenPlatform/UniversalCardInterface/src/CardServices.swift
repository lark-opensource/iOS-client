//
//  CardServices.swift
//  UniversalCardInterface
//
//  Created by ByteDance on 2023/8/17.
//

import Foundation
public protocol UniversalCardLayoutServiceProtocol {
    func layout(
        layoutConfig: UniversalCardLayoutConfig,
        source: (data: UniversalCardData, context: UniversalCardContext, config: UniversalCardConfig)
    ) -> CGSize
}
