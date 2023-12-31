//
//  SearchSource.swift
//  LarkSearch
//
//  Created by SolaWing on 2020/6/2.
//

import Foundation
import LarkModel
import RxSwift
import LarkSDKInterface
import LarkSearchFilter
import RustPB

/// a search source is responsible get search response from request
public protocol SearchSource {
    /// Source识别标识，主要是日志和统计用
    var identifier: String { get }
    /// 该Sources支持哪些可被用户配置的Filters. UI可参考提供相应的配置UI
    /// 不支持用户定制的参数不放到supportedFilters中
    var supportedFilters: [SearchFilter] { get }
    /// 搜索源核心API
    /// search应该在subscribe时真正执行, 且考虑支持Cancel
    /// 如果Observable返回多次结果，应该标明Results应该是增加还是替换之前的结果
    func search(request: SearchRequest) -> Observable<SearchResponse>
}

public protocol SearchRequest {
    /// 用户输入的原始query
    var query: String { get }
    /// 用户选择的filters
    var filters: [SearchFilter] { get }
    /// 用户请求的数据条数. 0代表未设置，Source可使用自己的默认设置
    /// NOTE: Source不一定使用这个字段，以实际返回为准
    var count: Int { get }
    /// 当加载更多时，需要把之前Response给的moreToken, 原样返回给Source以做更多加载的数据判断
    /// 首屏加载时应该传nil
    var moreToken: Any? { get }
    /// additional infomation pass to source from caller
    var context: SearchRequestContext { get }
    var pageInfos: [SearchRequestPageInfo] { get }
    var isQueryTemplate: Bool { get }
}

extension SearchRequest {
    /// will assert more token as given type. or nil
    func assertMoreToken<T>() -> T? {
        return moreToken as! T? // swiftlint:disable:this all
    }
}

/// 用来传递动态的配置参数到Source。后续filters也可能合进来存储
/// 动态容器可以隔离静态范形的传染性带来的麻烦
@frozen
public struct SearchRequestContext: Sequence {
    private var _hash = [AnyHashable: Any]()
    public init() {}
    /// use associated value as key, eg: KeyPath
    public subscript<K>(key: K) -> K.Value? where K: SearchRequestContextKey & Hashable {
        get {
            _hash[key] as? K.Value
        }
        set {
            _hash[key] = newValue
        }
    }
    /// use type as key to get value
    public subscript<K>(key: K.Type) -> K.Value? where K: SearchRequestContextKey {
        get {
            _hash[TypeKey(type: key)] as? K.Value
        }
        set {
            _hash[TypeKey(type: key)] = newValue
        }
    }
    public func makeIterator() -> Dictionary<AnyHashable, Any>.Iterator { _hash.makeIterator() }
}

/// use to assign dynamic value from dynamic type WritableKeyPath
public protocol WritableKeyPathUpdater {
    /// assign value to root, return true if success.
    @discardableResult
    func tryAssign<Root>(value: Any, to: inout Root) -> Bool
}

extension WritableKeyPath: WritableKeyPathUpdater, SearchRequestContextKey {
    public func tryAssign<Root>(value: Any, to: inout Root) -> Bool {
        if let value = value as? Value, let kp = self as? WritableKeyPath<Root, Value> {
            to[keyPath: kp] = value
            return true
        }
        return false
    }
}

public enum SearchError: Int32 {
    case serverError = 100_012
    case offline = 100_052
    case timeout = 100_054
}

/// 搜索源回应数据，给上层调用者使用
public protocol SearchResponse {
    // NOTE: 这里没使用泛形，若使用，会依次传染Source，依赖Source的VM，上层的Binder等都需要指定泛型，
    // 比较繁琐，影响易用性。

    /// 本次请求返回的数据
    var results: [SearchItem] { get }
    /// 暂定: 多次返回时结果的合并处理策略
    var resultType: SearchResponseResultType { get }
    /// 加载more需要的token。调用方加载More时，会透传回Source.
    /// 比如记录lastObject的ID，或者记录offset.
    /// 返回nil代表没有更多数据
    /// @see SearchRequest.moreToken
    var moreToken: Any? { get }
    var hasMore: Bool { get }
    /// 用于保存一些额外的Response信息，透传给消费端
    var context: SearchResponseContext { get }
    /// rust 层会返回一些错误
    var searchError: SearchError? { get }
    /// 返回是否可请求冷热数据
    var secondaryStageSearchable: Bool? { get }
    /// 保存Response的错误信息
    var errorInfo: Search_V2_SearchCommonResponseHeader.ErrorInfo? { get }
    /// server返回的错误
    var errorCode: Int32? { get }
}

/// 多次返回Response时，和之前的结果合并策略控制
/// FIXME: 现在还没用上这个字段，只是预留，正式使用时需要多确认
public enum SearchResponseResultType {
    /// 新结果添加到旧结果后面，对应流式增量返回数据
    case append
    /// 丢弃本次请求之前返回的结果. 如果是加载更多，之前请求的结果不受影响
    case replace
}

extension SearchResponse {
    public var resultType: SearchResponseResultType { .append }
}

public protocol SearchRequestContextKey {
    associatedtype Value
}

public typealias SearchResponseContextKey = SearchRequestContextKey

/// a context for store SearchResponseContext infomation
/// also recommend create Key type in this struct namespace
public typealias SearchResponseContext = SearchRequestContext

extension SearchItem where Self: AnyObject {
    public var identifier: String? { String(describing: ObjectIdentifier(self)) }
}

// MARK: Basic protocol implment
public struct BaseSearchRequest: SearchRequest {
    public var query: String
    public var filters: [SearchFilter]
    public var count: Int
    public var moreToken: Any?
    public var context: SearchRequestContext
    public var pageInfos: [SearchRequestPageInfo]
    public var isQueryTemplate: Bool

    public init(query: String,
                filters: [SearchFilter] = [],
                count: Int = 0,
                moreToken: Any? = nil,
                context: SearchRequestContext = SearchRequestContext(),
                pageInfos: [SearchRequestPageInfo] = [],
                isQueryTemplate: Bool = false) {
        self.query = query
        self.filters = filters
        self.count = count
        self.moreToken = moreToken
        self.context = context
        self.pageInfos = pageInfos
        self.isQueryTemplate = isQueryTemplate
    }
    public init(from: SearchRequest) {
        query = from.query
        filters = from.filters
        count = from.count
        moreToken = from.moreToken
        context = from.context
        pageInfos = from.pageInfos
        isQueryTemplate = from.isQueryTemplate
    }
}

public struct SearchRequestPageInfo {
    public var clusteringType: RustPB.Search_V2_ClusteringType
    public var pageSize: Int32
    public init(clusteringType: RustPB.Search_V2_ClusteringType, pageSize: Int32) {
        self.clusteringType = clusteringType
        self.pageSize = pageSize
    }
}
public struct BaseSearchResponse: SearchResponse {
    public var results: [SearchItem]
    public var suggestionInfo: Search_V2_SuggestionInfo?
    public var moreToken: Any?
    public var hasMore: Bool
    public var searchError: SearchError?
    public var resultType: SearchResponseResultType
    public var context: SearchResponseContext
    public var secondaryStageSearchable: Bool?
    public var errorInfo: Search_V2_SearchCommonResponseHeader.ErrorInfo?
    public var errorCode: Int32? /// 部分结果认为success的场景可能也会返回errorcode，但是searchError只会在结果error时才会返回

    public init(results: [SearchItem],
                moreToken: Any?,
                hasMore: Bool,
                searchError: SearchError?,
                suggestionInfo: Search_V2_SuggestionInfo? = nil,
                resultType: SearchResponseResultType = .append,
                context: SearchResponseContext = SearchResponseContext(),
                secondaryStageSearchable: Bool? = nil) {
        self.results = results
        self.moreToken = moreToken
        self.hasMore = hasMore
        self.searchError = searchError
        self.suggestionInfo = suggestionInfo
        self.resultType = resultType
        self.context = context
        self.secondaryStageSearchable = secondaryStageSearchable
    }
    public init(from: SearchResponse) {
        results = from.results
        moreToken = from.moreToken
        hasMore = from.hasMore
        resultType = from.resultType
        context = from.context
        secondaryStageSearchable = from.secondaryStageSearchable
    }
}

// MARK: Helper
@usableFromInline
struct TypeKey: Hashable {
    public static func == (lhs: TypeKey, rhs: TypeKey) -> Bool {
        lhs.type == rhs.type
    }
    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(type).hash(into: &hasher)
    }
    @usableFromInline var type: Any.Type
}
