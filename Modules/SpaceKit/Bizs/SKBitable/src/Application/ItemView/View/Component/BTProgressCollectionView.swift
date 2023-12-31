//
//  BTProgressCollectionView.swift
//  SKBitable
//
//  Created by yinyuan on 2022/12/9.
//

import UniverseDesignColor

final class BTProgressCell: UICollectionViewCell {
    
    final class Constaints {
        static let spacing: CGFloat = 8
        static let defaultLableWidth: CGFloat = 56
        static let defaultProgressWidth: CGFloat = 100
        static let maxProgressWidth: CGFloat = 286
        static let percentChar = "%"
        static let progressHeight = 10
    }
    
    lazy var progressView: BTProgressView = {
        let view = BTProgressView()
        return view
    }()
    
    lazy var lable: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 14)
        view.textAlignment = .right
        view.textColor = UDColor.textTitle
        return view
    }()
    
    var fieldEditable: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var remainWidth = self.frame.width - Constaints.spacing
        if !fieldEditable {
            remainWidth -= (BTFieldLayout.Const.panelIndicatorWidthHeight + BTFieldLayout.Const.panelIndicatorRightMargin)
        }
        let pec = Constaints.defaultProgressWidth / (Constaints.defaultProgressWidth + Constaints.defaultLableWidth)
        let progressWidth = min(remainWidth * pec, Constaints.maxProgressWidth)
        progressView.snp.updateConstraints { make in
            make.width.equalTo(progressWidth)
        }
    }
    
    private func setup() {
        self.backgroundColor = .clear
        contentView.addSubview(progressView)
        contentView.addSubview(lable)
        progressView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(Constaints.defaultProgressWidth)
            make.height.equalTo(Constaints.progressHeight)
        }
        lable.snp.makeConstraints { make in
            make.left.equalTo(progressView.snp.right).offset(Constaints.spacing)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
}

final class BTProgressCollectionView: UICollectionView {
    
    public var fieldModel: BTFieldModel = BTFieldModel(recordID: "") {
        didSet {
            reloadData()
        }
    }
    
    private lazy var flowLayout = UICollectionViewFlowLayout().construct { it in
        it.minimumLineSpacing = BTFieldLayout.Const.tableItemSpacing
    }
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = BTFieldLayout.Const.progressItemSpacing
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
        self.backgroundColor = .clear
        self.insetsLayoutMarginsFromSafeArea = false
        self.bounces = false
        self.contentInsetAdjustmentBehavior = .never
        self.isScrollEnabled = true
        self.delaysContentTouches = false
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.register(BTProgressCell.self, forCellWithReuseIdentifier: BTProgressCell.reuseIdentifier)
    }
}

extension BTProgressCollectionView: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width = fieldModel.width - BTFieldLayout.Const.containerLeftRightMargin * 2 - BTFieldLayout.Const.containerPadding * 2
        if fieldModel.editable {
            width -= (BTFieldLayout.Const.panelIndicatorWidthHeight + BTFieldLayout.Const.panelIndicatorRightMargin)
        }
        return CGSize(width: max(0, width), height: BTFieldLayout.Const.progressItemHeight)
    }
}

extension BTProgressCollectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 至少得显示 1 个，空的话也要显示
        return max(1, fieldModel.numberValue.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BTProgressCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? BTProgressCell {
            cell.progressView.minValue = fieldModel.property.min ?? 0
            cell.progressView.maxValue = fieldModel.property.max ?? 100
            cell.progressView.progressColor = fieldModel.property.progress?.color
            if indexPath.item < fieldModel.numberValue.count {
                let numberModel = fieldModel.numberValue[indexPath.item]
                cell.progressView.value = fixedNumberValue(numberModel)
                cell.lable.text = numberModel.formattedValue
            } else {
                // 空状态
                cell.progressView.value = cell.progressView.minValue
                cell.lable.text = nil
            }
            cell.fieldEditable = fieldModel.editable
        }
        return cell
    }
    
    /// 由于早期的设计问题，在百分数情况下：
    /// 存在一个历史遗漏的问题：number 类型传给客户端的 numberValue 在百分数情况下是乘以 100 后的值。
    /// 但是呢，在 lookup 和 formula 场景下传过来的 numberValue 值又是没有乘以 100 (formatterValue 是正常的)。由于之前没有在 lookup 和 formula 场景下使用 numberValue，而只使用了 formatterValue，因此该问题一直没有暴露。
    /// 直到，进度条字段出现，我们需要使用 numberValue 来作为进度计算显示，这时候才发现问题。但是重构已经来不及了。只能现这样特殊处理一下。
    /// 计划由前端统一解决该问题后，再删除这个函数。
    private func fixedNumberValue(_ numberModel: BTNumberModel) -> Double {
        // 仅在查找引用和公式两种可能原样引用进度条的场景下fix
        // 仅对百分数类型进行 fix
        if fieldModel.compositeType.uiType == .lookup || fieldModel.compositeType.uiType == .formula {
            if fieldModel.property.formatter.hasSuffix("%"), numberModel.formattedValue.hasSuffix("%") {
                return numberModel.rawValue * 100
            }
        }
        return numberModel.rawValue
    }
}
