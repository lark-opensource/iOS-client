//
//  MinutesInstanceRegistry.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/3/24.
//

import Foundation
import LKCommonsLogging

final public class MinutesInstanceRegistry {

    static let logger = Logger.log(MinutesInstanceRegistry.self, category: "Minutes")

    typealias MinutesGetter = () -> Minutes?

    var registry: [String: MinutesGetter] = [:]

    public static let shared = MinutesInstanceRegistry()

    public func findMinutes(for token: String) -> Minutes? {
        if let getter = registry[token], let minutes = getter() {
            Self.logger.debug("get \(minutes) for \(token.suffix(6))")
            return minutes
        } else {
            Self.logger.debug("clean \(token.suffix(6))")
            registry[token] = nil
            return nil
        }
    }

    public func register(_ minutes: Minutes) {
        let token = minutes.objectToken
        registry[token] = { [weak minutes] in return minutes }
        Self.logger.debug("register \(minutes) for \(token.suffix(6))")
    }
}
