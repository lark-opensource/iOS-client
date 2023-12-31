//
//  IconView.swift
//  ByteView
//
//  Created by fakegourmet on 2020/12/8.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation

public final class IconView: UIView {
    public var iconBackgroundColor: UIColor? {
        get {
            iconBgView.backgroundColor
        }
        set {
            iconBgView.backgroundColor = newValue
        }
    }

    public var iconBackgroundCornerRadius: CGFloat {
        get {
            iconBgView.layer.cornerRadius
        }
        set {
            iconBgView.layer.cornerRadius = newValue
        }
    }

    public var image: UIImage? {
        get {
            imageView.image
        }
        set {
            imageView.image = newValue
        }
    }

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var iconBgView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(iconBgView)
        addSubview(imageView)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        iconBgView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(1)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
