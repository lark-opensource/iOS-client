//
//  ComponentBuilder.swift
//  ComponentDemo
//
//  Created by Rico on 2021/9/15.
//

import Foundation

@resultBuilder
public struct ComponentBuilder {

    public static func buildBlock(_ components: [ComponentType]...) -> [ComponentType] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [ComponentType]?) -> [ComponentType] {
        component ?? []
    }

    public static func buildEither(first component: [ComponentType]) -> [ComponentType] {
        component
    }

    public static func buildEither(second component: [ComponentType]) -> [ComponentType] {
        component
    }

    public static func buildArray(_ components: [[ComponentType]]) -> [ComponentType] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: ComponentType?) -> [ComponentType] {
        if let expr = expression {
            return [expr]
        }
        return []
    }

    public static func buildExpression(_ expression: ComponentType) -> [ComponentType] {
        [expression]
    }

}
