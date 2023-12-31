//
//  BTStageField.swift
//  SKBitable
//
//  Created by X-MAN on 2023/5/29.
//

import Foundation
import UniverseDesignColor
import SKBrowser
import SKFoundation

final class BTStageFieldItemCell: UICollectionViewCell {
    
    private lazy var item: BTStageItemView = {
        let item = BTStageItemView(with: .big)
        return item
    }()
    
    private static let inset: CGFloat = 10.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        contentView.addSubview(item)
        contentView.layer.cornerRadius = 6
        item.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Self.inset)
            make.trailing.equalToSuperview().offset(-Self.inset)
            make.top.bottom.equalToSuperview()
        }
    }
    
    func config(_ model: BTStageModel, color: UIColor) {
        item.configInField(name: model.name, type: model.type)
        contentView.backgroundColor = color
    }
    
    static func width(model: BTStageModel) -> CGFloat {
        return BTStageItemView.width(with: model.name, style: .big) + 2 * inset
    }
    
}

final class BTStageItemFlowLayout: UICollectionViewFlowLayout {
    
    private var model: BTFieldModel = BTFieldModel(recordID: "")
    
    func updateModel(_ model: BTFieldModel) {
        self.model = model
    }
    
    var cachedAttrs: [UICollectionViewLayoutAttributes] = []
    var cachedHeight: CGFloat = 0
    
    /// 返回结果 第一个为容器最大高度， 第二个contentSize 第三个为cell布局
    static func getLayoutInfo(with model: BTFieldModel, containerWidth: CGFloat) -> (CGFloat, CGFloat, [UICollectionViewLayoutAttributes]) {
        let models = BTStageField.getStageList(model)
        guard models.count > 1 else {
            let defaultHeight = BTFieldLayout.Const.stageFieldContainerHeight
            return (defaultHeight, defaultHeight, [])
        }
        var attrs = [UICollectionViewLayoutAttributes]()
        let itemSpacing = BTStageField.itemSpacing
        let lineSpacging = BTStageField.lineSpacing
        let itemHeight = BTStageField.itemHeight
        let inset = BTStageField.inset
        var x: CGFloat = inset.left
        var y: CGFloat = inset.top
        var height = BTFieldLayout.Const.stageFieldContainerHeight
        for (index, (option, _)) in models.enumerated() {
            let isFirst = x == inset.left
            let itemWidth = min(BTStageFieldItemCell.width(model: option), containerWidth - inset.left * 2)
            // 预计算最右边
            let destRight = x + itemWidth
            if destRight + inset.right < containerWidth {
                // 不换行，继续计算
                let attr = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: index, section: 0))
                attr.frame = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)
                attrs.append(attr)
                x = destRight + itemSpacing
            } else if destRight + inset.right > containerWidth {
                // 换行
                y = y + itemHeight + lineSpacging
                height = height + itemHeight + lineSpacging
                let attr = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: index, section: 0))
                attr.frame = CGRect(x: inset.left, y: y, width: itemWidth, height: itemHeight)
                attrs.append(attr)
                x = inset.left + itemWidth + itemSpacing
            } else {
                // 刚好等于
                let attr = UICollectionViewLayoutAttributes(forCellWith: IndexPath(row: index, section: 0))
                attr.frame = CGRect(x: isFirst ? x : x + itemSpacing, y: y, width: itemWidth, height: itemHeight)
                attrs.append(attr)
                x = containerWidth
            }
        }
        return (min(height, 258), height, attrs)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let width = collectionView?.bounds.width else { return nil }
        let result = Self.getLayoutInfo(with: model, containerWidth: width)
        cachedAttrs = result.2
        cachedHeight = result.1
        return cachedAttrs
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cachedAttrs.safe(index: indexPath.row)
    }
    
    override var collectionViewContentSize: CGSize {
        guard let width = collectionView?.bounds.width else { return .zero }
        return CGSize(width: width, height: cachedHeight)
    }
}

final class BTStageField: BTBaseField {
        
    private lazy var itemView: BTStageItemView = {
        let item = BTStageItemView(with: .big)
        return item
    }()
    
    static let itemSpacing: CGFloat = 4
    static let lineSpacing: CGFloat = 4
    static let itemHeight: CGFloat = 24
    static let inset = UIEdgeInsets(top: 6,
                                    left: 6,
                                    bottom: 6,
                                    right: 6)

    
    private lazy var collectionView: UICollectionView = {
        let layout = BTStageItemFlowLayout()
        layout.minimumInteritemSpacing = Self.lineSpacing
        layout.minimumLineSpacing = Self.itemSpacing
        layout.scrollDirection = .vertical
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.dataSource = self
        collection.delegate = self
        collection.showsVerticalScrollIndicator = false
        collection.contentInset = .zero
        collection.backgroundColor = .clear
        collection.register(BTStageFieldItemCell.self, forCellWithReuseIdentifier: BTStageFieldItemCell.reuseIdentifier)
        return collection
    }()
    
    private var dataSource: [(BTStageModel, UIColor)] {
        return Self.getStageList(fieldModel)
    }
    
    static func getStageList(_ fieldModel: BTFieldModel) -> [(BTStageModel, UIColor)] {
        let stages = fieldModel.property.stages
        guard !stages.isEmpty else { return [] }
        return fieldModel.optionIDs.map { optionId in
            if var option = stages.first(where: { $0.id == optionId }) {
                let colorModel = fieldModel.colors.first(where: { $0.id == option.color }) ?? BTColorModel()
                switch option.type {
                case .defualt:
                    option.status = .progressing
                case .endDone:
                    if let lastDefault = stages.last(where: { $0.type == .defualt }) {
                        option = lastDefault
                    } else {
                        // 异常处理
                        DocsLogger.btError("[BTStageField] cant not find default option")
                    }
                    option.status = .finish
                    option.type = .endDone
                case .endCancel:
                    option.status = .finish
                }
                return (option, UIColor.docs.rgb(colorModel.color))
            } else {
                return (fieldModel.property.stages[0], UIColor.docs.rgb(BTColorModel().color))
            }
        }
    }
    
    override func setupLayout() {
        super.setupLayout()
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        containerView.addSubview(itemView)
    }
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        if model.optionIDs.count > 1, model.compositeType.isCalculationType {
            itemView.isHidden = true
            collectionView.isHidden = false
            (collectionView.collectionViewLayout as? BTStageItemFlowLayout)?.updateModel(model)
            collectionView.reloadData()
            containerView.layer.borderWidth = BTFieldLayout.Const.containerBorderWidth
            containerView.layer.ud.setBorderColor(UDColor.lineBorderComponent)
            updateBorderMode(.normal)
            updateContainerColor()
        } else {
            updateBorderMode(.none)
            itemView.isHidden = false
            collectionView.isHidden = true
            if let cuttentOpionId = model.optionIDs.first ?? model.property.stages.first?.id,
               var option = model.property.stages.first(where: { $0.id == cuttentOpionId }) {
                let colorModel = model.colors.first(where: { $0.id == option.color }) ?? BTColorModel()
                switch option.type {
                case .defualt:
                    option.status = .progressing
                case .endDone:
                    if let lastDefault = model.property.stages.last(where: { $0.type == .defualt }) {
                        option = lastDefault
                    } else {
                        // 异常处理
                        DocsLogger.btError("[BTStageField] cant not find default option")
                    }
                    option.status = .finish
                    option.type = .endDone
                case .endCancel:
                    option.status = .finish
                }
                containerView.backgroundColor = UIColor.docs.rgb(colorModel.color)
                itemView.configInField(name: option.name, type: option.type)
                let itemWidth = itemView.width()
                itemView.snp.remakeConstraints { make in
                    make.top.bottom.equalToSuperview()
                    make.centerX.equalToSuperview()
                    make.width.lessThanOrEqualTo(itemWidth)
                    make.left.greaterThanOrEqualToSuperview().offset(12)
                    make.right.lessThanOrEqualToSuperview().offset(-12)
                }
            }
        }
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(gotoDetail))
        tapGR.delegate = self
        containerView.addGestureRecognizer(tapGR)
    }
    
    @objc
    private func gotoDetail() {
        // 计算字段不应该跳转
        guard !fieldModel.compositeType.isCalculationType,
              fieldModel.uneditableReason != .drillDown,
              fieldModel.uneditableReason != .notSupported,
              fieldModel.uneditableReason != .bitableNotReady,
              fieldModel.uneditableReason != .isExtendField,
              fieldModel.uneditableReason != .proAdd
        else {
            showUneditableToast()
            return
        }
        delegate?.stageFieldClick(with: fieldModel)
    }
    
}

extension BTStageField: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}

extension BTStageField: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BTStageFieldItemCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? BTStageFieldItemCell, let (option, color) = dataSource.safe(index: indexPath.row) {
            cell.config(option, color: color)
        }
        return cell
    }
}

extension BTStageField: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let (option, _) = dataSource.safe(index: indexPath.row) {
            return CGSize(width: min(BTStageFieldItemCell.width(model: option), fieldModel.width - Self.inset.left * 2), height: Self.itemHeight)
        }
        return .zero
    }
}
