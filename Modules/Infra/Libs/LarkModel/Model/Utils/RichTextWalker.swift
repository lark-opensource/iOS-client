//
//  RichTextWalker.swift
//  LarkModel
//
//  Created by qihongye on 2018/3/26.
//  Copyright © 2018年 qihongye. All rights reserved.
//

import Foundation
import RustPB

public struct RichTextWalkerOption<T> {
    public var elementId: String
    public var element: RustPB.Basic_V1_RichTextElement
    public var parentElement: RustPB.Basic_V1_RichTextElement?
    public var results: [T]
}

public typealias RichTextOptionsType<T> = (RichTextWalkerOption<T>) -> [T]
public typealias AttributedStringOptionType = RichTextOptionsType<NSMutableAttributedString>
public typealias StringOptionType = RichTextOptionsType<String>

public struct RichTextWalker {
    public static func walker<T>(
        richText: RustPB.Basic_V1_RichText,
        options: [RustPB.Basic_V1_RichTextElement.Tag: RichTextOptionsType<T>],
        endCondition: () -> Bool = { false }
    ) -> [T] {
        // swiftlint:disable nesting
        typealias WalkNode = (id: String, element: RustPB.Basic_V1_RichTextElement, childIdx: Int, result: [T])
        // swiftlint:enable nesting
        return richText.elementIds.flatMap { (id) -> [T] in
            guard let element = richText.elements[id] else { return [] }

            var results: [T] = []
            var stack: [WalkNode] = [(id, element, 0, [])]
            // deep traversal algorithm，深度遍历算法
            while var node = stack.popLast() {
                // processing child elements of the current node if needed
                // 如果还有子节点未处理，则根据截断条件判断是否需要处理该子节点
                if node.childIdx < node.element.childIds.count, !endCondition() {
                    let elementId = node.element.childIds[node.childIdx]
                    guard let element = richText.elements[node.element.childIds[node.childIdx]] else { return [] }

                    node.childIdx += 1
                    stack.append(node)
                    stack.append((elementId, element, 0, []))
                    continue
                }
                // processing nodes that are truncated or have no child elements
                // 处理子节点被截断或者无子节点的节点，所以有子节点的父节点都会参与计算
                guard let process = options[node.element.tag] else { continue }
                let option = RichTextWalkerOption(
                    elementId: node.id,
                    element: node.element,
                    parentElement: stack.last?.element,
                    results: node.result
                )
                results = process(option)
                // processing result stored in the parent node
                // 处理结果存入父节点result中
                if !stack.isEmpty {
                    stack[stack.count - 1].result += results
                }
            }

            return results
        }
    }
}
