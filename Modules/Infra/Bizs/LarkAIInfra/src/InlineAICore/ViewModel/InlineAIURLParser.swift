//
//  InlineAIURLParser.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/10/30.
//  


import Foundation
import RustPB
import RxSwift
import RxCocoa
import LarkContainer
import LarkDocsIcon

protocol InlineAIURLRequest {
    func sendAsyncHttpRequest(token: String, type: CCMDocsType) -> Observable<[String: Any]?>
}

protocol InlineAIDocURLAnalysis {
    func getFileInfoNewFrom(_ url: URL) -> (token: String?, type: CCMDocsType?)
}

extension DocsIconRequest: InlineAIURLRequest {}
extension DocsUrlUtil: InlineAIDocURLAnalysis {}


protocol InlineAIURLParserDelegate: AnyObject {
    
    /// 返回解析文档URL的结果。如果没有文档URL，不会触发回调
    /// - Parameter result: 格式为`[token: [String: Any]]`
    func didFinishParse(result: [String: Any])
}

class InlineAIURLParser {
    
    struct ParseResult {

        var originToken: String
        var originType: CCMDocsType
        var url: URL
        
        var token: String
        var type: Int
        var title: String
    }
    
    struct DocURLInfo {
        var docToken: String
        var docType: CCMDocsType
        var url: URL
    }
    
    let disposeBag = DisposeBag()

    let regexString: String
    
    let docsIconRequest: InlineAIURLRequest

    let docsUrlUtil: InlineAIDocURLAnalysis
    
    /// 初始化比较耗时，存储起来
    lazy var regularExpression: NSRegularExpression? = {
        return try? NSRegularExpression(pattern: regexString, options: [])
    }()

    enum Status {
        case empty
        case downloading
        case success(ParseResult)
        case failure
    }
    
    /// 所有下载任务的状态
    var dowloadTask: [String: Status] = [:]
    
    /// 当前对话的状态
    var currentURLCache: [String: Status] = [:]
    
    weak var delegate: InlineAIURLParserDelegate?
    
    init(regexString: String,
        docsIconRequest: InlineAIURLRequest,
        docsUrlUtil: InlineAIDocURLAnalysis) {
        self.regexString = regexString
        self.docsIconRequest = docsIconRequest
        self.docsUrlUtil = docsUrlUtil
    }

    func mergeCurrentCache(infos: [DocURLInfo]) {
        var newCache: [String: Status] = [:]
        for info in infos {
            let key = getCacheKey(info.docToken)
            if let old = currentURLCache[key] {
                switch old {
                case .failure, .empty:
                    newCache[key] = .empty
                case .success, .downloading:
                    newCache[key] = old
                }
            } else {
                newCache[key] = .empty
            }
        }
        self.currentURLCache = newCache
    }
    
    func parse(with content: String) {
        let infos = transformToDocsInfo(with: content)
        guard !infos.isEmpty else {
            LarkInlineAILogger.info("[url] no url found")
            return
        }
        self.mergeCurrentCache(infos: infos)
        for info in infos {
            let cacheKey = getCacheKey(info.docToken)
            if let task = dowloadTask[cacheKey] {
                switch task {
                case .success: // 不用重复请求
                    checkFinalResult()
                    continue
                case .downloading: // 不用重复请求
                    continue
                case .failure: // 需要重新触发
                    break
                case .empty: // 新任务
                    self.updateDolowndResult(key: cacheKey, status: .downloading)
                }
            }
            self.requestDocsTitle(token: info.docToken, type: info.docType) { [weak self] title, token, type in
                guard let self = self else { return }
                let result = ParseResult(originToken: info.docToken, originType: info.docType, url: info.url, token: token, type: type, title: title)
                self.updateDolowndResult(key: cacheKey, status: .success(result))
                self.checkFinalResult()
            }
        }
    }
    
    func updateDolowndResult(key: String, status: Status) {
        self.dowloadTask[key] = status
        if self.currentURLCache[key] != nil { // 保证是当前content的url
            self.currentURLCache[key] = status
        }
    }
    
    func checkFinalResult() {
        var linkToMention: [String: Any] = [:]
        for (key, value) in self.currentURLCache {
            switch value {
            case .empty, .downloading:
                return
            case .success(let result):
                let info: [String: Any] = ["file_type": result.originType.rawValue,
                                           "icon_type": result.type,
                                           "token": result.token,
                                           "raw_url": result.url.absoluteString,
                                           "title": result.title]
                linkToMention[key] = info
            default:
                break
            }
        }
        if linkToMention.isEmpty {
            LarkInlineAILogger.info("[url] parse fail")
            return
        }
        LarkInlineAILogger.info("[url] parse success")
        LarkInlineAILogger.debug("[url] parse result: \(linkToMention)")
        self.delegate?.didFinishParse(result: linkToMention)
    }
    
    func regularUrlRanges(text: String) -> [NSRange] {
        let matches = regularExpression?.matches(in: text, range: NSRange(location: 0, length: text.utf16.count)) ?? []
        return matches.map { $0.range }
    }
    
    /// 解析content中的文档URL
    func transformToDocsInfo(with content: String) -> [DocURLInfo] {
        let text = content
        var result: [DocURLInfo] = []
        let ranges = regularUrlRanges(text: text)
        for range in ranges {
            guard let subStr = text.subString(with: range),
                  let url = URL(string: subStr) else {
                continue
            }
            let (docToken, docType) = self.docsUrlUtil.getFileInfoNewFrom(url)
            
            guard let docToken = docToken,
                  !docToken.isEmpty,
                  let docType = docType else {
                continue
            }
            result.append(DocURLInfo(docToken: docToken, docType: docType, url: url))
        }
        return result
    }
    
    private func getCacheKey(_ token: String) -> String {
        return token
    }
    
    private func requestDocsTitle(token: String, type: CCMDocsType, callback: @escaping (String, String, Int) -> Void) {
        let cacheKey = getCacheKey(token)
        self.updateDolowndResult(key: cacheKey, status: .downloading)
        LarkInlineAILogger.info("[url] requst url")
        docsIconRequest.sendAsyncHttpRequest(token: token, type: type)
                       .observeOn(MainScheduler.instance)
                       .subscribe { [weak self] response in
            guard let self = self else { return }
            guard let map = response else {
                LarkInlineAILogger.error("requestDocsTitle error")
                self.updateDolowndResult(key: cacheKey, status: .failure)
                return
            }
            guard let dataMap = map["data"] as? [String: Any] else {
                LarkInlineAILogger.error("requestDocsTitle data is nil")
                self.updateDolowndResult(key: cacheKey, status: .failure)
                return
            }
            var title = dataMap["title"] as? String ?? ""
            if title.isEmpty {
                title = type.untitledString
            }
            let type = dataMap["obj_type"] as? Int ?? 0
            let token = dataMap["token"] as? String ?? ""
            callback(title, token, type)
        }.disposed(by: disposeBag)
    }
}

extension CCMDocsType {
    
    
    /// 兜底文档名
    public var untitledString: String {
        var title = " "
        switch self {
        case .doc, .docX, .wiki, .wikiCatalog:
            title = BundleI18n.LarkAIInfra.Doc_Facade_UntitledDocument
        case .sheet:
            title = BundleI18n.LarkAIInfra.Doc_Facade_UntitledSheet
        case .folder:
            title = BundleI18n.LarkAIInfra.Doc_Facade_UntitledDocument
        case .bitable:
            title = BundleI18n.LarkAIInfra.Doc_Facade_UntitledBitable
        case .mindnote:
            title = BundleI18n.LarkAIInfra.Doc_Facade_UntitledMindnote
        case .slides:
            title = BundleI18n.LarkAIInfra.LarkCCM_Slides_Untitled
        case .file, .mediaFile:
            title = BundleI18n.LarkAIInfra.Doc_Facade_UntitledFile
        case .whiteboard:
            title = BundleI18n.LarkAIInfra.LarkCCM_Docx_Board
        default:
            title = "Untitled " + name
            LarkInlineAILogger.info("[url] Untitled name")
        }
        return title
    }
}
