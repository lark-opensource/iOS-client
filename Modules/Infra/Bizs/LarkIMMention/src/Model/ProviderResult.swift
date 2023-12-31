import Foundation

struct ProviderResult: CustomStringConvertible {
    /// 加载器固定返回数据类型
    /// 人员tab: 第一组为可能@的人, 第二组为群内, 第三组为群外
    var result: [[IMMentionOptionType]]
    var hasMore: Bool
    
    var isEmpty: Bool {
        return result.reduce(0, { $0 + $1.count }) == 0
    }
    
    var description: String {
        return "count: \(result.map { $0.count }), hasMore: \(hasMore)"
    }
}

enum ProviderError: Error {
    case none
    case noSearchResult
    case noRecommendResult
    case request(Error)
}

enum ProviderEvent: CustomStringConvertible {
    struct Response {
        var query: String?
        var res: ProviderResult
        var isShowPrivacy: Bool = false
        
        static func empty(query: String? = nil, hasMore: Bool = false) -> Response {
            return Response(query: query, res: ProviderResult(result: [], hasMore: hasMore))
        }
    }
    
    case startSearch(String?)
    case fail(ProviderError)
    case loading(String?)
    case success(Response)
    case complete
    
    var description: String {
        switch self {
        case .startSearch(let query): return "start search \(query ?? "")"
        case .fail(let e): return "fail \(e.localizedDescription)"
        case .loading(let query): return "loading \(query ?? "")"
        case .success(let res): return "query: \(res.query ?? ""), results: \(res.res)"
        case .complete: return "complete"
        }
    }
}
