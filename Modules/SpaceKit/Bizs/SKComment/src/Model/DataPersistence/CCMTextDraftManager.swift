//
//  CCMTextDraftManager.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/8/9.
//  


import Foundation
import SKFoundation
import SpaceInterface

private extension CCMTextDraftKey {
    
    func draftKey() -> String {
        let entityId = self.entityId ?? "ENTITY"
        let customKey = self.customKey
        return "\(entityId)|\(customKey)"
    }
}


public class CCMTextDraftManager {
    
    let mmkvStorage: CCMMMKVStorage
    
    init(path: String) {
        mmkvStorage = CCMMMKVStorage(path: path)
    }
}

extension CCMTextDraftManager {
    
    @discardableResult
    public func updateModel<T: Encodable>(_ model: T, forKey key: CCMTextDraftKey) -> Bool {
        do {
            let dictKey = key.draftKey()
            let data = try JSONEncoder().encode(model)
            DocsLogger.debug("[draft] update draft Model key:\(key.customKey)", component: LogComponents.comment)
            return mmkvStorage.setDataOfCurrentUser(data, forKey: dictKey)
        } catch {
            DocsLogger.error("[draft] update draft Model error: \(error) key:\(key.customKey)", component: LogComponents.comment)
            return false
        }
    }
    
    public func getModel<T: Decodable>(forKey key: CCMTextDraftKey) -> Swift.Result<T, Error> {
        do {
            let dictKey = key.draftKey()
            if let data = mmkvStorage.getDataOfCurrentUser(forKey: dictKey) {
                let model = try JSONDecoder().decode(T.self, from: data)
                DocsLogger.debug("[draft] get draft Model success key:\(key.customKey) model:\(model)", component: LogComponents.comment)
                return .success(model)
            } else {
                DocsLogger.debug("[draft] get draft Model failure key:\(key.customKey)", component: LogComponents.comment)
                return .failure(TextDraftError.dataNotExist)
            }
        } catch {
            DocsLogger.error("[draft] get draft model error: \(error)", component: LogComponents.comment)
            return .failure(error)
        }
    }
    
    public func removeModel(forKey key: CCMTextDraftKey) {
        let dictKey = key.draftKey()
        DocsLogger.debug("[draft] remove draft key:\(key.customKey)", component: LogComponents.comment)
        mmkvStorage.removeDataOfCurrentUser(forKey: dictKey)
    }
}

private enum TextDraftError: LocalizedError {
    case dataDecodeFailed
    case dataNotExist
    
    var errorDescription: String? {
        switch self {
        case .dataDecodeFailed:
            return "data decode failed"
        case .dataNotExist:
            return "data not exist"
        }
    }
}

extension CommentDraftModel {

    public func decodedAttrString(attributes: [NSAttributedString.Key: Any],
                                  permissionBlock: PermissionQuerryBlock? = nil) -> NSAttributedString {

        let attributedText = AtInfoXMLParser.attrString(encodeString: self.content,
                                                        attributes: attributes,
                                                        isHighlightSelf: false,
                                                        lineBreakMode: .byWordWrapping,
                                                        permissionBlock: permissionBlock)
        return attributedText
    }
}
