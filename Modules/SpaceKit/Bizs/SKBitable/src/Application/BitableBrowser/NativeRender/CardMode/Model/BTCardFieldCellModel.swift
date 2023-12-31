//
//  BTCardTextModel.swift
//  SKBitable
//
//  Created by X-MAN on 2023/10/31.
//

import Foundation
import SKInfra

protocol BTCardFieldCellModelProtocol {
    var fieldId: String { get set }
    var fieldName: String { get set }
}

struct BTCardFieldCellModel: BTCardFieldCellModelProtocol, SKFastDecodable, Hashable {
    var fieldId: String = ""
    var fieldName: String = ""
    var fieldUIType: BTFieldUIType = .notSupport
    var highlightColor: String? = nil
    var borderHighlightColor: String? = nil
    var data: [AnyHashable] = [] // 都是已数组形式传过来的
    var isRichText: Bool {
        return fieldUIType == .text
    }
    
    var isSimpleText: Bool {
        switch fieldUIType {
        case .barcode, .email,
             .number, .currency,
             .phone, .url,
             .location, .autoNumber:
            return true
        default:
            return false
        }
    }
    
    var isDate: Bool {
        return fieldUIType == .dateTime || fieldUIType == .createTime || fieldUIType == .lastModifyTime
    }
    
    var isEmpty: Bool {
        var empty = data.isEmpty
        if fieldUIType == .text {
            // 多行文本特化逻辑
            if let richtTextData = getFieldData(type: BTRichTextData.self).first,
               let seg = richtTextData.segments?.first,
                !seg.text.isEmpty {
                empty = false
            } else {
                empty = true
            }
        } else if fieldUIType == .dateTime ||
            fieldUIType == .createTime ||
            fieldUIType == .lastModifyTime {
            // 多行文本特化逻辑
            if let richtTextData = getFieldData(type: BTDateData.self).first,
               !richtTextData.text.isEmpty {
                empty = false
            } else {
                empty = true
            }
        }
        return empty
    }
    
    // 所有的都是数组，外面决定用多少个
    func getFieldData<T: SKFastDecodable>(type: T.Type) ->[T] {
        if let data = data as? [[String: Any]] {
            return data.map {
                return T.convert(from: $0)
            }
        }
        return []
    }
    
    static func == (lhs: BTCardFieldCellModel, rhs: BTCardFieldCellModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    static func deserialized(with dictionary: [String: Any]) -> BTCardFieldCellModel {
        var model = BTCardFieldCellModel()
        model.fieldId <~ (dictionary, "fieldId")
        model.fieldName <~ (dictionary, "fieldName")
        model.fieldUIType <~ (dictionary, "fieldUIType")
        model.highlightColor <~ (dictionary, "highlightColor")
        model.borderHighlightColor <~ (dictionary, "borderHighlightColor")
        model.data <~ (dictionary, "data")
        return model
    }
    
}
