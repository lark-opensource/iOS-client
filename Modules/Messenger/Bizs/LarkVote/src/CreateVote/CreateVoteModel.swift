//
//  CreateVoteModel.swift
//  LarkVote
//
//  Created by Fan Hui on 2022/3/31.
//

import Foundation
import EENavigator
import RustPB

final class CreateVoteModel {
    /// 投票主题
    var topic: String? = ""

    /// 投票选项
    var options: [CreateVoteOption] = []

    /// 是否多选
    var minPickNum: Int = 1

    var maxPickNum: Int = 1

    /// 是否实名
    var isRealName: Bool = false

    public func transformModelToPB(containerType: Vote_V1_VoteScopeContainerType, scopeID: String) -> Vote_V1_PublishVoteRequest {
        var PBModel = Vote_V1_PublishVoteRequest()
        PBModel.isPublic = isRealName
        PBModel.minPickNum = Int64(minPickNum)
        PBModel.maxPickNum = Int64(maxPickNum)
        PBModel.cid = UUID().uuidString
        PBModel.scopeID = scopeID
        PBModel.voteScene = containerType
        PBModel.topic = topic ?? ""
        var arr: [Vote_V1_VoteOption] = []
        for option in options {
            let optionPBModel = option.transformModelToPB()
            arr.append(optionPBModel)
        }
        PBModel.options = arr
        return PBModel
    }
}

final class CreateVoteOption {
    /// 选项序号
    var optionNumber: Int = 0

    /// 选项内容，目前只支持投票选项文本类型，后续可做扩展
    var optionContent: String? = ""

    init(optionNumber: Int, optionContent: String?) {
        self.optionNumber = optionNumber
        self.optionContent = optionContent
    }

    public func transformModelToPB() -> Vote_V1_VoteOption {
        var PBModel = Vote_V1_VoteOption()
        PBModel.index = Int32(optionNumber)
        PBModel.content = optionContent ?? ""
        // 目前支持投票选项文本类型
        PBModel.type = .text
        return PBModel
    }
}

enum VoteIndex: Int {
    case topic = 0
    case options
    case isMultiple
    case isAnonymous
}
