//
//  AvatarView.swift
//  ByteView
//
//  Created by wulv on 2021/11/19.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewUI

final class ChatAvatarView: UIView {

    enum Content {
        case key(_ key: String, userId: String, backup: UIImage?)
        case image(UIImage?)
    }

    private lazy var avatar = AvatarView()
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        return tapGesture
    }()


    var clickEnable: Bool = true
    var clickClosure: (() -> Void)?

    var content: Content? {
        didSet {
            guard let content = content else {
                imageView.isHidden = true
                avatar.isHidden = true
                return
            }

            switch content {
            case .key(let key, let id, let backup):
                if !key.isEmpty {
                    avatar.isHidden = false
                    imageView.isHidden = true
                    let info = AvatarInfo.remote(key: key, entityId: id)
                    avatar.setTinyAvatar(info)
                } else {
                    avatar.isHidden = true
                    imageView.isHidden = false
                    imageView.image = backup
                }
            case .image(let image):
                avatar.isHidden = true
                imageView.isHidden = false
                imageView.image = image
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        clipsToBounds = true
        layer.masksToBounds = true

        addGestureRecognizer(tapGesture)
        tapGesture.rx.event.bind { [weak self] _ in
            guard self?.clickEnable == true else { return }
            guard let closure = self?.clickClosure else { return }
            closure()
        }
        .disposed(by: rx.disposeBag)

        addSubview(imageView)
        imageView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        imageView.isHidden = true

        addSubview(avatar)
        avatar.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        avatar.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
