//
//  UDColorPicker.swift
//  UDKit
//
//  Created by zfpan on 2020/11/13.
//  Copyright © 2020年 panzaofeng. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignFont

/// call ball of select color in color pickers
/// - Parameters:
///   - color: selected color
///   - panel: the panel operated by user
public protocol UDColorPickerPanelDelegate: AnyObject {
    func didSelected(color: UIColor?, category: UDPaletteItemsCategory, in panel: UDColorPickerPanel)
}

public final class UDColorPickerPanel: UIView {
    //color picker delegate
    public weak var delegate: UDColorPickerPanelDelegate?

    private var data: [UDPaletteModel]
    private var collectionView: UICollectionView

    fileprivate static let titleLeftMargin: CGFloat = 16
    fileprivate static let leftRightMargin: CGFloat = 14
    fileprivate static let itemSize: CGFloat = 40
    fileprivate static let colorAreaSize: CGFloat = 36
    fileprivate static let iconSize: CGFloat = 24

    private let reuseIdentifier: String = "com.bytedance.universeui.colorpicker"
    private var isNeedUseMaxPadding = false
    private static let cellWidth: CGFloat = 48

    /// color picker constructor
    /// - Parameters:
    ///   - config: color picker config
    public init(config: UDColorPickerConfig) {
        // make UICollectionView
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        self.collectionView = SelfSizingCollectionView(frame: .zero,
                                                       collectionViewLayout: layout)
        collectionView.backgroundColor = config.backgroundColor
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ColorPickerCell.self,
                                forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.register(ColorPickerHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: String(describing: ColorPickerHeaderView.self))

        self.data = config.models
        super.init(frame: .zero)

        collectionView.delegate = self
        collectionView.dataSource = self

        _addSubviews()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// color picker data updater
    /// - Parameters:
    ///   - config: color picker config
    public func update(_ config: UDColorPickerConfig) {
        self.data = config.models
        collectionView.backgroundColor = config.backgroundColor
        collectionView.reloadData()
    }

    private func _addSubviews() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        collectionView.layer.cornerRadius = 6
    }
}

// MARK: - UICollectionViewDataSource
extension UDColorPickerPanel: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        return data[section].items.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let model = data[indexPath.section]

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let pickerCell = cell as? ColorPickerCell {
            let item = model.items[indexPath.row]
            var selected = false
            if indexPath.row == model.selectedIndex {
                selected = true
            }
            pickerCell.update(item, category: model.category, selected: selected)
        }
        return cell

    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }
}

// MARK: - UICollectionViewDelegate / UICollectionViewDelegateFlowLayout
extension UDColorPickerPanel: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
        let item = data[indexPath.section].items[indexPath.row]
        delegate?.didSelected(color: item.color, category: data[indexPath.section].category, in: self)
        data[indexPath.section].selectedIndex = indexPath.row
        collectionView.reloadData()
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UDColorPickerPanel.cellWidth
        return CGSize(width: width, height: width)

    }

    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: String(describing: ColorPickerHeaderView.self),
                for: indexPath)
            if let header = view as? ColorPickerHeaderView {
                header.update(data[indexPath.section].title)
            }
            return view
        } else {
             return UICollectionReusableView()
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        var minimumInteritemSpacing: CGFloat = 0.0
        let model = data[section]
        switch model.category {
        case .basic:
            minimumInteritemSpacing = 6.0
        default:
            minimumInteritemSpacing = 2.0
        }
        return minimumInteritemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard data.count > section, !data[section].title.isEmpty else {
            return CGSize(width: collectionView.frame.width, height: 0)
        }
        return CGSize(width: collectionView.frame.width, height: 46)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {

        return UIEdgeInsets(top: 0,
                            left: UDColorPickerPanel.leftRightMargin,
                            bottom: 0,
                            right: UDColorPickerPanel.leftRightMargin)
    }
}

private class ColorPickerCell: UICollectionViewCell {
    private let aIcon: UIImageView = UIImageView()
    private let bgView: UIView = UIView(frame: CGRect(x: 0, y: 0,
                                                      width: UDColorPickerPanel.itemSize,
                                                      height: UDColorPickerPanel.itemSize))
    private let content: UIView = UIView(frame: CGRect(x: 2, y: 2,
                                                       width: UDColorPickerPanel.itemSize,
                                                       height: UDColorPickerPanel.itemSize))

    override init(frame: CGRect) {
        super.init(frame: frame)
        bgView.layer.cornerRadius = 6.0
        bgView.backgroundColor = UIColor.clear
        contentView.addSubview(bgView)
        content.layer.cornerRadius = 4.0
        contentView.addSubview(content)
        content.addSubview(aIcon)
        aIcon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.width.equalTo(UDColorPickerPanel.iconSize)
        }
        bgView.snp.makeConstraints { (make) in
            make.height.width.equalTo(UDColorPickerPanel.itemSize)
            make.center.equalToSuperview()
        }
        content.snp.makeConstraints { (make) in
            make.height.width.equalTo(UDColorPickerPanel.colorAreaSize)
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ item: UDPaletteItem, category: UDPaletteItemsCategory, selected: Bool) {
        if category == .basic {
            if selected {
                aIcon.image = BundleResources.image(named: "highlight_common")
                aIcon.isHidden = false
            } else {
                aIcon.isHidden = true
            }
            content.backgroundColor = item.color
            content.layer.borderWidth = 0
        } else if category == .text {
            let image = BundleResources.image(named: "highlight_text")
            aIcon.image = image.withColor(item.color ?? UDColor.neutralColor12)
            aIcon.isHidden = false
            content.backgroundColor = UDColorPickerColorTheme.colorPickerTextBackgroundColor
            content.layer.borderColor = UDColorPickerColorTheme.colorPickerInnerTextBorderColor.cgColor
            content.layer.borderWidth = 1
        } else if category == .background {
            let image = BundleResources.image(named: "highlight_text")
            aIcon.image = image.withColor(UDColor.neutralColor12)
            aIcon.isHidden = false
            content.backgroundColor = item.color
            content.layer.borderWidth = 0
        }

        if selected {
            self.showBorder()
        } else {
            self.hideBorder()
        }
    }
}

fileprivate extension UIView {
    func showBorder(_ width: CGFloat = 4, _ color: CGColor = UDColorPickerColorTheme.colorPickerBorderColor.cgColor) {
        if layer.sublayers?.contains(borderLayer) ?? false {
            return
        }
        borderLayer.borderColor = color
        borderLayer.frame = CGRect(x: 0,
                                   y: 0,
                                   width: frame.width,
                                   height: frame.height)
        borderLayer.borderWidth = width
        borderLayer.cornerRadius = 8.0
        layer.addSublayer(borderLayer)
    }

    func hideBorder() {
        borderLayer.removeFromSuperlayer()
    }

    private static var borderLayerKey: UInt8 = 0
    var borderLayer: CALayer {
        get {
            guard let value = objc_getAssociatedObject(self, &UIView.borderLayerKey) as? CALayer else {
                let layer = CALayer()
                self.borderLayer = layer
                return layer
            }
            return value
        }
        set {
            objc_setAssociatedObject(self, &UIView.borderLayerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private class ColorPickerHeaderView: UICollectionReusableView {

    private let label: UILabel = {
        let label = UILabel()
        label.font = UDFont.body0
        label.textColor = UDColorPickerColorTheme.colorPickerTitleTextColor
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(14)
            make.height.equalTo(22)
            make.left.equalToSuperview().offset(UDColorPickerPanel.titleLeftMargin)
            make.right.equalToSuperview().offset(-UDColorPickerPanel.titleLeftMargin)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ title: String?) {
        label.text = title
    }

}

// unit test support, need expose some private variables
extension UDColorPickerPanel {
    #if DEBUG
    func paletteData() -> [UDPaletteModel] {
        return data
    }
    #endif
}

/// 在 CollectionView 没有外部约束大小时，其高度可以根据内容自动撑开
class SelfSizingCollectionView: UICollectionView {

    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
