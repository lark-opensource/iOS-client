//
//  RedPacketContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/10.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import EEFlexiable
import UniverseDesignColor

struct RedPacketContentConfig {
    public static var subjectFont: UIFont { UIFont.ud.headline(.s4) }
    public static var actionFont: UIFont { UIFont.ud.caption1(.s4) }
    public static let contentMaxWidth: CGFloat = 160
    public static var contentMaxHeight: CGFloat = 238
    public static let padding: CGFloat = 12
    public static let redPacketYellow = UIColor.ud.Y200 & UIColor.ud.Y800
}

final class RedPacketContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: RedPacketContentContext>: ComponentBinder<C> {
    private let props = RedPacketComponent<C>.Props()
    private let style = ASComponentStyle()
    private lazy var _component: RedPacketComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: ComponentWithContext<C> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? RedPacketContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.statusText = vm.statusText
        props.isShowShadow = vm.isShowShadow
        props.chatComponentTheme = vm.chatComponentTheme
        props.typeDescription = vm.typeDescription
        props.companyImagePassThrough = vm.companyImagePassThrough
        props.mainTip = vm.mainTip
        props.previewChatters = vm.previewChatters
        props.totalNum = vm.totalNum
        props.isCustomCover = vm.isCustomCover
        props.coverImagePassThrough = vm.coverImagePassThrough
        props.hongbaoCoverDisplayName = vm.hongbaoCoverDisplayName
        props.isExclusive = vm.isExclusive
        props.isB2C = vm.isB2CHongbao
        props.b2cCoverDisplayName = vm.b2cCoverDisplayName
        props.tapAction = { [weak vm] in
            vm?.redPacketButtonTapped()
        }

        let widthLimit = RedPacketContentConfig.contentMaxWidth
        let heightLimit = RedPacketContentConfig.contentMaxHeight
        let contentPreferMaxWidth = vm.contentPreferMaxWidth
        style.width = CSSValue(cgfloat: widthLimit)
        style.height = CSSValue(cgfloat: heightLimit)
        props.shrinkScale = 1

        if vm.shouldAddFillet {
            style.cornerRadius = 8
        } else {
            style.cornerRadius = 0
        }
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = RedPacketComponent(props: props, style: style, context: context)
    }
}
