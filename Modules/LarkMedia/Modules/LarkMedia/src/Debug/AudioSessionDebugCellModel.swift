//
//  AudioSessionDebugCellModel.swift
//  AudioSessionScenario
//
//  Created by ford on 2020/6/11.
//

import Foundation

enum AudioDebugCellType {
    case subtitle
    case button
    case singleSel
    case multiSel
    case `switch`
    case singleSelAction
}

typealias SingleSelItem = (value: String, options: [String])
typealias MultiSelItem = (value: [String], options: [String])
typealias SingleSelActionItem = (value: String, options: [String], action: ((String)->String)?)

protocol AudioDebugCellValueType {}

protocol AudioDebugCellValue {
    func execute(completion: @escaping (AudioDebugCellValueType) -> Void)
}

struct AudioDebugSubtitleCellModel: AudioDebugCellValueType {
    typealias DataType = String
    var type: AudioDebugCellType { return .subtitle }
    var title: String
    var value: DataType
}

struct AudioDebugButtonCellModel: AudioDebugCellValueType {
    typealias DataType = (() -> Void)
    var type: AudioDebugCellType { return .button }
    var title: String
    var value: DataType
}

struct AudioDebugSingleSelCellModel: AudioDebugCellValueType {
    typealias DataType = SingleSelItem
    var type: AudioDebugCellType { return .singleSel }
    var title: String
    var value: DataType
}

struct AudioDebugMultiSelCellModel: AudioDebugCellValueType {
    typealias DataType = MultiSelItem
    var type: AudioDebugCellType { return .multiSel }
    var title: String
    var value: DataType
}

struct AudioDebugSwitchCellModel: AudioDebugCellValueType {
    typealias DataType = ((Bool) -> Bool)
    var type: AudioDebugCellType { return .switch }
    var title: String
    var isDefaultOn: Bool
    var value: DataType
}

struct AudioDebugSingleSelActionCellModel: AudioDebugCellValueType {
    typealias DataType = SingleSelActionItem
    var type: AudioDebugCellType { return .singleSelAction }
    var title: String
    var value: DataType
}

struct AudioDebugSubtitleCellModelGetter: AudioDebugCellValue {
    func execute(completion: @escaping (AudioDebugCellValueType) -> Void) {
        completion(AudioDebugSubtitleCellModel(title: title, value: value))
    }

    typealias DataType = String
    var title: String
    var value: DataType
}

struct AudioDebugButtonCellModelGetter: AudioDebugCellValue {
    func execute(completion: @escaping (AudioDebugCellValueType) -> Void) {
        completion(AudioDebugButtonCellModel(title: title, value: value))
    }
    typealias DataType = (() -> Void)
    var title: String
    var value: DataType
}

struct AudioDebugSingleSelCellModelGetter: AudioDebugCellValue {
    func execute(completion: @escaping (AudioDebugCellValueType) -> Void) {
        completion(AudioDebugSingleSelCellModel(title: title, value: value))
    }
    typealias DataType = SingleSelItem
    var title: String
    var value: DataType
}

struct AudioDebugMultiSelCellModelGetter: AudioDebugCellValue {
    func execute(completion: @escaping (AudioDebugCellValueType) -> Void) {
        completion(AudioDebugMultiSelCellModel(title: title, value: value))
    }
    typealias DataType = MultiSelItem
    var title: String
    var value: DataType
}

struct AudioDebugSwitchCellModelGetter: AudioDebugCellValue {
    func execute(completion: @escaping (AudioDebugCellValueType) -> Void) {
        completion(AudioDebugSwitchCellModel(title: title, isDefaultOn: isDefaultOn, value: value))
    }
    typealias DataType = ((Bool) -> Bool)
    var title: String
    var isDefaultOn: Bool
    var value: DataType
}

struct AudioDebugSingleSelActionCellModelGetter: AudioDebugCellValue {
    func execute(completion: @escaping (AudioDebugCellValueType) -> Void) {
        completion(AudioDebugSingleSelActionCellModel(title: title, value: value))
    }

    typealias DataType = SingleSelActionItem
    var title: String
    var value: DataType
}

struct AudioDebugSectionModel {
    let sectionTitle: String
    let cellModels: [AudioDebugCellValue]
}
