//
//  URLCardViewModel+Ability.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/8/9.
//

import RustPB
import RxSwift
import LarkModel
import Foundation
import EENavigator
import LarkContainer
import TangramService
import LarkMessageBase
import TangramComponent
import RenderRouterInterface

extension URLCardViewModel: ComponentAbility {
    // URLSDK级别容器
    public var cardContainer: URLCardContainer {
        return urlCardService.container
    }

    // update component(root or sub)
    public func updatePreview(component: Component, animation: UITableView.RowAnimation) {
        self.renderer.update(component: component) { [weak self] in
            self?.dependency.reloadRow(animation: animation, updateVM: true)
        }
    }

    // 关闭预览
    public func closePreview() {
        urlCardService.closePreview(previewID: entity.previewID)
        dependency.reloadRow(animation: .none, updateVM: true)
    }
}
