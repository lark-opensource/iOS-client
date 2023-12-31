//
//  IMMentionTagView.swift
//  LarkIMMention
//
//  Created by Yuri on 2023/1/10.
//

import UIKit
import Foundation
import SnapKit
import LarkBizTag
import LarkTag
import RustPB

class IMMentionTagView: UIView {
    
    lazy var chatterTagBuilder: ChatterTagViewBuilder = ChatterTagViewBuilder()
    lazy var nameTag: TagWrapperView = {
        let nameTag = chatterTagBuilder.build()
        nameTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameTag.setContentHuggingPriority(.required, for: .horizontal)
        return nameTag
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(nameTag)
        nameTag.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 更新tag
    func update(id: String, tags: [PickerOptionTagType]?, tagData: Basic_V1_TagData?) {
        // 自定义标签和外部标签放在tagData,其他放在tags
        chatterTagBuilder.reset(with: [])
        let data = tagData?.transform() ?? []
        let tgs = tags ?? []
        chatterTagBuilder.isOnLeave(tgs.contains(.onLeave))
            .isRobot(tgs.contains(.robot))
            .isUnregistered(tgs.contains(.unregistered))
            .addTags(with: data)
            .refresh()
    }
    
    var isTagEmpty: Bool {
        return chatterTagBuilder.isDisplayedEmpty()
    }
}
