//
//  AppBuilder.swift
//  LarkBizTag
//
//  Created by 白镜吾 on 2022/11/24.
//

import Foundation

public final class OPTagViewBuilder: TagViewBuilder {

    /// 应用
    public func isApp(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .app)
        return self
    }
}
