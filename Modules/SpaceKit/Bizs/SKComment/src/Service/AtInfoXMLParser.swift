//
//  AtInfoXMLParser.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/5/17.
//  


import Foundation
import SKFoundation
import SKCommon
import SpaceInterface

/// AtInfo解析器
public final class AtInfoXMLParser: NSObject {
    
    /// AtInfo信息内容
    struct AtInfoContent {
        let type: String
        let href: String
        let token: String
        let content: String // 用于显示的内容
        var icon: String?
        var subType: Int?
        var iconInfoMeta: String?
        
        static var empty: AtInfoContent {
            AtInfoContent(type: "", href: "", token: "", content: "")
        }
    }
    
    enum ParseError: LocalizedError {
        
        case sourceInvalid
        
        case processFailed(Error) // 解析中途失败，一般是特殊字符引起
        
        var errorDescription: String? {
            switch self {
            case .sourceInvalid:
                return "input source invalid"
            case .processFailed(let err):
                return err.localizedDescription
            }
        }
    }
    
    private var xmlParser = XMLParser()
    
    // MARK: 每次解析的临时数据
    private var tempContent = ""
    private var tempAttributes = [String: String]()
    
    deinit {
        xmlParser.delegate = nil
    }
    
    func parse(xmlString: String) -> Swift.Result<AtInfoContent, Error> {
        guard let data = xmlString.data(using: .utf8) else {
            DocsLogger.info("AtInfoXMLParser init failed: \(xmlString)")
            return .failure(ParseError.sourceInvalid)
        }
        xmlParser = .init(data: data)
        xmlParser.delegate = self
        
        tempContent.removeAll()
        tempAttributes.removeAll()
        
        xmlParser.parse()
        let result = getParseResult()
        return result
    }
}

extension AtInfoXMLParser {
    
    private func getParseResult() -> Swift.Result<AtInfoContent, Error> {
        if let err = xmlParser.parserError {
            DocsLogger.info("AtInfoXMLParser parse error: \(err)")
            return .failure(ParseError.processFailed(err))
        }
        let type = tempAttributes["type"] ?? ""
        var subType: Int?
        if let subTypeRaw = tempAttributes["sub_type"],
           let subTypeInt = Int(subTypeRaw) {
            subType = subTypeInt
        }
        let href = tempAttributes["href"] ?? ""
        let token = tempAttributes["token"] ?? ""
        let icon = tempAttributes["icon"]
        var iconInfo: String? = nil
        if UserScopeNoChangeFG.HZK.customIconPart, let info = tempAttributes["icon_info"] {
            iconInfo = info.urlDecoded()
        }
        var result = AtInfoContent(type: type, href: href, token: token, content: tempContent)
        result.icon = icon
        result.subType = subType
        result.iconInfoMeta = iconInfo
        tempAttributes.removeAll()
        tempContent.removeAll()
        
        return .success(result)
    }
}

extension AtInfoXMLParser {
    
    public class func attrString(encodeString: String,
                                 attributes: [NSAttributedString.Key: Any],
                                 isHighlightSelf: Bool = true,
                                 useSelfCache: Bool = true,
                                 lineBreakMode: NSLineBreakMode = .byWordWrapping,
                                 permissionBlock: PermissionQuerryBlock? = nil,
                                 userId: String? = nil,
                                 selfNameMaxWidth: CGFloat = 0,
                                 atSelfYOffset: CGFloat? = nil,
                                 atInfoTransform: ((AtInfo) -> AtInfo)? = nil) -> NSAttributedString {
        
        DocsLogger.info("AtInfoXMLParser use xml format")
        
        guard let regularExpression = AtInfo.mentionRegex else {
            return NSAttributedString(string: encodeString, attributes: attributes)
        }
        let results: [AtInfo.AtInfoOrString]
        do {
            results = try AtInfo.parseMessageContent(in: encodeString, pattern: regularExpression,
                                                     makeInfo: AtInfoXMLParser.getMentionDataFrom)
        } catch {
            results = []
        }

        let mutaAttrString = NSMutableAttributedString(string: "")
        results.forEach { result in
            var attrString = NSAttributedString()
            switch result {
            case .string(let str):
                attrString = NSAttributedString(string: str.parseHTMLConvertCharNoTrimming(), attributes: attributes)
            case .atInfo(var atInfo):
                if let permissionBlock = permissionBlock, let permVaule = permissionBlock(atInfo) {
                    atInfo.hasPermission = permVaule
                }
                if let uid = userId {
                    atInfo.updateUserId(uid)
                }
                if let transform = atInfoTransform {
                    atInfo = transform(atInfo)
                }
                if atInfo.isCurrentUser && isHighlightSelf {
                    attrString = atInfo.attributeStringForAtSelf(attributes: attributes,
                                                                 useSelfCache: useSelfCache,
                                                                 selfNameMaxWidth: selfNameMaxWidth,
                                                                 yOffset: atSelfYOffset)
                } else {
                    attrString = atInfo.attributedString(attributes: attributes, lineBreakMode: lineBreakMode)
                }
            }
            mutaAttrString.append(attrString)
        }
        return mutaAttrString
    }
    
    class func getMentionDataFrom(checkingResult: NSTextCheckingResult, input: NSString) throws -> AtInfo? {
        // 解析atinfo
        let range = checkingResult.range
        guard input.length > 0 else {
            DocsLogger.info("input is Empty")
            return nil
        }
        guard range.location != NSNotFound else {
            DocsLogger.info("range.location not found")
            return nil
        }
        guard range.location + range.length <= input.length else {
            DocsLogger.info("range beyond bounds")
            return nil
        }
        var xmlString = input.substring(with: range)
        let unEscapedContent: String
        if let contentRange = AtInfoXMLParser.getRangeOfContent(xmlString) {
            let rawContent = String(xmlString[contentRange])
            unEscapedContent = rawContent.parseHTMLConvertChar() // 反转义，转为实际显示的字符
            xmlString.replaceSubrange(contentRange, with: "") // 移除原始content,避免其中的xml保留字符导致解析失败
        } else {
            unEscapedContent = ""
        }
        
        xmlString = AtInfoXMLParser.preProcessRawString(xmlString)
        let rawResult = AtInfoXMLParser().parse(xmlString: xmlString)
        switch rawResult {
        case .success(let info):
            guard let result = info.asAtInfo() else { return nil }

            let atString: String
            if result.type == .user {
                atString = String(unEscapedContent.dropFirst())
            } else {
                atString = unEscapedContent
            }
            let newResult = AtInfo(type: result.type,
                                   href: result.href,
                                   token: result.token,
                                   at: atString,
                                   icon: result.iconInfo)
            
            newResult.subType = result.subType
            newResult.iconInfoMeta = result.iconInfoMeta
            return newResult
        case .failure(let error):
            DocsLogger.error("MENTION use regex parse method, error:\(error)")
            let params = ["raw_str": "", "error_des": "\(error)"]
            DocsTracker.newLog(enumEvent: .mentionParseDowngrade, parameters: params)
            throw error
        }
    }
    
    /// 预处理原始字符：替换其中的 & 为 &amp;
    class func preProcessRawString(_ rawString: String) -> String {
        let newString = rawString.replacingOccurrences(of: "&", with: "&amp;")
        return newString
    }
    
    /// 获取content的range
    class func getRangeOfContent(_ rawString: String) -> Range<String.Index>? {
        let startIndex = rawString.range(of: ">")?.lowerBound
        let endIndex = rawString.range(of: "<", options: .backwards)?.lowerBound
        guard var indexA = startIndex,
              let indexB = endIndex else {
            let loginfo = "startIndex:\(String(describing: startIndex)), endIndex:\(String(describing: endIndex))"
            DocsLogger.info("cannot get index, \(loginfo)")
            return nil
        }
        indexA = rawString.index(after: indexA) // 后移一位
        let fullRange = rawString.startIndex ..< rawString.endIndex
        guard fullRange.contains(indexA), fullRange.contains(indexB) else {
            DocsLogger.info("index beyond bounds, fullRange:\(fullRange), startIndex:\(indexA), endIndex:\(indexB)")
            return nil
        }
        let range = indexA ..< indexB
        return range
    }
}

extension AtInfoXMLParser: XMLParserDelegate {
    
    public func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        tempAttributes = attributeDict
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        tempContent.append(string)
    }
}

extension AtInfoXMLParser.AtInfoContent {

    func asAtInfo() -> AtInfo? {
        guard !type.isEmpty else {
            DocsLogger.info("transform to AtInfo error: type isEmpty")
            return nil
        }
        guard !token.isEmpty else {
            DocsLogger.info("transform to AtInfo error: token isEmpty")
            return nil
        }
        let atType = AtType(rawValue: Int(type) ?? AtType.unknown.rawValue) ?? .unknown
        let newContent: String
        if atType == .user {
            newContent = String(content.dropFirst()) // 去除"@"符号
        } else {
            newContent = content
        }
        let iconInfo = AtInfo.makeIconInfo(with: icon)
        let result = AtInfo(type: atType,
                            href: href,
                            token: token,
                            at: newContent,
                            icon: iconInfo)
        if let subType = self.subType {
            result.subType = AtType(rawValue: subType)
        }
        result.iconInfoMeta = iconInfoMeta
        return result
    }
}

class AtInfoXMLParserImp: AtInfoXMLParserInterface {
    
    init() {}
    func attrString(encodeString: String,
                   attributes: [NSAttributedString.Key: Any],
                   isHighlightSelf: Bool = true,
                   useSelfCache: Bool = true,
                   lineBreakMode: NSLineBreakMode,
                   permissionBlock: PermissionQuerryBlock? = nil,
                   userId: String? = nil,
                   selfNameMaxWidth: CGFloat,
                   atSelfYOffset: CGFloat? = nil,
                    atInfoTransform: ((AtInfo) -> AtInfo)? = nil) -> NSAttributedString {
        return AtInfoXMLParser.attrString(encodeString: encodeString,
                                   attributes: attributes,
                                   isHighlightSelf: isHighlightSelf,
                                   useSelfCache: useSelfCache,
                                   lineBreakMode: lineBreakMode,
                                   permissionBlock: permissionBlock,
                                   userId: userId,
                                   selfNameMaxWidth: selfNameMaxWidth,
                                   atInfoTransform: atInfoTransform)
    }
    
    func decodedAttrString(model: CommentDraftModel, attributes: [NSAttributedString.Key: Any], permissionBlock: PermissionQuerryBlock?) -> NSAttributedString {
        let attributedText = AtInfoXMLParser.attrString(encodeString: model.content,
                                                         attributes: attributes,
                                                         isHighlightSelf: false,
                                                         lineBreakMode: .byWordWrapping,
                                                         permissionBlock: permissionBlock)
         return attributedText
    }

    func decodedAttrString(model: CommentDraftModel, attributes: [NSAttributedString.Key: Any],
                           token: String, type: DocsType?, checkPermission: Bool) -> NSAttributedString {
        var block: PermissionQuerryBlock?
        if checkPermission {
            block = { (atInfo: AtInfo) -> Bool? in
                guard atInfo.type == .user, let type = type else {
                    return nil
                }
                let uid = atInfo.token
                let docsKey = AtUserDocsKey(token: token, type: type)
                return AtPermissionManager.shared.hasPermission(uid, docsKey: docsKey)
            }
        }
        return decodedAttrString(model: model, attributes: attributes, permissionBlock: block)
    }
}
