//
//  DocTagBuilder.swift
//  LarkBizTag
//
//  Created by 白镜吾 on 2022/11/24.
//

import Foundation

public final class DocTagViewBuilder: TagViewBuilder {

    /// 标签互斥约束
    public override var mutexTags: [[TagType]] {
        return customMutexTags ??
        [
            [.relation, .connect, .external]
        ]
    }

    /// 外部
    @available(*, deprecated, message: "This Api is Only Use For 'External', Please Use 'func addTag(with tagDataItem: TagDataItem) -> TagViewBuilder'")
    public func isExternal(_ value: Bool) -> Self {
        self.judgeType(value: value, tagType: .external)
        return self
    }
}
