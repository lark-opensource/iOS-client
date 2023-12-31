//
//  BTCardAttachmentValueView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/2.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont

fileprivate struct Const {
    static let iconSpacing: CGFloat = 4.0
    static let textFont: UIFont = UDFont.body2
    static let textColor: UIColor = UDColor.textTitle
    static let iconSize: CGFloat = 16.0
}

final class BTCardAttachmentValueView: UIView {
    
    private lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.attachmentOutlined.ud.withTintColor(UDColor.iconN2)
        return view
    }()
    
    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.textColor = Const.textColor
        label.font = Const.textFont
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(iconImageView)
        addSubview(countLabel)
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(Const.iconSize)
        }
        countLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(Const.iconSpacing)
            make.right.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}

extension BTCardAttachmentValueView: BTCellValueViewProtocol {
    
    func setData(_ model: BTCardFieldCellModel, containerWidth: CGFloat) {
        let data = model.getFieldData(type: BTAttachmentData.self)
        let count = data.count
        countLabel.text = "\(count)"
    }
}
