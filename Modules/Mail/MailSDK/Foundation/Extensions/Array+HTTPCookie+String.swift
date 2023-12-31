import Foundation

extension Array where Element: HTTPCookie {
    var cookieString: String {
        return self.map({ (cookie) -> String in
            return "\(cookie.name)=\(cookie.value)"
        }).joined(separator: ";")
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Array {
    // 去重
    func filterDuplicates<E: Equatable>(_ filter: (Element) -> E) -> [Element] {
        var result = [Element]()
        for value in self {
            let key = filter(value)
            if !result.map({ filter($0) }).contains(key) {
                result.append(value)
            }
        }
        return result
    }

    func splitArray(withSubsize subsize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: subsize).map {
            Array(self[$0 ..< Swift.min($0 + subsize, self.count)])
        }
    }
}
