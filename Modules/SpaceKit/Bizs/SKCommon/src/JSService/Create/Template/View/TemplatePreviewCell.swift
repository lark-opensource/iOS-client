//
//  TemplatePreviewCell.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/5/31.
//  


import SKUIKit
import RxSwift
import SKResource
import UniverseDesignColor

class TemplatePreviewCell: TemplateBaseCell {
    var needSelectedBorder = true {
        didSet {
            selectedBorderLayer.isHidden = !needSelectedBorder || !isSelected
        }
    }
    
    private let selectedBorderLayer: CALayer = {
        let layer = CALayer()
        layer.cornerRadius = 6
        layer.opacity = 1.0
        layer.isHidden = true
        return layer
    }()
    private let disposeBag: DisposeBag = DisposeBag()
    
    override var isSelected: Bool {
        get { super.isSelected }
        set {
            super.isSelected = newValue
            selectedBorderLayer.isHidden = !needSelectedBorder || !newValue
        }
    }
    
    override var bottomViewConfig: TemplateBaseCell.BottomViewConfig {
        var config: BottomViewConfig = .default
        config.style = .onlyTitle
        return config
    }
    
    override var whiteBgViewHeight: CGFloat { 102 }
    override var whiteBgViewWidth: CGFloat { 96 }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.insertSublayer(selectedBorderLayer, at: 0)
        selectedBorderLayer.ud.setBackgroundColor(UDColor.primaryContentDefault)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        selectedBorderLayer.frame = CGRect(x: -1.5, y: -1.5, width: frame.width + 3.0, height: frame.height + 3.0)
    }
}

class GroupNoticeTemplatePreviewCell: TemplatePreviewCell {
    override var bottomViewConfig: TemplateBaseCell.BottomViewConfig {
        var config = super.bottomViewConfig
        config.titleFontSize = 14
        return config
    }
}
