import Foundation
import LKCommonsLogging
let urlHelperlogger = Logger.lkwlog(URL.self, category: "URLHelper")
public extension URL {
    /// 判断 url 中是否有 ResourceID 标记
    internal func hasResourceID() -> Bool {
        if let fragment = fragment, !fragment.isEmpty {
            do {
                let regex = "(%5E|\\^){4}[0-9a-zA-Z_-]+(%5E|\\^){4}"
                let re0 = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
                // 查找标记
                return re0.firstMatch(in: fragment, options: [], range: NSMakeRange(0, fragment.count)) != nil
            } catch {
                urlHelperlogger.error("hasResourceID error", error: error)
            }
        }
        return false
    }
    /// 提取 url 中的 ResourceID 标记并且移除标记还原 URL
    ///   "https://x.y" -> "https://x.y#^^^^{resourceID}^^^^" -> ({resourceID}, "https://x.y")
    ///   "https://x.y#" -> "https://x.y#^^^^X{resourceID}^^^^" -> ({resourceID}, "https://x.y#")
    ///   "https://x.y#X" -> "https://x.y#X^^^^X{resourceID}^^^^" -> ({resourceID}, "https://x.y#X")
    /// - Returns: (resourceID, originURL)
    internal func parseURLResourceID() -> (String?, URL) {
        var replaceID: String?
        var newURL: URL?
        if let fragment = fragment, !fragment.isEmpty {
            do {
                let regex = "(%5E|\\^){4}[0-9a-zA-Z_-]+(%5E|\\^){4}"
                let re0 = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
                // 查找标记
                if let match = re0.firstMatch(in: fragment, options: [], range: NSMakeRange(0, fragment.count)) {
                    // 获取标记内容
                    let replaceIDTag = (fragment as NSString).substring(with: match.range)
                    
                    // 尝试从标记中读取 replaceID 内容（删除非内容部分）
                    let regex = "((^(%5E|\\^){4})|((%5E|\\^){4})$)"
                    let re1 = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
                    replaceID = re1.stringByReplacingMatches(in: replaceIDTag, options: [], range: NSMakeRange(0, replaceIDTag.count), withTemplate: "")
                    // 移除标记并获得新 fragment
                    let newFragment = re0.stringByReplacingMatches(in: fragment, options: [], range: NSMakeRange(0, fragment.count), withTemplate: "")
                    // 如果 replaceID 以 X 开头，说明组装 URL 的时候，已经自带了 #，因此还原 URL 的时候，不需要移除已有的 #
                    let fragmentFixTag = "X"
                    // 组装新的去除标记后的新 URL
                    if var urlComponent = URLComponents(url: self, resolvingAgainstBaseURL: false) {
                        if newFragment.isEmpty, replaceID?.starts(with: fragmentFixTag) != true {
                            // 对于这种情况，要移除 #
                            urlComponent.fragment = nil
                        } else {
                            urlComponent.fragment = newFragment
                        }
                        newURL = urlComponent.url
                    }
                    // 对于以 X 开头的 replaceID，要移除 X
                    if let tReplaceID = replaceID, tReplaceID.starts(with: fragmentFixTag) {
                        replaceID = String(tReplaceID[tReplaceID.index(after: tReplaceID.startIndex)...])
                    }
                }
            } catch {
                urlHelperlogger.error("parseURLResourceID error", error: error)
            }
        }
        return (replaceID, newURL ?? self)
    }
    
    func getQuery() -> [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }
        guard let queryItems = components.queryItems else {
            return nil
        }
        var results = [String: String]()
        for item in queryItems {
            if let value = item.value {
                results[item.name] = value
            }
        }
        return results
    }
}
