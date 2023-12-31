//
//  BTProgressField.swift
//  SKBitable
//
//  Created by yinyuan on 2022/12/10.
//


import Foundation
import SKBrowser
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignProgressView
import UniverseDesignIcon
import UniverseDesignFont
import SKCommon
import LarkTag
import SKFoundation
import SKResource

struct BTFieldUIDataProgress: BTFieldUIData {
    struct Const {
        static let progressBarHeight: CGFloat = 8.0
        static let progressBarSpaceH: CGFloat = 8.0
        
        static let barMinWidth: CGFloat = 72.0
        static let textMinWidth: CGFloat = 42.0
        
        static let lineHeight: CGFloat = 24.0
        
        static let textFont = UDFont.body0
        static let textColor = UDColor.textTitle
    }
}

private extension BTFieldModel {
    var progressFixValue: [Double] {
        numberValue.map { item in
            // 仅在查找引用和公式两种可能原样引用进度条的场景下fix
            // 仅对百分数类型进行 fix
            if compositeType.uiType == .lookup || compositeType.uiType == .formula {
                if property.formatter.hasSuffix("%"), item.formattedValue.hasSuffix("%") {
                    return item.rawValue * 100
                }
            }
            return item.rawValue
        }
    }
}

final class BTFieldV2Progress: BTFieldV2Base, BTFieldProgressCellProtocol {
    
    override func subviewsInit() {
        super.subviewsInit()
        
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(progressBarClick))
        containerView.addGestureRecognizer(tapGesture)
        
        collectionView.register(ProgressCell.self, forCellWithReuseIdentifier: ProgressCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.insetsLayoutMarginsFromSafeArea = false
        collectionView.bounces = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isScrollEnabled = true
        collectionView.delaysContentTouches = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        
        reloadData()
    }
    
    @objc
    override func onFieldValueEnlargeAreaClick(_ sender: UITapGestureRecognizer) {
        progressBarClick()
    }
    
    func updateEditingStatus(_ editing: Bool) {
        fieldModel.update(isEditing: editing)
    }
    
    func reloadData() {
        collectionView.reloadData()
    }

    func stopEditing() {
        updateBorderMode(.normal)
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
    
    func panelDidStartEditing() {
        updateBorderMode(.editing)
        delegate?.panelDidStartEditingField(self, scrollPosition: nil)
    }
    
    @objc
    private func progressBarClick() {
        if fieldModel.editable {
            delegate?.startEditProgress(forField: self)
        } else {
            showUneditableToast()
        }
    }
    
    // MARK: - private
    
    private var uiModel: BTFieldUIDataProgress?

    private let collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

}

extension BTFieldV2Progress: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 至少得显示 1 个，空的话也要显示
        return max(1, fieldModel.numberValue.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProgressCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? ProgressCell {
            cell.progressBar.minValue = fieldModel.property.min ?? 0
            cell.progressBar.maxValue = fieldModel.property.max ?? 100
            cell.progressBar.progressColor = fieldModel.property.progress?.color
            if indexPath.item < fieldModel.numberValue.count {
                let numberModel = fieldModel.numberValue[indexPath.item]
                cell.progressBar.value = fieldModel.progressFixValue[indexPath.item]
                cell.textLabel.text = numberModel.formattedValue
            } else {
                // 空状态
                cell.progressBar.value = cell.progressBar.minValue
                cell.textLabel.text = nil
            }
            
            cell.updateLayout()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: layoutInfo.valueSize.width, height: BTFieldUIDataProgress.Const.lineHeight)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
}

private class ProgressCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let progressBar = BTProgressView()
        
    let textLabel = UILabel().construct { it in
        it.font = BTFieldUIDataProgress.Const.textFont
        it.textColor = BTFieldUIDataProgress.Const.textColor
        it.textAlignment = .right
    }
    
    func updateLayout() {
        textLabel.sizeToFit()
        let leftOffset = textLabel.text.isEmpty ? 0 : BTFieldUIDataProgress.Const.progressBarSpaceH
        var textLabelWidth = textLabel.text.isEmpty ? 0 : max(textLabel.bounds.width, BTFieldUIDataProgress.Const.textMinWidth)
        
        let width = self.bounds.width
        var progressBarWidth = width - textLabelWidth - leftOffset
        if progressBarWidth < BTFieldUIDataProgress.Const.barMinWidth, !textLabel.text.isEmpty {
            // 进度条最小宽度为72
            progressBarWidth = BTFieldUIDataProgress.Const.barMinWidth
            textLabelWidth = width - progressBarWidth - leftOffset
        }
        
        textLabel.snp.remakeConstraints { make in
            make.left.equalTo(progressBar.snp.right).offset(leftOffset)
            make.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.height.equalTo(BTFieldUIDataProgress.Const.lineHeight)
            make.width.equalTo(textLabelWidth)
        }
        
        progressBar.snp.remakeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.height.equalTo(BTFieldUIDataProgress.Const.progressBarHeight)
            make.width.equalTo(progressBarWidth)
        }
    }
    
    private func subviewsInit() {
        contentView.addSubview(progressBar)
        contentView.addSubview(textLabel)
        
        progressBar.setContentCompressionResistancePriority(.required, for: .horizontal)
        textLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        progressBar.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.height.equalTo(BTFieldUIDataProgress.Const.progressBarHeight)
            make.width.equalTo(BTFieldUIDataProgress.Const.barMinWidth)
        }
        textLabel.snp.makeConstraints { make in
            make.left.equalTo(progressBar.snp.right).offset(BTFieldUIDataProgress.Const.progressBarSpaceH)
            make.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.height.equalTo(BTFieldUIDataProgress.Const.lineHeight)
            make.width.equalTo(BTFieldUIDataProgress.Const.textMinWidth)
        }
    }
    
}
