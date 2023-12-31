//
//  BlockComponent.swift
//  templateDemo
//
//  Created by  bytedance on 2021/3/29.
//

import Foundation
import SwiftyJSON
import LarkWorkplaceModel
import LKCommonsLogging

/// BlockLayout 组件 (包裹了Block）
final class BlockLayoutComponent: GroupComponent {
    static let logger = Logger.log(BlockLayoutComponent.self)

    var lastComponentState: ComponentState?
    var componentState: ComponentState = .loading
    var groupType: GroupComponentType = .Block

    var componentID: String = ""

    var layoutParams: BaseComponentLayout?

    var nodeComponents: [NodeComponent] = []

    var extraComponents: [NodeComponentType: NodeComponent] = [:]

    var editorProps: TMPLBlockProps?

    var styles: TMPLBlockStyles?

    func parse(json: JSON) -> GroupComponent {
        componentID = json[ComponentIdKey].string ?? ""   // ⚠️返回数据中没有ID，则数据异常

        /// 解析布局参数
        layoutParams = BaseComponentLayout(json: json[StylesKey])

        /// 解析子节点（⚠️block应该还需要一些数据链接）
        nodeComponents = [BlockComponent()]

        do {
            let propsData = try json[PropsKey].rawData()
            let stylesData = try json[StylesKey].rawData()
            editorProps = try JSONDecoder().decode(TMPLBlockProps.self, from: propsData)
            styles = try JSONDecoder().decode(TMPLBlockStyles.self, from: stylesData)
        } catch {
            Self.logger.error("block decode error: \(error)")
        }

        return self
    }

    func updateGroupState(_ newState: ComponentState) {
        if componentState != .running {
            componentState = newState
        }
    }

    func removeComponent(at index: Int, for notAuth: Bool) {
        guard notAuth else {
            return
        }
        if index >= 0 && index < nodeComponents.count {
            nodeComponents.remove(at: index)
        }
    }
}

extension BlockLayoutComponent {
    var moduleReqParam: ComponentModuleReqParam? {
        let params = [
            "blockId": editorProps?.blockId ?? "",
            "itemId": editorProps?.itemId ?? ""
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            assertionFailure()
            return nil
        }
        guard let jsonStr = String(data: data, encoding: .utf8) else {
            assertionFailure()
            return nil
        }
        return ComponentModuleReqParam(
            moduleType: .blockList,
            componentId: componentID,
            params: jsonStr
        )
    }

    func updateModuleData(_ json: JSON, isPortalPreview: Bool = false) -> Bool {
        do {
            let item = try JSONDecoder().decode(WPTemplateModule.ComponentDetail.Block.self, from: json.rawData())
            let node = self.nodeComponents.first as? BlockComponent
            // 单个 Block 组件的 block scene 使用 .template (不会限制 Block 高度)
            node?.updateDataModel(
                item.itemInfo,
                scene: .templateComponent,
                elementId: componentID,
                editorProps: editorProps,
                styles: styles,
                isPortalPreview: isPortalPreview
            )
            return true
        } catch {
            Self.logger.error("block \(componentID) module decode error: \(error.localizedDescription)")
            return false
        }
    }
}

/// 真正的Block组件
final class BlockComponent: NodeComponent {
    var type: NodeComponentType { .Block }
    private(set) var layoutParams: BaseComponentLayout?
    private(set) var blockModel: BlockModel?

    func updateDataModel(
        _ item: WPAppItem,
        scene: BlockScene,
        elementId: String,
        editorProps: TMPLBlockProps? = nil,
        styles: TMPLBlockStyles? = nil,
        displaySize: FavoriteAppDisplaySize?=nil,
        isPortalPreview: Bool = false
    ) {
        self.blockModel = BlockModel(
            item: item,
            scene: scene,
            elementId: elementId,
            editorProps: editorProps,
            styles: styles,
            sourceData: nil,
            isPortalPreview: isPortalPreview
        )
        if let size = displaySize {
            let blockHeight = WPUtils.getBlockHeight(size: size)
            layoutParams = .init(width: "fill_parent", height: "\(blockHeight)", margins: [0, 0, 0, 0])
        }
    }

    func updateEditState(isEditing: Bool) {
        blockModel?.isEditing = isEditing
    }

    /// 是否是模版工作台常用区域 Block
    var isTemplateCommonAndRecommand: Bool {
        return blockModel?.isTemplateCommonAndRecommand ?? false
    }

    /// 是否可删除
    var isDeletable: Bool {
        return blockModel?.isDeletable ?? false
    }

    /// 是否可排序
    var isSortable: Bool {
        return blockModel?.isSortable ?? false
    }

    /// 是否是可编辑（删除、拖拽）的应用
    var isEditable: Bool {
        return blockModel?.isEditable ?? false
    }

    /// 是否是模版工作台推荐 Block
    var isTemplateRecommand: Bool {
        return blockModel?.isTemplateRecommand ?? false
    }

    var appId: String? {
        return blockModel?.appId
    }
}
