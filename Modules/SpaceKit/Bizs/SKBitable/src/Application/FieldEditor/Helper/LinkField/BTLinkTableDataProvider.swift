//
//  BTLinkTableDataProvider.swift
//  SKBitable
//
//  Created by yinyuan on 2023/11/7.
//

import SKFoundation
import SKInfra
import SKCommon

enum LinkTableError: Error, CustomStringConvertible {
    case invalidResponse
    case invalidResponseData
    case invalidLinkContent
    case tableNotFound(code: Int, msg: String)
    case noPermission(code: Int, msg: String)
    case unknownError(code: Int, msg: String)
    
    var description: String {
        switch self {
        case .invalidResponse:
            return "LinkTableError.invalidResponse"
        case .invalidResponseData:
            return "LinkTableError.invalidResponseData"
        case .invalidLinkContent:
            return "LinkTableError.invalidLinkContent"
        case .tableNotFound(let code, let msg):
            return "LinkTableError.tableNotFound(\(code),\(msg)"
        case .noPermission(let code, let msg):
            return "LinkTableError.noPermission(\(code),\(msg)"
        case .unknownError(code: let code, msg: let msg):
            return "LinkTableError.unknownError(\(code),\(msg)"
        }
    }
}

struct LinkContentResponse: SKFastDecodable {
    
    enum Code: Int {
        case tableNotFound = 800004000
        case fieldTypeNotMatch = 600004601
        case noRecordPerm = 800004011
        case noTablePermission = 600014041
        case noTablePermission2 = 800008006
    }
    
    var code: Int?
    var msg: String?
    var data: LinkContentData?
    
    static func deserialized(with dictionary: [String : Any]) -> Self {
        var model = Self.init()
        model.code <~ (dictionary, "code")
        model.msg <~ (dictionary, "msg")
        model.data <~ (dictionary, "data")
        return model
    }
}

struct LinkContentData: SKFastDecodable {
    
    var offset: String?
    var hasMore: Bool = false
    var linkContent: String?
    var linkTableName: String?
    
    static func deserialized(with dictionary: [String : Any]) -> Self {
        var model = Self.init()
        model.offset <~ (dictionary, "offset")
        model.hasMore <~ (dictionary, "hasMore")
        model.linkContent <~ (dictionary, "linkContent")
        model.linkTableName <~ (dictionary, "linkTableName")
        return model
    }
}

struct LinkRecord {
    var recordID: String
    var primaryValue: String
}

struct LinkContent: SKFastDecodable {
    
    var primaryValue: [String: String] = [:]
    var primaryFieldType: Int?
    var recordIDs: [String] = []
    
    static func deserialized(with dictionary: [String : Any]) -> Self {
        var model = Self.init()
        model.primaryValue <~ (dictionary, "primaryValue")
        model.primaryFieldType <~ (dictionary, "primaryFieldType")
        model.recordIDs <~ (dictionary, "recordIDs")
        return model
    }
}

enum LinkTableLoadStatus {
    case paused                   // 暂停拉取
    case loading                  // 正在拉取
    case failed(error: Error)     // 拉取失败
    case finished                 // 拉取完成
}

protocol BTLinkTableDataProviderDelegate: AnyObject {
    func dataUpdate(linkTableName: String?, records: [LinkRecord], hasMore: Bool, loadStatus: LinkTableLoadStatus)
}

class BTLinkTableDataProvider {
    
    weak var delegate: BTLinkTableDataProviderDelegate?
    
    private var request: DocsRequest<Any>? // 必须持有住，不然还没请求就自己释放了
    // 关联字段所在 Base
    private let baseToken: String
    // 关联字段所在表（并不是被关联表）
    private let tableID: String
    // 关联字段 fieldID
    private let fieldID: String
    
    private var offset: String?
    private(set) var records: [LinkRecord] = []
    private(set) var hasMore: Bool = true
    private(set) var linkTableName: String?
    
    private(set) var loadStatus: LinkTableLoadStatus = .paused
    
    private var searchKeyWord: String = ""
    
    init(baseToken: String, tableID: String, fieldID: String) {
        self.baseToken = baseToken
        self.tableID = tableID
        self.fieldID = fieldID
    }
    
    func reset() {
        DocsLogger.btInfo("[BTLinkTableDataProvider] reset")
        searchKeyWord = ""
    }
    
    func reload() {
        DocsLogger.btInfo("[BTLinkTableDataProvider] reload")
        // 重置属性
        records = []
        offset = nil
        hasMore = true
        loadStatus = .paused
        
        resume(onece: true)
    }
    
    // 暂停
    func pause() {
        DocsLogger.btInfo("[BTLinkTableDataProvider] pause")
        guard searchKeyWord.isEmpty else {
            // 搜索模式自动拉取所有记录，不支持暂停
            DocsLogger.btInfo("[BTLinkTableDataProvider] pause return for searchKeyWord.isEmpty")
            return
        }
        guard case .loading = loadStatus else {
            // 只有正在加载的过程可以被暂停
            DocsLogger.btInfo("[BTLinkTableDataProvider] pause return for not loading")
            return
        }
        // 设置为 paused 后，将不会再继续请求下一页
        self.loadStatus = .paused
    }
    
    func search(keyWord: String) {
        DocsLogger.btInfo("[BTLinkTableDataProvider] search:\(keyWord.count)")
        self.searchKeyWord = keyWord
        resume()
        dataUpdate()
    }
    
    /// 恢复
    /// onece 是否只请求一次
    func resume(onece: Bool = false) {
        DocsLogger.btInfo("[BTLinkTableDataProvider] resume onece:\(onece)")
        if case .loading = loadStatus {
            // 只有已经暂停状态可以恢复
            DocsLogger.btInfo("[BTLinkTableDataProvider] resume return for loading")
            return
        }
        if case .finished = loadStatus {
            // 只有已经暂停状态可以恢复
            // 已经加载完成就直接回调数据
            DocsLogger.btInfo("[BTLinkTableDataProvider] resume return for finished")
            dataUpdate()
            return
        }
        requetsMoreLinkContent(offset: offset)
        if onece {
            // 恢复请求后马上再 pause 掉
            pause()
        }
    }
    
    private func requetsMoreLinkContent(offset: String?) {
        // 单页 200 条记录
        let pageSize: Int = 200
        DocsLogger.btInfo("requetsMoreLinkContent offset:\(offset ?? "") pageSize:\(pageSize)")
        let path = OpenAPI.APIPath.getBaseLinkContent(baseToken)
        var params: [String: Any] = [
            "tableID": self.tableID,
            "fieldID": self.fieldID,
            "pageSize": pageSize,
        ]
        if let offset = offset {
            params["offset"] = offset
        }
        let request = DocsRequest<Any>(path: path, params: params)
            .set(method: .GET)
        self.request = request
        self.loadStatus = .loading
        request.start { (data, response, error) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                if let error = error {
                    self.handleLinkContentResponse(error: error)
                    return
                }
                guard let data = data else {
                    self.handleLinkContentResponse(error: DocsNetworkError.invalidData)
                    return
                }
                do {
                    let response = try LinkContentResponse.deserialized(with: data)
                    self.handleLinkContentResponse(response: response)
                } catch {
                    self.handleLinkContentResponse(error: error)
                }
            }
        }
    }
    
    private func handleLinkContentResponse(response: LinkContentResponse? = nil, error: Error? = nil) {
        if let error = error {
            handleError(error: error)
            return
        }
        guard let response = response else {
            handleError(error: LinkTableError.invalidResponse)
            return
        }
        guard response.code == 0 else {
            let code = response.code ?? 0
            if code == LinkContentResponse.Code.tableNotFound.rawValue 
                || code == LinkContentResponse.Code.fieldTypeNotMatch.rawValue
            {
                // table not found
                handleError(error: LinkTableError.tableNotFound(code: code, msg: response.msg ?? ""))
            } else if code == LinkContentResponse.Code.noRecordPerm.rawValue 
                        || code == LinkContentResponse.Code.noTablePermission.rawValue
                        || code == LinkContentResponse.Code.noTablePermission2.rawValue
            {
                // no permission
                handleError(error: LinkTableError.noPermission(code: code, msg: response.msg ?? ""))
            } else {
                handleError(error: LinkTableError.unknownError(code: code, msg: response.msg ?? ""))
            }
            return
        }
        guard let data = response.data else {
            handleError(error: LinkTableError.invalidResponseData)
            return
        }
        guard let linkContentStr = data.linkContent else {
            handleError(error: LinkTableError.invalidLinkContent)
            return
        }
        let linkContent: LinkContent
        do {
            linkContent = try LinkContent.deserialized(with: linkContentStr)
        } catch {
            handleError(error: error)
            return
        }
        self.linkTableName = data.linkTableName ?? self.linkTableName
        let newRecords = linkContent.recordIDs.map { recordID in
            LinkRecord(recordID: recordID, primaryValue: linkContent.primaryValue[recordID] ?? "")
        }
        records.append(contentsOf: newRecords)
        if data.hasMore {
            self.hasMore = true
            self.offset = data.offset
            if let offset = data.offset {
                if case .loading = loadStatus {
                    // 自动继续请求下一页
                    DocsLogger.btInfo("[BTLinkTableDataProvider] continue requetsMoreLinkContent")
                    requetsMoreLinkContent(offset: offset)
                }
            } else {
                // 异常状态，终止拉取，对外表现为已经拉取完成
                DocsLogger.btError("hasMode but offset is nil")
                self.hasMore = true
                self.loadStatus = .finished
            }
        } else {
            self.hasMore = false    // 数据拉取完成
            self.offset = nil
            self.loadStatus = .finished
        }
        // callback
        dataUpdate()
    }
    
    private func dataUpdate() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            var records = self.records
            if !self.searchKeyWord.isEmpty {
                records = records.filter({ record in
                    record.primaryValue.localizedStandardContains(self.searchKeyWord)
                })
            }
            DocsLogger.btInfo("[BTLinkTableDataProvider] dataUpdate records:\(records.count), hasMore: \(self.hasMore) loadStatus:\(self.loadStatus)")
            self.delegate?.dataUpdate(linkTableName: linkTableName, records: records, hasMore: self.hasMore, loadStatus: self.loadStatus)
        }
    }
    
    private func handleError(error: Error) {
        DocsLogger.error("BTLinkTableDataProvider.handleError", error: error)
        loadStatus = .failed(error: error)
        dataUpdate()
    }
}
