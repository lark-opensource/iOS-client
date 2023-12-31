//
//  BTFieldV2Stage.swift
//  SKBitable
//
//  Created by X-MAN on 2023/8/8.
//

import Foundation
import SKFoundation
import SKBrowser
import UniverseDesignColor

fileprivate let ContainerCornerRadius: CGFloat = 6.0

final class BTStageFieldItemCellV2: UICollectionViewCell {
    
    private lazy var item: BTStageItemView = {
        let item = BTStageItemView(with: .big)
        return item
    }()
    
    private static let inset: CGFloat = 8.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        contentView.addSubview(item)
        contentView.layer.cornerRadius = ContainerCornerRadius
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

final class BTStageItemFlowLayoutV2: UICollectionViewFlowLayout {
    
    private var model: BTFieldModel = BTFieldModel(recordID: "")
    
    func updateModel(_ model: BTFieldModel) {
        self.model = model
    }
    
    var cachedAttrs: [UICollectionViewLayoutAttributes] = []
    var cachedHeight: CGFloat = 0
    
    static func caculateWidthForSingleLine(with model: BTFieldModel, maxWidth: CGFloat) -> CGFloat {
        let stages = BTStageField.getStageList(model)
        if stages.count == 0 {
            return 0
        } else if stages.count == 1 {
            let width = BTFieldV2Stage.getItemWidth(model)
            return width > maxWidth ? CGFloat.greatestFiniteMagnitude : width
        } else {
            let inset = BTFieldV2Stage.inset
            var currentWidth: CGFloat = inset.left
            for stage in stages {
                currentWidth += BTFieldV2Stage.itemSpacing + BTStageFieldItemCellV2.width(model: stage.0) + inset.right
                if currentWidth >= maxWidth {
                    return CGFloat.greatestFiniteMagnitude
                } else {
                    currentWidth -= inset.right
                }
            }
            return currentWidth + inset.right
        }
    }
    
    /// 返回结果 第一个为容器最大高度， 第二个contentSize 第三个为cell布局
    static func getLayoutInfo(with model: BTFieldModel, containerWidth: CGFloat) -> (CGFloat, CGFloat, [UICollectionViewLayoutAttributes]) {
        let models = BTStageField.getStageList(model)
        guard models.count > 1 else {
            let defaultHeight = BTFieldV2Stage.itemHeight
            return (defaultHeight, defaultHeight, [])
        }
        var attrs = [UICollectionViewLayoutAttributes]()
        let itemSpacing = BTFieldV2Stage.itemSpacing
        let lineSpacging = BTFieldV2Stage.lineSpacing
        let itemHeight = BTFieldV2Stage.itemHeight
        let inset = BTFieldV2Stage.inset
        var x: CGFloat = inset.left
        var y: CGFloat = inset.top
        var height = BTFieldV2Stage.itemHeight
        for (index, (option, _)) in models.enumerated() {
            let isFirst = x == inset.left
            let itemWidth = min(BTStageFieldItemCellV2.width(model: option), containerWidth - inset.left * 2)
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
                attr.frame = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)
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

final class BTFieldV2Stage: BTFieldV2Base {
    
    // 单个item的宽度
    static func getItemWidth(_ fieldModel: BTFieldModel) -> CGFloat {
        if let stage = BTStageField.getStageList(fieldModel).first {
            return BTStageItemView.width(with: stage.0.name, style: .big) + itemInset * 2
        }
        return 0
    }
    
    private lazy var itemView: BTStageItemView = {
        let item = BTStageItemView(with: .big)
        return item
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = BTStageItemFlowLayoutV2()
        layout.minimumInteritemSpacing = Self.lineSpacing
        layout.minimumLineSpacing = Self.itemSpacing
        layout.scrollDirection = .vertical
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.dataSource = self
        collection.delegate = self
        collection.showsVerticalScrollIndicator = false
        collection.contentInset = .zero
        collection.backgroundColor = .clear
        collection.register(BTStageFieldItemCellV2.self, forCellWithReuseIdentifier: BTStageFieldItemCellV2.reuseIdentifier)
        return collection
    }()
    
    private var dataSource: [(BTStageModel, UIColor)] {
        return BTStageField.getStageList(fieldModel)
    }
    
    static let itemSpacing: CGFloat = 4
    static let lineSpacing: CGFloat = 4
    static let itemHeight: CGFloat = 32
    static let inset: UIEdgeInsets = .zero
    static let itemInset: CGFloat = 12
    
    override func subviewsInit() {
        super.subviewsInit()
        containerView.addSubview(collectionView)
        containerView.addSubview(itemView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        itemView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(Self.itemHeight)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(Self.itemInset)
            make.right.lessThanOrEqualToSuperview().offset(-Self.itemInset)
        }
    }
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        if model.optionIDs.count > 1, model.compositeType.isCalculationType {
            itemView.isHidden = true
            collectionView.isHidden = false
            (collectionView.collectionViewLayout as? BTStageItemFlowLayoutV2)?.updateModel(model)
            collectionView.reloadData()
            containerView.backgroundColor = UIColor.clear
        } else {
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
                containerView.layer.cornerRadius = ContainerCornerRadius
                containerView.backgroundColor = UIColor.docs.rgb(colorModel.color)
                itemView.configInField(name: option.name, type: option.type)
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
              fieldModel.uneditableReason != .proAdd,
              fieldModel.uneditableReason != .editAfterSubmit
        else {
            showUneditableToast()
            return
        }
        delegate?.stageFieldClick(with: fieldModel)
    }
}

extension BTFieldV2Stage {
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.view == containerView {
            return true
        }
        return super.gestureRecognizer(gestureRecognizer, shouldReceive: touch)
    }
}

extension BTFieldV2Stage: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BTStageFieldItemCellV2.reuseIdentifier, for: indexPath)
        if let cell = cell as? BTStageFieldItemCellV2, let (option, color) = dataSource.safe(index: indexPath.row) {
            cell.config(option, color: color)
        }
        return cell
    }
}

extension BTFieldV2Stage: UICollectionViewDelegateFlowLayout {}
