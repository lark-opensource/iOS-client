//
//  ItemDocIconView.swift
//  LarkListItem
//
//  Created by Yuri on 2023/8/10.
//

import UIKit
import SnapKit

final public class ItemDocIconView: UIView, ItemViewContextable {
    var context: ListItemContext

    let service = DocIconService()
    var imageView = UIImageView()

    var info: ListItemNode.DocIcon? {
        didSet {
            guard let info else {
                imageView.image = nil
                return
            }
            requestImage(info: info)
        }
    }

    init(context: ListItemContext) {
        self.context = context
        super.init(frame: .zero)
        render()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func requestImage(info: ListItemNode.DocIcon) {
        service.requestImage(userId: context.userId, info: info) { [weak self] image in
            self?.imageView.image = image
        }
    }
}
