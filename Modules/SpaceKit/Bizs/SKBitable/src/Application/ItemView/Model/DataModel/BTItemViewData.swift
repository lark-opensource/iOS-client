//
//  BTItemViewData.swift
//  SKBitable
//
//  Created by zoujie on 2023/8/7.
//  

import Foundation

enum BTItemViewDataType: String {
  case stage = "Stage"
}

struct BTItemViewDatas: Codable {
    var stageItemViewData: [BTStageItemViewData]
}

struct BTStageItemViewData: Codable {
    var recordId: String
    var stageDatas: [BTItemViewStageDatas]?
}

struct BTItemViewStageDatas: Codable {
    var stageFieldId: String
    var optionDatas: [BTItemViewStageOptDatas]
}

struct BTItemViewStageOptDatas: Codable {
  var optionId: String
  var requiredFields: [String]
  var stageConvert: Bool
}


