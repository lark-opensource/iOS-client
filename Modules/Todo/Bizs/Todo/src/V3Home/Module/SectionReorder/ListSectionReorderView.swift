//
//  ListSectionReorderView.swift
//  Todo
//
//  Created by wangwanxin on 2023/1/29.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignFont

final class ListSectionReorderCellFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForInteractivelyMovingItem(at indexPath: IndexPath, withTargetPosition position: CGPoint) -> UICollectionViewLayoutAttributes {
        let attributes = super.layoutAttributesForInteractivelyMovingItem(at: indexPath, withTargetPosition: position)
        attributes.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        return attributes
    }
}

final class ListSectionReorderCell: UICollectionViewCell {

    var text: String? {
        didSet { textLabel.text = text }
    }

    var showSeparateLine: Bool = true {
        didSet { separateLine.isHidden = !showSeparateLine }
    }

    private var textLabel: UILabel = {
        let contentLabel = UILabel()
        contentLabel.font = UDFont.systemFont(ofSize: 16)
        contentLabel.textColor = UIColor.ud.textTitle
        contentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return contentLabel
    }()

    private let reorderBtn: UIButton = {
        let btn = UIButton()
        let icon = UDIcon.getIconByKey(.menuOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 20, height: 20))
        btn.setImage(icon, for: .normal)
        return btn
    }()

    private lazy var separateLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgFloat

        contentView.addSubview(reorderBtn)
        reorderBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-12)
            make.height.equalToSuperview()
            make.width.equalTo(20)
        }

        contentView.addSubview(textLabel)
        textLabel.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(reorderBtn.snp.left).offset(-16)
        }

        contentView.addSubview(separateLine)
        separateLine.snp.makeConstraints { make in
            make.left.equalTo(textLabel.snp.left)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
