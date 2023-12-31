//  Created by Songwen Ding on 2018/4/9.

import UIKit
import Kingfisher
import SKResource

@objc protocol CollaboratorAvatarBarDelegate: UIScrollViewDelegate {
    @objc
    optional func avatarBar(_ bar: CollaboratorAvatarBar, didSelectAt index: Int)
}

struct AvatarBarItem {
    var button: AvatarBarButton?
    let id: String
    let imageURL: String?
    let imageKey: String?
    let image: UIImage?
}

class AvatarBarButton: UIButton {
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
class CollaboratorAvatarBar: UIScrollView {
    var items = [AvatarBarItem]()
    func setImages(items: [AvatarBarItem], progressHandle: ((UIImage?, Error?) -> Void)? = nil, complete: (() -> Void)? = nil) {
        self.items.forEach { (item) in
            item.button?.removeFromSuperview()
        }
        self.items.removeAll()
        var index = 0
        for var item in items {
            let button = AvatarBarButton(index: index)
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
                if let urlStr = item.imageURL, !urlStr.isEmpty {
                    if let image = ImageCache.default.retrieveImageInMemoryCache(forKey: urlStr.hashValue.description) {
                        button.setImage(image, for: .normal)
                        continue
                    } else if let url = URL(string: urlStr) {
                        let resource = ImageResource(downloadURL: url, cacheKey: urlStr.hashValue.description)
                        button.kf.setImage(with: resource, for: .normal, placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
                    } else {
                        button.setImage(BundleResources.SKResource.Common.Collaborator.avatar_placeholder, for: .normal)
                    }
                } else if let imageKey = item.imageKey, !imageKey.isEmpty {
                    let fixedKey = imageKey.replacingOccurrences(of: "lark.avatar/", with: "")
                        .replacingOccurrences(of: "mosaic-legacy/", with: "")
                    button.bt.setLarkImage(with: .avatar(key: fixedKey, entityID: item.id),
                                           for: .normal,
                                           placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
                } else {
                    button.setImage(BundleResources.SKResource.Common.Collaborator.avatar_placeholder, for: .normal)
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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = self.bounds.size.height
        self.contentSize.height = size
        for index in 0..<self.items.count {
            self.items[index].button?.frame = CGRect(x: 16 + CGFloat(index) * (32 + 10), y: 0, width: size, height: size)
        }
    }

    @objc
    private func buttonAction(sender: UIButton) {
        guard let button = sender as? AvatarBarButton else { return }
        (self.delegate as? CollaboratorAvatarBarDelegate)?.avatarBar?(self, didSelectAt: button.index)
    }
}
