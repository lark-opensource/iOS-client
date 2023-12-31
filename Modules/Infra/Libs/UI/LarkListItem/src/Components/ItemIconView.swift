//
//  ItemIconView.swift
//  LarkListItem
//
//  Created by Yuri on 2023/8/11.
//

import UIKit

final public class ItemIconView: UIView, ItemViewContextable {
    var context: ListItemContext

    let imgView = UIImageView()
    public let avatarView = PickerAvatarView()
    public lazy var docIconView = { ItemDocIconView(context: context) }()

    public var icon: ListItemNode.Icon? {
        didSet {
            guard let icon else { return }
            avatarView.image = nil
            avatarView.isHidden = true
            imgView.isHidden = true
            docIconView.isHidden = true
            switch icon {
            case .local(let image):
                imgView.isHidden = false
                imgView.image = image
                imgView.image = image
            case .remote(let id, let key):
                avatarView.isHidden = false
                avatarView.style = .circle
                avatarView.setAvatarByIdentifier(id, avatarKey: key ?? "", avatarSize: 48)
            case .avatarImageURL(let imageURL):
                avatarView.isHidden = false
                avatarView.style = .circle
                avatarView.setAvatarByImageURL(imageURL)
            case .docIcon(let info):
                docIconView.isHidden = false
                docIconView.info = info
            case .avatar(let id, let key):
                avatarView.isHidden = false
                avatarView.setAvatarByIdentifier(id, avatarKey: key ?? "", avatarSize: 48)
            default: break
        }
        }
    }

    public init(context: ListItemContext) {
        self.context = context
        super.init(frame: .zero)
        render()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        addSubview(imgView)
        addSubview(avatarView)
        addSubview(docIconView)
        imgView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        avatarView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        docIconView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
