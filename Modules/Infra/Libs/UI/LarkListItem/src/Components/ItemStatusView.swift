//
//  ItemStatusView.swift
//  LarkListItem
//
//  Created by Yuri on 2023/10/8.
//

import UIKit
import SnapKit

class ItemStatusView: UIView, ItemViewContextable {
    var context: ListItemContext

    var node: ListItemNode? {
        didSet {
            let tagView = context.statusService?.generateStatusView(status: node?.status)
            if let tagView {
                subviews.forEach { $0.removeFromSuperview() }
                addSubview(tagView)
                tagView.snp.makeConstraints {
                    $0.edges.equalToSuperview()
                }
            }
            self.isHidden = tagView == nil
        }
    }

    init(context: ListItemContext) {
        self.context = context
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
