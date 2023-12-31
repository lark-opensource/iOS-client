//
//  PushTranslateResults.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 翻译结果推送，包含RichText，暂时放在ByteViewNetwork里
/// - PUSH_VC_TRANSLATE_RESULTS = 89382
/// - Videoconference_V1_PushVCTranslateResults
public struct PushTranslateResults {

    ///翻译结果
    public var translateInfos: [TranslateInfo]
}

extension PushTranslateResults: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_PushVCTranslateResults
    init(pb: Videoconference_V1_PushVCTranslateResults) {
        self.translateInfos = pb.translateInfos.map({ $0.vcType })
    }
}
