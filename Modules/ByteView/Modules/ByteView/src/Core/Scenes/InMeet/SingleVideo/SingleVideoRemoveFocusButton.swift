//
//  SingleVideoRemoveFocusButton.swift
//  ByteView
//
//  Created by Tobb Huang on 2023/2/28.
//

import Foundation
import UniverseDesignIcon

class SingleVideoRemoveFocusButton: UIButton {

    private lazy var image: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.withdrawFocusOutlined, iconColor: .ud.iconN1, size: CGSize(width: 16, height: 16))
        return imageView
    }()

    private lazy var title: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = I18n.View_G_UnfocusVideoForAll
        titleLabel.textColor = .ud.textTitle
        titleLabel.font = .systemFont(ofSize: 16)
        return titleLabel
    }()

    init() {
        super.init(frame: .zero)

        layer.cornerRadius = 6
        layer.masksToBounds = true
        vc.setBackgroundColor(.ud.N00.withAlphaComponent(0.7), for: .normal)
        vc.setBackgroundColor(.ud.N350.withAlphaComponent(0.7), for: .highlighted)

        addSubview(image)
        image.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(10)
            make.size.equalTo(16)
        }

        addSubview(title)
        title.snp.makeConstraints { make in
            make.left.equalTo(image.snp.right).offset(4)
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open var isHighlighted: Bool {
        didSet {
            alpha = isHighlighted ? 0.9 : 1.0
        }
    }
}
