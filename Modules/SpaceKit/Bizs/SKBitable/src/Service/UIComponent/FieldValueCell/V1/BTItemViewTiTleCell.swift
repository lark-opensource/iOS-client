//
//  BTItemViewTiTleCell.swift
//  SKBitable
//
//  Created by zoujie on 2023/7/21.
//  

import SKFoundation
import UIKit
import SnapKit
import SKResource
import UniverseDesignColor
import UniverseDesignShadow
import SKUIKit

final class BTItemViewTiTleCell: UICollectionViewCell, UITextViewDelegate {
    static let cornerRadii = 24

    weak var delegate: BTFieldDelegate?

    private var gradientLayers: [CAGradientLayer] = []

    private lazy var titleView = BTTextView().construct { it in
        it.isEditable = false
        it.bounces = false
        it.btDelegate = self
        it.delegate = self
        it.isScrollEnabled = false
        it.textContainer.maximumNumberOfLines = 2
        it.textContainer.lineBreakMode = .byTruncatingTail
        it.showsVerticalScrollIndicator = false
        it.showsHorizontalScrollIndicator = false
        it.enablePlaceHolder(enable: true)
        it.placeholderLabel.text = BundleI18n.SKResource.Doc_Block_UnnamedRecord
        it.placeholderLabel.textColor = UDColor.primaryPri900.withAlphaComponent(0.7)
        it.placeholderLabel.font = BTFieldLayout.Const.itemViewTitleFont
    }
    
    private lazy var leftBgView = UIView()
    let leftGradientLayer = CAGradientLayer()
    
    private lazy var rightBgView = UIView()
    let rightGradientLayer = CAGradientLayer()
    
    private lazy var bottomLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineBorderCard
    }
    
    override var bounds: CGRect {
        didSet {
            guard bounds != .zero else {
                return
            }
            
            updateBackgroundLayer()
            updateCustomCorner()
        }
    }

    private var showGradient = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        if SKDisplay.pad {
            layer.shadowOffset = CGSize(width: 0, height: -6)
            layer.shadowOpacity = 0
            layer.shadowRadius = 16
            layer.ud.setShadow(type: UDShadowType.s5Down)
        } else {
            layer.shadowOffset = CGSize(width: 0, height: -10)
            layer.shadowOpacity = 0
            layer.shadowRadius = 36
            layer.ud.setShadow(type: UDShadowType.s5Down)
        }
        contentView.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.height.equalTo(0)
            make.bottom.equalToSuperview().inset(BTFieldLayout.Const.itemViewTitleNoTabsBootomMargin)
            make.left.right.equalToSuperview().inset(BTFieldLayout.Const.itemViewTitleLeftRightMargin)
        }
        
        contentView.addSubview(leftBgView)
        contentView.addSubview(rightBgView)
        contentView.addSubview(bottomLine)
        
        leftBgView.snp.makeConstraints { make in
            make.height.equalTo(144)
            make.top.left.right.equalToSuperview()
        }
        
        rightBgView.snp.makeConstraints { make in
            make.height.equalTo(144)
            make.top.left.right.equalToSuperview()
        }
        
        bottomLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        setUpBgLayer()
    }

    func update(title: String, hasShowTabs: Bool, hasShowCover: Bool, hasShowCatalogue: Bool) {
        self.showGradient = !hasShowCover
        bottomLine.isHidden = hasShowTabs || hasShowCatalogue
        titleView.enablePlaceHolder(enable: title.isEmpty)
        let attrs = BTUtil.getFigmaHeightAttributes(font: BTFieldLayout.Const.itemViewTitleFont, alignment: .left)
        
        let fullAttString = NSMutableAttributedString(string: title, attributes: [.foregroundColor: UDColor.primaryPri900])
        let fullRange = NSRange(location: 0, length: fullAttString.length)
        fullAttString.addAttributes(attrs, range: fullRange)
        
        titleView.attributedText = fullAttString
        var bottomOffset: CGFloat = BTFieldLayout.calculateItemViewTitleBottomOffset(
            shouldShowItemViewCatalogue: hasShowCatalogue,
            shouldShowItemViewTabs: hasShowTabs
        )
        let topOffset = hasShowCover ? BTFieldLayout.Const.itemViewTitleTopMarginCover : BTFieldLayout.Const.itemViewTitleTopMarginNoCover
        var titleViewHeight = titleView.sizeThatFits(CGSize(width: self.bounds.width - BTFieldLayout.Const.itemViewTitleLeftRightMargin * 2, height: CGFloat.greatestFiniteMagnitude)).height
        
        titleViewHeight = max(min(BTFieldLayout.Const.itemViewTitleMaxHeight, titleViewHeight), 28)
        titleView.snp.updateConstraints { make in
            make.height.equalTo(titleViewHeight)
            make.bottom.equalToSuperview().inset(bottomOffset)
        }
        
        // 刷新placeholder布局，避免复用带来的问题
        titleView.layoutSubviews()

        setUpBgLayer()
        updateCustomCorner()
    }

    private func updateCustomCorner() {
        if showGradient {
            layer.shadowOpacity = 0
            layer.cornerRadius = 0
            return
        }
        layer.cornerRadius = CGFloat(Self.cornerRadii)
        layer.maskedCorners = .top

        layer.shadowOpacity = 0.1
    }
    
    private func updateBgView() {
        leftBgView.snp.updateConstraints { make in
            make.height.equalTo(showGradient ? 144 : 0)
        }
        
        rightBgView.snp.updateConstraints { make in
            make.height.equalTo(showGradient ? 144 : 0)
        }
    }
    
    private func setUpBgLayer() {
        for layer in gradientLayers {
            layer.removeFromSuperlayer()
        }
        
        updateBgView()
        if !showGradient {
            backgroundColor = UDColor.bgBody
            return
        }
        // 设置渐变的颜色
        leftGradientLayer.colors = [UDColor.primaryPri600.withAlphaComponent(0.06).cgColor, UDColor.primaryPri600.withAlphaComponent(0).cgColor]
        rightGradientLayer.colors = [UDColor.W400.withAlphaComponent(0.06).cgColor, UDColor.W400.withAlphaComponent(0).cgColor]
        
        // 设置渐变的起始点和终止点
        leftGradientLayer.startPoint = CGPoint(x: 0.27, y: 0)
        leftGradientLayer.endPoint = CGPoint(x: 0.31, y: 1)
        rightGradientLayer.startPoint = CGPoint(x: 0.79, y: 0.02)
        rightGradientLayer.endPoint = CGPoint(x: 0.8, y: 1)
        
        // 将渐变图层添加到视图的图层中
        leftBgView.layer.addSublayer(leftGradientLayer)
        rightBgView.layer.addSublayer(rightGradientLayer)
        gradientLayers.append(leftGradientLayer)
        gradientLayers.append(rightGradientLayer)
    }
    
    private func updateBackgroundLayer() {
        leftGradientLayer.frame = self.bounds
        rightGradientLayer.frame = self.bounds
    }
}

extension BTItemViewTiTleCell: BTTextViewDelegate {
    func btTextViewDidScroll(toBounce: Bool) {
        delegate?.setRecordScrollEnable(toBounce)
    }
    
    func btTextView(_ textView: BTTextView, didSigleTapped sender: UITapGestureRecognizer) {}
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.startRecordContentOffset()
    }
    
    func btTextView(_ textView: BTTextView, shouldApply action: BTTextViewMenuAction) -> Bool {
        /// 记录标题接入复制鉴权点位
        let fakeField = BTFieldModel(recordID: BTFieldExtendedType.itemViewHeader.mockFieldID)
        return delegate?.textViewOfField(fakeField, shouldAppyAction: action) ?? false
    }
}
