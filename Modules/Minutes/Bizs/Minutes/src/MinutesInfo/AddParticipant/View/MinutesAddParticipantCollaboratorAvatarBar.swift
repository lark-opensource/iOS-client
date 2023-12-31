//
//  MinutesShareCollaboratorAvatarBar.swift
//  Minutes
//
//  Created by panzaofeng on 2021/6/16.
//  Copyright © 2021年 panzaofeng. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import Kingfisher
import MinutesNetwork

@objc protocol AddParticipantCollaboratorAvatarBarDelegate: UIScrollViewDelegate {
    @objc
    optional func avatarBar(_ bar: AddParticipantCollaboratorAvatarBar, didSelectAt index: Int)
}

struct AddParticipantAvatarBarItem {
    var button: AddParticipantAvatarBarButton?
    let id: String
    let imageURL: URL?
    let image: UIImage?
}

class AddParticipantAvatarBarButton: UIButton {
    let index: Int

    init(index: Int) {
        self.index = index
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Collaborator TableView
class AddParticipantCollaboratorAvatarBar: UIScrollView {
    var items = [AddParticipantAvatarBarItem]()
    func setImages(items: [AddParticipantAvatarBarItem], progressHandle: ((UIImage?, Error?) -> Void)? = nil, complete: (() -> Void)? = nil) {
        self.items.forEach { (item) in
            item.button?.removeFromSuperview()
        }
        self.items.removeAll()
        var index = 0
        for var item in items {
            let button = AddParticipantAvatarBarButton(index: index)
            index += 1
            button.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
            button.layer.cornerRadius = 16
            button.layer.masksToBounds = true
            item.button = button
            self.items.append(item)
            self.addSubview(button)
            // 更新图片，如果提供了本地图片就用本地的，没有的话再通过URL下载
            if let image = item.image {
                button.setImage(image, for: .normal)
            } else {
                if let urlStr = item.imageURL {
                    button.setAvatarImage(with: urlStr, for: .normal, placeholder: UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: 48, color: UIColor.ud.N300))
                } else {
                    button.setImage(UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: 48, color: UIColor.ud.N300), for: .normal)
                }
            }
        }
        self.contentSize.width = 16 + CGFloat(self.items.count) * (32 + 10)
        complete?()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = self.bounds.size.height
        self.contentSize.height = size
        let itemSize = CGSize(width: 32, height: 32)
        for index in 0..<self.items.count {
            self.items[index].button?.frame = CGRect(x: 16 + CGFloat(index) * (32 + 10), y: 8, width: itemSize.width, height: itemSize.height)
        }
    }

    @objc
    private func buttonAction(sender: UIButton) {
        guard let button = sender as? AddParticipantAvatarBarButton else { return }
        (self.delegate as? AddParticipantCollaboratorAvatarBarDelegate)?.avatarBar?(self, didSelectAt: button.index)
    }
}
