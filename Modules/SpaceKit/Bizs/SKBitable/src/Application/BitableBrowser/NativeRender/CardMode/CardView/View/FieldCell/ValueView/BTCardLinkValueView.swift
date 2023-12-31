//
//  BTCardLinkValueView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/1.
//

import Foundation
import UniverseDesignFont
import UniverseDesignColor

fileprivate struct Const {
    static let cornerRadius: CGFloat = 4.0
    static let font: UIFont = UDFont.caption0
    static let itemHeight: CGFloat = 20.0
    static let itemSpacing: CGFloat = 4.0
    static let linkItemTextInset: CGFloat = 6.0
    static let textColor: UIColor = UDColor.textTitle
    static let itemBackgorundCorlor = UDColor.fillTag.withAlphaComponent(0.1)
}

fileprivate class BTCardLinkItem: UIView, BTSingleContainerItemProtocol {
    
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
            make.left.greaterThanOrEqualToSuperview().offset(Const.linkItemTextInset)
            make.right.lessThanOrEqualToSuperview().offset(-Const.linkItemTextInset)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
    }
    
    
    func setData(_ text: String) {
        label.text = text
    }
    
    func itemWidth() -> CGFloat {
        return Const.linkItemTextInset + ceil(label.intrinsicContentSize.width) + Const.linkItemTextInset
    }
}

final class BTCardLinkValueView: UIView {
    
    private lazy var singleLineContainer: BTSingleLineContainerView = {
        let config = BTSingleLineContainerView.Config(itemSpacing: 4.0, itemHeight: 20.0)
        let container =  BTSingleLineContainerView(with: config)
        container.dataSource = self
        return container
    }()
    
    private var datas: [BTLinkData] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(singleLineContainer)
        singleLineContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension BTCardLinkValueView: BTCellValueViewProtocol {
    
    func setData(_ model: BTCardFieldCellModel, containerWidth: CGFloat) {
        let datas = model.getFieldData(type: BTLinkData.self)
        self.datas = datas
        if !datas.isEmpty {
            singleLineContainer.layout(with: containerWidth)
        }
    }
}

extension BTCardLinkValueView: BTSingleLineContainerViewDataSource {
    func numberOfItem() -> Int {
        datas.count
    }
    
    func itemView(for index: Int) -> BTSingleContainerItemProtocol {
        let item = BTCardLinkItem()
        if let data = datas.safe(index: index) {
            item.setData(data.text)
        }
        return item
    }
    
    func countView(for remain: Int) -> BTSingleContainerItemProtocol {
        let item = BTCardLinkItem()
        item.setData("+\(remain)")
        return item
    }
    
}
