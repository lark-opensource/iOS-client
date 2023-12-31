import Foundation

public extension String {
    /// 实现模糊匹配函数，接收一个过滤字符串作为参数，返回一个可选的字符串索引数组
    ///
    /// - Parameter filter: 待匹配的 key
    /// - Returns: 模糊匹配的 index 数组，未匹配到则返回 nil；
    ///     注意：默认任意穿都匹配空串，所以当传入的 `filter` 为空字符串时返回空数组表示匹配。
    ///
    /// 当前该方法用于多个Debug页面替换NSPredicate以提升搜索效率，另外也可以借助返回值实现高亮
    func fuzzyMatch(_ filter: String) -> [String.Index]? {
        var indexs: [Index] = []
        if filter.isEmpty { return [] }

        var remainder = filter[...].utf8
        for index in utf8.indices {
            let char = utf8[index]
            if char == remainder[remainder.startIndex] {
                indexs.append(index)
                remainder.removeFirst()
                if remainder.isEmpty { return indexs }
            }
        }
        return nil
    }

    @inlinable func fuzzyMatch(_ filter: String) -> Bool { fuzzyMatch(filter) != nil }
}
