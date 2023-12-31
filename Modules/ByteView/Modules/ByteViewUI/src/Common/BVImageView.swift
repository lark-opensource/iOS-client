//
//  BVImageView.swift
//  ByteViewUI
//
//  Created by lutingting on 2022/12/27.
//

import Foundation

public final class BVImageView: UIView {
    public var edgeInsets: UIEdgeInsets = .zero {
        didSet {
            updateLayout()
        }
    }

    public var image: UIImage? {
        didSet {
            guard image != oldValue else { return }
            imageView.image = image
        }
    }


    lazy var imageView: UIImageView = {
        let emoji = UIImageView()
        emoji.backgroundColor = .clear
        emoji.contentMode = .scaleAspectFit
        return emoji
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(edgeInsets)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateLayout() {
        imageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(edgeInsets)
        }
    }

}
