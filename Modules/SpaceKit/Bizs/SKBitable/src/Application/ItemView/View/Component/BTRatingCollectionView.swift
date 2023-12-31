//
//  BTRatingCollectionView.swift
//  SKBitable
//
//  Created by yinyuan on 2023/2/17.
//

import Foundation
import UniverseDesignColor
import SKFoundation

final class BTRatingCell: UICollectionViewCell {
    
    /// 是否居中布局
    fileprivate var formEditStyle = false {
        didSet {
            ratingView.isUserInteractionEnabled = formEditStyle
            remakeConstraints()
        }
    }
    
    lazy var ratingView: BTRatingView = {
        let view = BTRatingView()
        return view
    }()
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.backgroundColor = .clear
        contentView.addSubview(ratingView)
        remakeConstraints()
    }
    
    private func remakeConstraints() {
        ratingView.snp.remakeConstraints { make in
            if formEditStyle {
                make.center.equalToSuperview()
                make.height.equalToSuperview()
            } else {
                make.left.equalToSuperview()
                make.centerY.equalToSuperview()
                make.height.equalTo(20)
            }
        }
    }
}

final class BTRatingCollectionView: UICollectionView {
    
    weak var ratingDelegate: BTRatingViewDelegate?
    
    public var fieldModel: BTFieldModel = BTFieldModel(recordID: "") {
        didSet {
            reloadData()
        }
    }
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = BTFieldLayout.Const.ratingItemSpacing
        super.init(frame: .zero, collectionViewLayout: layout)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.backgroundColor = .clear
        self.delegate = self
        self.dataSource = self
        self.insetsLayoutMarginsFromSafeArea = false
        self.bounces = false
        self.contentInsetAdjustmentBehavior = .never
        self.isScrollEnabled = true
        self.delaysContentTouches = false
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.register(BTRatingCell.self, forCellWithReuseIdentifier: BTRatingCell.reuseIdentifier)
    }
}

extension BTRatingCollectionView: UICollectionViewDelegateFlowLayout {
    
    private func cellSize() -> CGSize {
        var width = fieldModel.width
        let formEditStyle = fieldModel.isInForm && fieldModel.editable
        if !formEditStyle {
            width -= (BTFieldLayout.Const.containerLeftRightMargin * 2 - BTFieldLayout.Const.containerPadding * 2)
            width -= (BTFieldLayout.Const.panelIndicatorWidthHeight + BTFieldLayout.Const.panelIndicatorRightMargin)
        }
        let height = formEditStyle ? BTFieldLayout.Const.ratingItemHeightInForm : BTFieldLayout.Const.ratingItemHeight
        return CGSize(width: max(0, width), height: height)
    }
    
    private func cellSizeV2() -> CGSize {
        return CGSize(width: bounds.width, height: BTFieldLayout.Const.ratingItemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return fieldModel.usingLayoutV2 ? cellSizeV2() : cellSize()
    }
}

extension BTRatingCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 至少得显示 1 个，空的话也要显示
        return max(1, fieldModel.numberValue.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BTRatingCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? BTRatingCell {
            var value: Int?
            if indexPath.item < fieldModel.numberValue.count {
                let numberModel = fieldModel.numberValue[indexPath.item]
                value = Int(numberModel.rawValue)
            } else {
                // 空状态
                value = nil
            }
            
            let formEditStyle = fieldModel.isInForm && fieldModel.editable
            let symbol = fieldModel.property.rating?.symbol ?? BTRatingModel.defaultSymbol
            
            let max = Int(fieldModel.property.max ?? 1)
            let min = Int(fieldModel.property.min ?? 5)
            
            let config = BTRatingView.ratingConfig(with: min,
                                                   maxValue: max,
                                                   maxWidth: cellSize().width,
                                                   formEditStyle: formEditStyle,
                                                   symbol: symbol)
            
            cell.ratingView.update(config, value)
            
            if cell.formEditStyle != formEditStyle {
                cell.formEditStyle = formEditStyle
            }
            
            cell.ratingView.delegate = ratingDelegate
        }
        return cell
    }
}
