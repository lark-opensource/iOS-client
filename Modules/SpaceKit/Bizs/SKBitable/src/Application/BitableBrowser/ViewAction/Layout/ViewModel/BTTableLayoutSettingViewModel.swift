//
//  BTTableLayoutSettingViewModel.swift
//  SKBitable
//
//  Created by zhysan on 2023/1/31.
//

import SKFoundation

// MARK: - view model

struct BTCardLayoutSettings {
    
    // MARK: - public
    
    struct ColumnSection {
        var columnType: BTTableLayoutSettings.ColumnType
    }

    struct TitleAndCoverSection {
        var coverField: BTFieldOperatorModel?
        var titleField: BTFieldOperatorModel
        var subTitleField: BTFieldOperatorModel?
    }
    
    struct DisplaySection {
        static let maxDisplayCount = 9
        
        var fields: [BTFieldOperatorModel]
    }
    
    struct MoreSection {
        var fields: [BTFieldOperatorModel]
        var addEnable: Bool
    }
    
    private(set) var column: ColumnSection?
    private(set) var titleAndCover: TitleAndCoverSection?
    private(set) var display: DisplaySection
    private(set) var more: MoreSection

    mutating func update(columnType: BTTableLayoutSettings.ColumnType) {
        column?.columnType = columnType
    }
    
    mutating func update(coverField: BTFieldOperatorModel?) {
        titleAndCover?.coverField = coverField
    }
    
    mutating func update(titleField: BTFieldOperatorModel) {
        titleAndCover?.titleField = titleField
    }
    
    mutating func update(subTitleField: BTFieldOperatorModel?) {
        titleAndCover?.subTitleField = subTitleField
    }
    
    @discardableResult
    mutating func update(addToVisiable field: BTFieldOperatorModel) -> Bool {
        guard display.fields.count < DisplaySection.maxDisplayCount else {
            return false
        }
        display.fields.append(field)
        more.fields.removeAll(where: { $0.id == field.id })
        more.addEnable = display.fields.count < DisplaySection.maxDisplayCount
        return true
    }
    
    mutating func update(deleteFromVisiable field: BTFieldOperatorModel) {
        display.fields.removeAll(where: { $0.id == field.id })
        more.fields = allFields.filter({ item in
            display.fields.first(where: { $0.id == item.id }) == nil
        })
        more.addEnable = display.fields.count < DisplaySection.maxDisplayCount
    }
    
    mutating func update(sortVisiable fields: [BTFieldOperatorModel]) {
        display.fields = fields
    }
    
    // MARK: - life cycle
    
    init(settings: BTTableLayoutSettings, fields: [BTFieldOperatorModel]) {
        self.allFields = fields
        
        // parse row count section
        var type: BTTableLayoutSettings.ColumnType = .three
        if let val = settings.columnCount, let valType = BTTableLayoutSettings.ColumnType(rawValue: val) {
            type = valType
        }
        column = ColumnSection(columnType: type)
        
        // parse title and cover section
        if let val = settings.titleFieldId, let titleField = fields.first(where: { $0.id == val }) {
            var subTitleField: BTFieldOperatorModel? = nil
            if let subTitleID = settings.subtitleFieldId {
                subTitleField = fields.first(where: { $0.id == subTitleID })
            }
            
            var coverField: BTFieldOperatorModel? = nil
            if let subTitleID = settings.coverFieldId {
                coverField = fields.first(where: { $0.id == subTitleID && $0.compositeType.type == .attachment })
            }
            titleAndCover = TitleAndCoverSection(coverField: coverField, titleField: titleField, subTitleField: subTitleField)
        }

        // parse display & more section
        var displayFields = [BTFieldOperatorModel]()
        var moreFields = fields
        if let val = settings.visibleFieldIds, !val.isEmpty {
            val.forEach({ id in
                let index = moreFields.firstIndex(where: { $0.id == id })
                if let index = index {
                    let item = moreFields[index]
                    displayFields.append(item)
                    moreFields.remove(at: index)
                }
            })
        }
        display = DisplaySection(fields: displayFields)
        more = MoreSection(fields: moreFields, addEnable: displayFields.count < DisplaySection.maxDisplayCount)
    }
    
    // MARK: - private
    
    private let allFields: [BTFieldOperatorModel]
}

final class BTTableLayoutSettingViewModel {
    
    // MARK: - public
    
    let allFields: [BTFieldOperatorModel]
    
    private(set) var viewType: BTTableLayoutSettings.ViewType
    
    // how to imp: private(set) & mutating ?
    var cardSettings: BTCardLayoutSettings
    
    func updateViewType(_ viewType: BTTableLayoutSettings.ViewType) {
        self.viewType = viewType
    }
    
    func getCurrentLayoutSettings() -> BTTableLayoutSettings {
        BTTableLayoutSettings(
            gridViewLayoutType: viewType,
            columnCount: cardSettings.column?.columnType.rawValue,
            visibleFieldIds: cardSettings.display.fields.compactMap({ $0.id }),
            coverFieldId: cardSettings.titleAndCover?.coverField?.id ?? "",
            titleFieldId: cardSettings.titleAndCover?.titleField.id,
            subtitleFieldId: cardSettings.titleAndCover?.subTitleField?.id ?? ""
        )
    }
    
    // MARK: - life cycle
    init(settings: BTTableLayoutSettings, fields: [BTFieldOperatorModel]) {
        self.viewType = settings.gridViewLayoutType
        self.allFields = fields
        self.cardSettings = BTCardLayoutSettings(settings: settings, fields: fields)
    }
    
    // MARK: - private
}
