//
//  BTSingleLineCapsuleView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/10/31.
//

import Foundation
import SKBrowser
import UniverseDesignFont
import UniverseDesignColor

extension BTCapsuleUIConfiguration {
    static let singleLineCapsule = BTCapsuleUIConfiguration(rowSpacing: 4.0,
                                                            colSpacing: 4.0,
                                                            lineHeight: 20.0,
                                                            textInsets: UIEdgeInsets(top: 0, left: 8.0, bottom: 0.0, right: 8.0),
                                                            font: UDFont.caption0)
    static let singleLineIconCapsule = BTCapsuleUIConfiguration(rowSpacing: 4.0,
                                                                colSpacing: 4.0,
                                                                lineHeight: 20.0,
                                                                textInsets: UIEdgeInsets(top: 0, left: 22.0, bottom: 0.0, right: 6.0),
                                                                font: UDFont.caption0,
                                                                avatarConfig: AvatarConfiguration(avatarLeft: 2.0, avatarSize: 16.0))
}

fileprivate class BTSingleLineCapsuleItemView: UIView, BTSingleContainerItemProtocol {
    
    struct Const {
        static let textInset: CGFloat = 8.0
        static let itemBackgorundCorlor = UDColor.fillTag.withAlphaComponent(0.1)
        static let font: UIFont = UDFont.caption0
        static let textColor: UIColor = UDColor.textTitle
        static let cornerRadius: CGFloat = 10.0
    }
    
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = Const.itemBackgorundCorlor
        layer.cornerRadius = Const.cornerRadius
        label.font = Const.font
        label.textColor = Const.textColor
        label.textAlignment = .left
        addSubview(label)
        label.snp.makeConstraints { make in
            make.left.greaterThanOrEqualToSuperview().offset(Const.textInset)
            make.right.lessThanOrEqualToSuperview().offset(-Const.textInset)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
    }
    
    
    func setData(_ text: String) {
        label.text = text
    }
    
    func itemWidth() -> CGFloat {
        return Const.textInset + ceil(label.intrinsicContentSize.width) + Const.textInset
    }
}

class BTSingleLineCapsuleView: BTSingleLineContainerView {
    
    private var config: BTCapsuleUIConfiguration
    private var models: [BTCapsuleModel] = []
    private var containerWidth: CGFloat = 0
    
    required init(with config: BTCapsuleUIConfiguration) {
        self.config = config
        let containerConfig = BTSingleLineContainerView.Config(itemSpacing: config.rowSpacing, itemHeight: config.lineHeight)
        super.init(with: containerConfig)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(with config: Config) {
        fatalError("init(with:) has not been implemented")
    }
    
    func setup() {
        self.dataSource = self
    }
    
    private func set(with models: [BTCapsuleModel], containerWidth: CGFloat) {
        if !models.isEmpty {
            self.containerWidth = containerWidth
            self.models = models
            layout(with: containerWidth)
        }
    }
    
}

extension BTSingleLineCapsuleView: BTCellValueViewProtocol {
    
    func setData(_ model: BTCardFieldCellModel, containerWidth: CGFloat) {
        if model.fieldUIType.isPlainCapusule {
            let data = model.getFieldData(type: BTCapsuleData.self)
            let capusles = data.map { $0.toCapsule() }
            set(with: capusles, containerWidth: containerWidth)
        } else if model.fieldUIType.isIconCapusle {
            let data = model.getFieldData(type: BTIConCapsuleData.self)
            let capusles = data.map { $0.toCapsule() }
            set(with: capusles, containerWidth: containerWidth)
        }
    }
}

extension BTSingleLineCapsuleView: BTSingleLineContainerViewDataSource {
    func numberOfItem() -> Int {
        return models.count
    }
    
    func itemView(for index: Int) -> BTSingleContainerItemProtocol {
        let isIconCapsule = config.avatarConfig != nil
        let cell = isIconCapsule ? BTCapsuleCellWithAvatar() : BTCapsuleCell()
        if let model = models.safe(index: index) {
            cell.setupCell(model, maxLength: containerWidth, layoutConfig: config)
        }
        return cell
    }
    
    func countView(for remain: Int) -> BTSingleContainerItemProtocol {
        let item = BTSingleLineCapsuleItemView()
        let text = "+\(remain)"
        item.setData(text)
        return item
    }
}

fileprivate extension BTFieldUIType {
    
    var isIconCapusle: Bool {
        return self == .user || self == .group || self == .lastModifyUser || self == .createUser
    }
    var isPlainCapusule: Bool {
        return self == .singleSelect || self == .multiSelect
    }
}
