//
//  BTCardCheckBoxValueView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/2.
//

import Foundation
import SKResource
import UniverseDesignFont
import UniverseDesignColor

fileprivate struct Const {
    static let singleLineContainerConfig = BTSingleLineContainerView.Config(itemSpacing: 4.0, itemHeight: 16.0)
    static let countItemTextInset: CGFloat = 4.0
    static let countFont: UIFont = UDFont.caption0
    static let countBackgroundColor = UDColor.fillTag.withAlphaComponent(0.1)
    static let textColor: UIColor = UDColor.textTitle
    static let countRadius: CGFloat = 2.0
    static let itemRadius: CGFloat = 4.0
}

final class BTCardCheckBoxItemView: UIButton, BTSingleContainerItemProtocol {
    
    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        layer.cornerRadius = Const.itemRadius
        setImage(BundleResources.SKResource.Bitable.icon_bitable_checkbox_off, for: [.normal, .highlighted])
        setImage(BundleResources.SKResource.Bitable.icon_bitable_checkbox_on, for: .selected)
        contentHorizontalAlignment = .fill
        contentVerticalAlignment = .fill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func itemWidth() -> CGFloat {
        return Const.singleLineContainerConfig.itemHeight
    }
    
    func checked(_ checked: Bool) {
        self.isSelected = checked
    }
}

final class BTCardCheckBoxValueView: UIView {
    
    private lazy var valueContainer: BTSingleLineContainerView = {
        let config = Const.singleLineContainerConfig
        let view = BTSingleLineContainerView(with: config)
        view.dataSource = self
        return view
    }()
    
    private var datas: [BTCheckBoxData] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(valueContainer)
        valueContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension BTCardCheckBoxValueView: BTCellValueViewProtocol {
    
    func setData(_ model: BTCardFieldCellModel, containerWidth: CGFloat) {
        let datas = model.getFieldData(type: BTCheckBoxData.self)
        self.datas = datas
        if !datas.isEmpty {
            valueContainer.layout(with: containerWidth)
        }
    }
}

extension BTCardCheckBoxValueView: BTSingleLineContainerViewDataSource {
    
    private class CountItem: UIView, BTSingleContainerItemProtocol {
        
        let label = UILabel()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setup() {
            layer.cornerRadius = Const.countRadius
            backgroundColor = Const.countBackgroundColor
            label.font = Const.countFont
            label.textColor = Const.textColor
            addSubview(label)
            label.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(Const.countItemTextInset)
                make.centerY.equalToSuperview()
            }
        }
        
        func setData(_ text: String) {
            label.text = text
        }
        
        func itemWidth() -> CGFloat {
            return ceil(label.intrinsicContentSize.width) + Const.countItemTextInset * 2
        }
    }
    
    func numberOfItem() -> Int {
        return datas.count
    }
    
    func itemView(for index: Int) -> BTSingleContainerItemProtocol {
        let item = BTCardCheckBoxItemView()
        if let data = datas.safe(index: index) {
            item.checked(data.checked)
        }
        return item
    }
    
    func countView(for remain: Int) -> BTSingleContainerItemProtocol {
        let item = CountItem()
        item.setData("+\(remain)")
        return item
    }
}
