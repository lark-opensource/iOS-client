//
//  DraftAPI.swift
//  Lark
//
//  Created by lichen on 2017/12/16.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RustPB

public protocol DraftAPI {
    func saveDraft(_ draft: RustPB.Basic_V1_Draft) -> Observable<RustPB.Basic_V1_Draft>

    func deleteDraft(key: String) -> Observable<Void>

    func getDraft(keys: [String]) -> Observable<[String: RustPB.Basic_V1_Draft]>

    /// get the draft of topic group in Thread tab
    func fetchDefaultTopicGroupDraft() -> Observable<RustPB.Basic_V1_Draft>
}

public typealias DraftAPIProvider = () -> DraftAPI
