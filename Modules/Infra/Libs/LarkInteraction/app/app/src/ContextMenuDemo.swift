//
//  ContextMenuDemo.swift
//  LarkInteractionDev
//
//  Created by Saafo on 2021/10/8.
//

import Foundation
import UIKit
import LarkInteraction

class ContextMenuDemo: UIViewController {

    let colors: [UIColor] = [.red, .orange, .yellow, .green]

    override func viewDidLoad() {
        super.viewDidLoad()

        let table = UITableView()
        view.addSubview(table)
        table.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.height.equalTo(200)
            $0.width.equalTo(176)
        }
        table.rowHeight = 60
        table.dataSource = self
        table.delegate = self
    }
}

extension ContextMenuDemo: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        colors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.contentView.backgroundColor = colors[indexPath.row]
        cell.textLabel?.text = String(indexPath.row)
        if #available(iOS 13.4, *) {
//            cell.addContextMenu(.init(menu: <#T##([MenuElement]) -> MenuGroup?#>))
//            cell.addLKInteraction(PointerInteraction(style: PointerStyle(effect: .highlight)))
        }
        return cell
    }

    @available(iOS 13.0, *)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let action = UIAction(title: "123") { _ in }
        let actions = [action]
        let preview: () -> UIViewController = {
            let vc = Preview()
            let cell = tableView.cellForRow(at: indexPath)
            let copy = cell?.snapshotView(afterScreenUpdates: false)
            vc.subView = copy
            vc.preferredContentSize = CGSize(width: 176, height: 60)
            return vc
        }
        return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: preview) { _ in

            return UIMenu(title: "", children: actions)
        }
    }

    @available(iOS 13, *)
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = tableView.cellForRow(at: indexPath) else { return nil }
        let copy = cell.snapshotView(afterScreenUpdates: false)
//        UIApplication.shared.keyWindow?.addSubview(copy!)
        return UITargetedPreview(view: copy!, parameters: UIPreviewParameters(), target: UIPreviewTarget(container: tableView, center: cell.center, transform: CGAffineTransform(scaleX: 1.1, y: 1.1)))
    }
}

class Preview: UIViewController {
    var subView: UIView?
    override func viewDidLoad() {
        super.viewDidLoad()
        if let subView = subView {
            view.addSubview(subView)
            subView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
    }
}
