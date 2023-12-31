//
//  ParticipantUserFlagLabel.swift
//  ByteView
//
//  Created by wulv on 2022/2/25.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import ByteViewNetwork

/// 用户标签类型
enum UserFlagType: Equatable {
    /// 无
    case none
    /// 外部
    case external
    /// 请假
    case onLeave
    /// 关联标签
    case relationTag(String)
}

extension UserFlagType {
    static func fromRelationTag(_ relation: VCRelationTag?) -> UserFlagType? {
        guard let relationTag = relation?.relationTag else { return nil }
        if relationTag.relationTagType == .external { return .external }
        let relationText = relationTag.relationTag?.localizedText
        guard relationTag.relationTagType != .unset, let relationText = relationText else {
            return nil
        }
        return .relationTag(relationText)
    }

    static func fromCollaborationTag(_ relation: CollaborationRelationTag?) -> UserFlagType? {
        guard let relationTag = relation else { return nil }
        let relationType = relationTag.relationTagType
        let relationText = relationTag.relationTag?.localizedText
        if relationType != .unset, let relationText = relationText {
            return .relationTag(relationText)
        }
        return nil
    }
}

/// 用户标签(外部/请假)
class ParticipantUserFlagLabel: ParticipantBaseLabel {

    var oriMinWidth: CGFloat = 35.0
    var dynamicMinWidth: CGFloat?
    var height: CGFloat = 18.0

    var type: UserFlagType = .none {
        didSet {
            if oldValue != type {
                update(type: type)
            }
        }
    }

    convenience init(type: UserFlagType, minWidth: CGFloat = 35, height: CGFloat = 18, horizontalHugging: UILayoutPriority = .required) {
        self.init(frame: .zero)
        self.oriMinWidth = minWidth
        self.height = height
        backgroundColor = participantsBgColor
        textInsets = UIEdgeInsets(top: 0.0,
                                  left: 4.0,
                                  bottom: 0.0,
                                  right: 4.0)
        font = .systemFont(ofSize: 12, weight: .medium)
        lineBreakMode = .byTruncatingTail
        textAlignment = .center
        contentMode = .center
        baselineAdjustment = .alignCenters
        layer.cornerRadius = 4.0
        clipsToBounds = true
        setContentHuggingPriority(horizontalHugging, for: .horizontal)
        snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(self.oriMinWidth)
            make.height.equalTo(self.height)
        }
        isHiddenInStackView = true
        self.type = type
    }

    /// 拒绝回复理由展示时，外部标签需要设置最大展示宽度，当外部内容宽度
    /// min <= width < max时，按照实际宽度展示，
    /// 其他条件按最小宽度展示
    func setMinWidth(_ minWidth: CGFloat?) {
        dynamicMinWidth = minWidth
        updateLabelWidth()
    }

    private func updateLabelWidth() {
        if let dynamicMinWidth = dynamicMinWidth, dynamicMinWidth > oriMinWidth {
            let width = ceil(text?.vc.boundingWidth(height: height - textInsets.top - textInsets.bottom, font: font) ?? 0.0) + textInsets.left + textInsets.right
            var renderWidth = oriMinWidth
            if width >= dynamicMinWidth {
                renderWidth = dynamicMinWidth
            } else if width >= oriMinWidth {
                renderWidth = width
            }
            snp.remakeConstraints { make in
                make.width.greaterThanOrEqualTo(renderWidth)
                make.width.lessThanOrEqualTo(width)
                make.height.equalTo(self.height)
            }
        } else {
            snp.remakeConstraints { make in
                make.width.greaterThanOrEqualTo(self.oriMinWidth)
                make.height.equalTo(self.height)
            }
        }
    }
}

// MARK: - Private
extension ParticipantUserFlagLabel {
    private func update(type: UserFlagType) {
        switch type {
        case .none:
            isHiddenInStackView = true
        case .external:
            isHiddenInStackView = false
            configureToExternal()
        case .onLeave:
            isHiddenInStackView = false
            configureToOnLeave()
        case .relationTag(let tag):
            isHiddenInStackView = false
            configureToRelationTag(tag)
        }
        updateLabelWidth()
    }

    private func configureToExternal() {
        text = I18n.View_G_ExternalLabel
        textColor = UIColor.ud.udtokenTagTextSBlue
            backgroundColor = UIColor.ud.udtokenTagBgBlue
        setContentCompressionResistancePriority(ParticipantStatusPriority.externalTag.priority, for: .horizontal)
    }

    private func configureToOnLeave() {
        text = I18n.View_G_OnLeave
        textColor = UIColor.ud.R600
        backgroundColor = UIColor.ud.R100
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func configureToRelationTag(_ tag: String) {
        text = tag
        textColor = UIColor.ud.udtokenTagTextSBlue
            backgroundColor = UIColor.ud.udtokenTagBgBlue
        setContentCompressionResistancePriority(ParticipantStatusPriority.externalTag.priority, for: .horizontal)
    }
}
