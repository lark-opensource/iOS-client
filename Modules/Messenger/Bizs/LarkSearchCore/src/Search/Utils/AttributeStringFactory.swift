//
//  AttributeStringFactory.swift
//  LarkListItem
//
//  Created by Yuri on 2023/5/29.
//

import Foundation
import RustPB
import UniverseDesignIcon
import LarkListItem

public class AttributeStringFactory {
    static let shared = AttributeStringFactory()

    func convert(xml: String) -> NSAttributedString {
        assert(Thread.isMainThread, "should occur on main thread!")
        if let result = cache.getValue(forKey: xml) {
            return result
        }
        let attrText = SearchAttributeString(searchHighlightedString: xml).attributeText
        cache.setValue(attrText, forKey: xml)
        return attrText
    }
    let cache = LRUCache<String, NSAttributedString>(capacity: 100)

    func clean() {
        cache.clean()
    }

    class LRUCache<Key: Hashable, Value> {
        private let capacity: Int
        private var cache = [Key: Value]()
        private var keys = [Key]()

        init(capacity: Int) {
            self.capacity = capacity
        }

        func setValue(_ value: Value, forKey key: Key) {
            if cache[key] == nil {
                keys.append(key)
            }

            cache[key] = value

            if keys.count > capacity {
                let keyToRemove = keys.removeFirst()
                cache[keyToRemove] = nil
            }
        }

        func getValue(forKey key: Key) -> Value? {
            if let value = cache[key] {
                if let index = keys.firstIndex(of: key) {
                    keys.remove(at: index)
                    keys.append(key)
                }
                return value
            }
            return nil
        }

        func clean() {
            cache.removeAll()
        }
    }
}
