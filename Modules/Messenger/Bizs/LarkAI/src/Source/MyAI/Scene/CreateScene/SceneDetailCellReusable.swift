//
//  SceneDetailCellReusable.swift
//  LarkAI
//
//  Created by Zigeng on 2023/10/11.
//

import Foundation
import UIKit

/// 场景详情页的各种cellViewModel --> cell的能力收敛到这里
protocol SceneDetailCellReusable: UITableViewDataSource {
    var sceneDetailView: UITableView { get }
    static func getCell(_ tableView: UITableView, cellVM: SceneDetailCellViewModel) -> any SceneDetailCell
    func registerCells()
}

extension SceneDetailCellReusable {
    static func getCell(_ tableView: UITableView, cellVM: SceneDetailCellViewModel) -> any SceneDetailCell {
        /// 输入框样式的cell
        if let cellVM = cellVM as? SceneDetailInputCellViewModel,
           let cell = tableView.dequeueReusableCell(withIdentifier: SceneDetailInputCell.identifier) as? SceneDetailInputCell {
            cell.setCell(vm: cellVM)
            return cell
        /// Switch样式的Cell
        } else if let cellVM = cellVM as? SceneDetailSwitchCellViewModel,
                  let cell = tableView.dequeueReusableCell(withIdentifier: SceneDetailSwitchCell.identifier) as? SceneDetailSwitchCell {
            cell.setCell(vm: cellVM)
            return cell
        /// 单行文本输入的cell
        } else if let cellVM = cellVM as? SceneDetailTextFieldCellViewModel,
                  let cell = tableView.dequeueReusableCell(withIdentifier: SceneDetailTextFieldCell.identifier) as? SceneDetailTextFieldCell {
            cell.setCell(vm: cellVM)
            return cell
        /// 跳转到二级选择器界面的cell
        } else if let cellVM = cellVM as? SceneDetailSelectorCellViewModel,
                  let cell = tableView.dequeueReusableCell(withIdentifier: SceneDetailSelectorCell.identifier) as? SceneDetailSelectorCell {
            cell.setCell(vm: cellVM)
            return cell
        /// 添加文本的cell
        } else if let cellVM = cellVM as? SceneDetailAddTextCellViewModel,
                  let cell = tableView.dequeueReusableCell(withIdentifier: SceneDetailAddTextCell.identifier) as? SceneDetailAddTextCell {
            cell.setCell(vm: cellVM)
            return cell
        /// 编辑icon的cell
        } else if let cellVM = cellVM as? SceneDetailIconCellViewModel,
                  let cell = tableView.dequeueReusableCell(withIdentifier: SceneDetailIconCell.identifier) as? SceneDetailIconCell {
            cell.setCell(vm: cellVM)
            return cell
        }
        #if DEBUG || ALPHA
        fatalError("unkown cellViewModel/cell")
        #endif
        return SceneDetailSwitchCell()
    }

    func registerCells() {
        sceneDetailView.register(SceneDetailInputCell.self, forCellReuseIdentifier: SceneDetailInputCell.identifier)
        sceneDetailView.register(SceneDetailTextFieldCell.self, forCellReuseIdentifier: SceneDetailTextFieldCell.identifier)
        sceneDetailView.register(SceneDetailSwitchCell.self, forCellReuseIdentifier: SceneDetailSwitchCell.identifier)
        sceneDetailView.register(SceneDetailSelectorCell.self, forCellReuseIdentifier: SceneDetailSelectorCell.identifier)
        sceneDetailView.register(SceneDetailAddTextCell.self, forCellReuseIdentifier: SceneDetailAddTextCell.identifier)
        sceneDetailView.register(SceneDetailIconCell.self, forCellReuseIdentifier: SceneDetailIconCell.identifier)
    }
}
