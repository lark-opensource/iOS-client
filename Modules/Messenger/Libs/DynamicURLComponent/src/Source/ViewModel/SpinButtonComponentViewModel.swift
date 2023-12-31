//
//  SpinButtonComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/19.
//

import UIKit
import Foundation
import RustPB
import LarkCore
import ByteWebImage
import TangramComponent
import TangramUIComponent
import UniverseDesignActionPanel

public final class SpinButtonComponentViewModel: RenderComponentBaseViewModel {
    // 当前选中的item，为了优化用户体验，点击之后立即修改UI，等push回来再更新一遍
    private var selectedIndex: Int = 0
    private lazy var _component: SpinButtonComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let spinButton = property?.spinButton ?? .init()
        let props = buildComponentProps(stateID: stateID, componentID: componentID, property: spinButton, style: style)
        _component = SpinButtonComponent<EmptyContext>(props: props, style: renderStyle)
    }

    private func buildComponentProps(stateID: String,
                                     componentID: String,
                                     property: Basic_V1_URLPreviewComponent.SpinButtonProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> SpinButtonComponentProps {
        let props = SpinButtonComponentProps()
        if let textColor = style.tcTextColor {
            props.titleColor = textColor
        }
        let items = property.items
        let index = Int(property.selectedIndex)
        self.selectedIndex = index
        if !items.isEmpty, index < items.count {
            props.title = items[index].text
        }
        if let font = style.tcFont {
            props.titleFont = font
        }
        let iconColor = props.titleColor
        props.setImage.update { view in
            let key = ImageItemSet.transform(imageSet: property.icon).generateImageMessageKey(forceOrigin: false)
            view.bt.setLarkImage(with: .default(key: key), completion: { [weak view] result in
                if case .success(let res) = result, let image = res.image {
                    view?.setImage(image, tintColor: iconColor)
                }
            })
        }
        var actions = [String: Basic_V1_UrlPreviewAction]()
        if let allActions = self.entity.previewBody?.states[stateID]?.actions {
            items.forEach({ actions[$0.actionID] = allActions[$0.actionID] })
        }
        props.onTap.update { [weak self, weak props] button in
            guard let self = self else { return }
            self.openSelection(
                componentID: componentID,
                sourceView: button,
                actions: actions,
                items: items,
                selectedIndex: self.selectedIndex,
                dismissCallback: { [weak button] in
                    button?.rotateIcon(animated: true)
                }, selectCallback: { [weak self] index, item in
                    guard let props = props, let self = self else { return }
                    props.title = item.text
                    self.selectedIndex = index
                    self.ability.updatePreview(component: self.component)
                }
            )
        }
        return props
    }

    func openSelection(
        componentID: String,
        sourceView: UIView?,
        actions: [String: Basic_V1_UrlPreviewAction],
        items: [Basic_V1_URLPreviewComponent.Item],
        selectedIndex: Int,
        dismissCallback: @escaping () -> Void,
        selectCallback: @escaping (Int, Basic_V1_URLPreviewComponent.Item) -> Void
    ) {
        guard let sourceView = sourceView, items.count > selectedIndex, let targetVC = dependency.targetVC else { return }
        let source = UDActionSheetSource(sourceView: sourceView,
                                         sourceRect: sourceView.bounds,
                                         arrowDirection: .up)
        let actionsheet = UDActionSheet(config: UDActionSheetUIConfig(popSource: source))
        actionsheet.dismissCallback = { dismissCallback() }
        for index in 0..<items.count {
            let item = items[index]
            let isSelected = (index == selectedIndex)
            actionsheet.addItem(.init(title: item.text, titleColor: isSelected ? UIColor.ud.colorfulBlue : nil, action: { [weak self] in
                guard let self = self else { return }
                URLTracker.trackRenderClick(entity: self.entity,
                                            extraParams: self.dependency.extraTrackParams ?? [:],
                                            clickType: .selectItem,
                                            componentID: componentID,
                                            actionID: item.actionID)
                if !isSelected, let action = actions[item.actionID] {
                    // 为了优化用户体验，点击之后立即修改UI，等push回来再更新一遍
                    selectCallback(index, item)
                    ComponentActionRegistry.handleAction(entity: self.entity,
                                                         action: action,
                                                         actionID: item.actionID,
                                                         dependency: self.dependency)
                }
            }))
        }
        actionsheet.setCancelItem(text: BundleI18n.DynamicURLComponent.Lark_Legacy_Cancel)
        self.userResolver.navigator.present(actionsheet, from: targetVC)
        URLTracker.trackRenderClick(entity: self.entity,
                                    extraParams: self.dependency.extraTrackParams,
                                    clickType: .pageClick,
                                    componentID: componentID)
    }
}
