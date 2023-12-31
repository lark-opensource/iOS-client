//
//  SCDebugFormViewModel.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/29.
//

import Foundation

class SCDebugFormViewModel {
    // section 及对应的字段
    let sectionList: [SCDebugSectionViewModel]
    // 字段行高
    let rowHeight: CGFloat = 44
    // 处理表单
    var handler: SCDebugFormViewModelHandler?

    var sectionContentMap: [String: [SCDebugFieldViewModel]] {
        sectionList.reduce(into: [String: [SCDebugFieldViewModel]](), { result, element in
            result.updateValue(element.fieldList, forKey: element.sectionName)
        })
    }

    init(sectionList: [SCDebugSectionViewModel]) {
        self.sectionList = sectionList
    }

    func submit(completed: @escaping (String?) -> Void) {
        handler?.requestResult(sectionContentMap: sectionContentMap) { text in
            completed(text)
        }
    }
}

class SCDebugSectionViewModel {
    let sectionName: String
    private(set) var fieldList: [SCDebugFieldViewModel]
    // 支持添加的 cell 类型，如果没有填空即可
    let addibleFieldType: [SCDebugFieldViewCellProtocol.Type]
    // 是否可添加
    var isEidtable: Bool{
        return !addibleFieldType.isEmpty
    }

    init(sectionName: String, 
         fieldList: [SCDebugFieldViewModel],
         addibleFieldType: [SCDebugFieldViewCellProtocol.Type] = []) {
        self.sectionName = sectionName
        self.fieldList = fieldList
        self.addibleFieldType = addibleFieldType
    }

    func insertFieldModel(modelType: SCDebugFieldViewCellProtocol.Type, at index: Int) {
        guard isEidtable,
              addibleFieldType.contains(where: { $0 == modelType }),
              index >= 0,
              index <= fieldList.count else { return }
        let fieldModel = SCDebugFieldViewModel(cellID: modelType.cellID, isRequired: false)
        fieldList.insert(fieldModel, at: index)
    }

    func removeFieldModel(at index: Int) {
        guard isEidtable,
              index >= 0,
              index < fieldList.count else { return }
        fieldList.remove(at: index)
    }
}

protocol SCDebugFormViewModelHandler {
    func requestResult(sectionContentMap: [String: [SCDebugFieldViewModel]],
                       completed: @escaping (String?) -> Void)
}

extension Array where Element: SCDebugSectionViewModel {
    subscript(searchKey: String) -> SCDebugSectionViewModel? {
        first(where: { searchKey == $0.sectionName })
    }

    subscript(safeAccess index: Int) -> SCDebugSectionViewModel? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
