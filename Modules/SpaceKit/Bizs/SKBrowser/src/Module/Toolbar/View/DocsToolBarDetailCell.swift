//
//  DocsToolBarDetailCell.swift
//  DocsSDK
//
//  Created by Gill on 2020/6/8.
//

import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignFont

// 图 + 文字
class DocsToolBarDetailCell: UICollectionViewCell {
    private var _selectedFlag: Bool = false
    
    enum Const {
        static var titleFont: UIFont { UIFont.systemFont(ofSize: 16) }
        static var bgCornerRadius: CGFloat { 6 }
        static var bgHorizontalInset: CGFloat { 8 }
        static var bgVerticalInset: CGFloat { 7 }
        static var iconLeftInset: CGFloat { 10 }
        static var iconTitleSpacing: CGFloat { 10 }
        static var titleRightInset: CGFloat { 10 }
    }
    
    private lazy var bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.fillActive
        view.layer.cornerRadius = Const.bgCornerRadius
        return view
    }()
    
    private lazy var iconImgView = UIImageView()
    
    private lazy var colorLine: UIView = {
        let view = UIView()
        view.isHidden = true
        view.layer.cornerRadius = 2
        return view
    }() //颜色选择器选中颜色

    var isEnabled: Bool = true {
        didSet {
            contentView.isUserInteractionEnabled = isEnabled
            _updateColor()
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.font = Const.titleFont
        label.numberOfLines = 1
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(bgView)
        contentView.addSubview(iconImgView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(colorLine)

        let bgColorView = UIView()
        bgColorView.backgroundColor = UDColor.fillHover
        bgColorView.layer.cornerRadius = Const.bgCornerRadius
        self.selectedBackgroundView = bgColorView
        bgColorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(Const.bgHorizontalInset)
            make.top.bottom.equalToSuperview().inset(Const.bgVerticalInset)
        }
        
        bgView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(Const.bgHorizontalInset)
            make.top.bottom.equalToSuperview().inset(Const.bgVerticalInset)
        }

        iconImgView.snp.makeConstraints { (make) in
            make.left.equalTo(bgView).offset(Const.iconLeftInset)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(DocsToolBar.Const.imageWidth)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Const.bgHorizontalInset + Const.iconLeftInset + DocsToolBar.Const.imageWidth + Const.iconTitleSpacing)
            make.right.equalTo(bgView).inset(Const.titleRightInset)
            make.centerY.equalToSuperview()
        }
        
        colorLine.snp.makeConstraints { (make) in
            make.centerX.equalTo(iconImgView)
            make.width.equalTo(DocsToolBar.Const.pickerColorWidth)
            make.height.equalTo(DocsToolBar.Const.pickerColorHeight)
            make.top.equalTo(iconImgView.snp.bottom).offset(1)
        }
        
        contentView.docs.addHighlight(with: UIEdgeInsets(horizontal: Const.bgHorizontalInset, vertical: Const.bgVerticalInset), radius: Const.bgCornerRadius)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSelectColor(for color: String?) {
        if let selectColor = color {
            showColorLine(colorString: selectColor)
        } else {
            hideColorLine()
        }
    }

    func lightItUp(light: Bool, image: UIImage, title: String?) {
        titleLabel.text = title
        iconImgView.image = image.withRenderingMode(.alwaysTemplate)
        _selectedFlag = light
        bgView.isHidden = !light
        _updateColor()
    }

    private func _updateColor() {
        var color: UIColor
        if !isEnabled {
            color = UIColor.ud.N400 // Color of disabled
            titleLabel.textColor = UIColor.ud.textDisabled
        } else {
            color = _selectedFlag ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
            titleLabel.textColor = color
        }
        iconImgView.tintColor = color
        titleLabel.highlightedTextColor = UIColor.ud.primaryContentDefault
        iconImgView.highlightedImage = iconImgView.image?.ud.withTintColor(UIColor.ud.colorfulBlue)
    }
    
    private func showColorLine(colorString: String) {
        iconImgView.snp.remakeConstraints { (make) in
            make.left.equalTo(bgView).offset(Const.iconLeftInset + 3) // 3 是 (imageWidth - 18) / 2
            make.top.equalTo(14)
            make.width.height.equalTo(18)
        }
        colorLine.backgroundColor = UIColor.docs.rgb(colorString)
        colorLine.isHidden = false
        if colorString == "#ffffff" { //当选中颜色为白色时需要设置边框颜色
            colorLine.layer.borderWidth = 0.3
            colorLine.layer.ud.setBorderColor(UDColor.N1000)
        }
        if colorString == "#0a0a0a" { //当选中颜色为黑色时需要设置边框颜色
            colorLine.layer.borderWidth = 0.3
            colorLine.layer.ud.setBorderColor(UDColor.N1000)
        }
    }
    
    private func hideColorLine() {
        iconImgView.snp.remakeConstraints { (make) in
            make.left.equalTo(bgView).offset(Const.iconLeftInset)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(DocsToolBar.Const.imageWidth)
        }
        colorLine.isHidden = true
        colorLine.layer.borderWidth = 0
    }
}
