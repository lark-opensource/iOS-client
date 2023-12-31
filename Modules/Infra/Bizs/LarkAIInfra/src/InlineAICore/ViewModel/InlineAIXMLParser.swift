//
//  InlineAIXMLParser.swift
//  SKComment
//
//  Created by huayufan on 2023/12/11.
//  


import Foundation


final class AIMentionParser: NSObject {

    private lazy var mentionRegex: NSRegularExpression? = {
         let pattern = "<at(\n|.)*?>(\n|.)*?</at>"
         let regex: NSRegularExpression?
         do {
             regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
         } catch {
             return nil
         }
         return regex
     }()
     
    private lazy var xmlParser = InlineAIXMLParser()
    
    func parseContent(text: String) -> [AtInfoContent] {
        // 找出所有的mention标签
         guard let mentionRegex else {
             LarkInlineAILogger.error("mentionRegex is nil")
             return []
         }
         let ranges = self.parseContent(in: text, pattern: mentionRegex)

        guard !ranges.isEmpty else {
            return []
        }
        var parseResult: [AtInfoContent] = []
        for range in ranges {
            guard let strRange = Range(range, in: text) else {
                continue
            }
            let str = String(text[strRange])
            let result = xmlParser.parse(xmlString: str)
            switch result {
            case var .success(info):
                info.update(range: range)
                parseResult.append(info)
            case let .failure(error):
                LarkInlineAILogger.error("xmlParser error:\(error)")
            }
        }
        return parseResult
     }
    
    private func parseContent(in text: String, pattern: NSRegularExpression) -> [NSRange] {
        let input: NSString = text as NSString
        return pattern.matches(in: text, range: NSRange(location: 0, length: input.length)).map { $0.range }
    }
}

extension AIMentionParser {
    func parseLinkText(text: String, typingAttributes: [NSAttributedString.Key : Any]) -> NSAttributedString? {
        let textContent = text
        let results = parseContent(text: textContent)
        let textAttr = NSMutableAttributedString(string: "", attributes: typingAttributes)
        var preRange = NSRange(location: 0, length: 0)
        LarkInlineAILogger.info("find link count:\(results.count)")
        for result in results {
            guard let range = result.range else {
                LarkInlineAILogger.error("parser range is nil")
                continue
            }

            let begin = preRange.location + preRange.length
            let pureTextRange = NSRange(location: begin, length: range.location - begin)
            
            if let strRange = Range(pureTextRange, in: textContent) {
                let str = String(textContent[strRange])
                textAttr.append(NSAttributedString(string: str, attributes: typingAttributes))
                preRange = range
            }
            let attr = result.toDocsLinkAttr(attributes: typingAttributes)
            textAttr.append(attr)
        }
        let begin = preRange.location + preRange.length
        let remainedLen = textContent.utf16.count - begin
        if results.isEmpty == false, remainedLen > 0 {
            let pureTextRange = NSRange(location: begin, length: remainedLen)
            if let strRange = Range(pureTextRange, in: textContent) {
                let str = String(textContent[strRange])
                textAttr.append(NSAttributedString(string: str, attributes: typingAttributes))
            }
        }
        if textAttr.string.isEmpty {
            return nil
        } else {
            return textAttr
        }
    }
}


final class InlineAIXMLParser: NSObject {

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
            LarkInlineAILogger.info("InlineAIXMLParser init failed: \(xmlString)")
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

extension InlineAIXMLParser: XMLParserDelegate {
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        tempAttributes = attributeDict
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        tempContent.append(string)
    }
}

extension InlineAIXMLParser {
    
    private func getParseResult() -> Swift.Result<AtInfoContent, Error> {
        if let err = xmlParser.parserError {
            LarkInlineAILogger.info("InlineAIXMLParser parse error: \(err)")
            return .failure(ParseError.processFailed(err))
        }
        let type = tempAttributes["type"] ?? ""
        let intType = Int(type) ?? 1
        let href = tempAttributes["href"] ?? ""
        let token = tempAttributes["token"] ?? ""
        let result = AtInfoContent(type: intType, href: href, token: token, content: tempContent)
        tempAttributes.removeAll()
        tempContent.removeAll()
        
        return .success(result)
    }
}
