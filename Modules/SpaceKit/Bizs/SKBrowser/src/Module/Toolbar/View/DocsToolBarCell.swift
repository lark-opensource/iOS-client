//
//  DocsToolBarCell.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/1/9.
//

import UIKit
import SKCommon
import UniverseDesignColor

//public enum ToolBarCellType {
//    case mainBar
//    case subBar
//}

public final class DocsToolBarCell: UICollectionViewCell {
    private var itemView: DocsToolBarItemView
    private var textColorItemView: DocsToolBarTextColorItemView

    var icon: UIImageView {
        get { return itemView.icon }
        set { itemView.icon = newValue }
    }

    override init(frame: CGRect) {
        itemView = DocsToolBarItemView(frame: frame)
        textColorItemView = DocsToolBarTextColorItemView(frame: frame)
        super.init(frame: frame)
        contentView.addSubview(itemView)
        itemView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        contentView.addSubview(textColorItemView)
        textColorItemView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let bgColorView = UIView()
        bgColorView.backgroundColor = UDColor.fillHover
        bgColorView.layer.cornerRadius = 6
        self.selectedBackgroundView = bgColorView
        self.selectedBackgroundView?.snp.makeConstraints { (make) in
            make.width.height.equalTo(DocsToolBar.Const.bgColorWidth)
            make.center.equalToSuperview()
        }

        itemView.isHidden = false
        textColorItemView.isHidden = true
    }

    public func resetSelectedContrains(_ width: Float) {
        self.selectedBackgroundView?.snp.remakeConstraints { (make) in
            make.width.height.equalTo(width)
            make.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        itemView.isHidden = false
        textColorItemView.isHidden = true
    }
    
    public func updateAppearance(image: UIImage?, enabled: Bool, adminLimit: Bool, selected: Bool, hasChildren: Bool, showOriginColor: Bool = false) {
        itemView.docs.removeAllPointer()
        contentView.isUserInteractionEnabled = enabled
        if showOriginColor {
            icon.image = image
            icon.highlightedImage = image?.withRenderingMode(.alwaysOriginal)
        } else {
            icon.image = image?.withRenderingMode(.alwaysTemplate)
            icon.highlightedImage = image?.ud.withTintColor(UDColor.primaryContentDefault)
        }
        var color: UIColor
        if adminLimit || !enabled {
            color = UDColor.iconDisabled // Color of disabled
            itemView.bgColorView.backgroundColor = .clear
            icon.highlightedImage = icon.image?.ud.withTintColor(color)
            selectedBackgroundView?.isHidden = true
        } else {
            if hasChildren {
                color = UDColor.iconN1
                itemView.bgColorView.backgroundColor = UDColor.fillHover
                itemView.docs.addStandardLift()
            } else if selected {
                color = UDColor.primaryContentDefault
                itemView.bgColorView.backgroundColor = UDColor.fillActive
                itemView.docs.addStandardLift()
            } else {
                itemView.bgColorView.backgroundColor = .clear
                color = UDColor.iconN1
                itemView.docs.addHighlight(with: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4), radius: 6)
            }
            if !showOriginColor {
                icon.highlightedImage = icon.image?.ud.withTintColor(UDColor.primaryContentDefault)
            }
            selectedBackgroundView?.isHidden = false
        }
        icon.tintColor = color
    }

    func updateHighlightColor(for rawData: [String: Any]?) {
        if let backgroundData = rawData?["background"] as? [String: Any], let valueDict = backgroundData["value"] as? [String: CGFloat] {
            _updateHighlightColor(for: .background, color: ColorPaletteItemV2.ColorInfo(valueDict).color)
        }
        if let backgroundData = rawData?["text"] as? [String: Any], let valueDict = backgroundData["value"] as? [String: CGFloat] {
            _updateHighlightColor(for: .text, color: ColorPaletteItemV2.ColorInfo(valueDict).color)
        }
    }

    func updateHighlightColor(for color: String) {
        _updateHighlightColor(for: .background, color: UIColor.docs.rgb(color))
    }

    func updateSelectColor(for color: String?) {
        if let selectColor = color {
            itemView.showColorLine(colorString: selectColor)
        } else {
            itemView.hideColorLine()
        }
    }

    private func _updateHighlightColor(for type: ColorPaletteItemCategory,
                                       color: UIColor?) {
        if type == .background {
            itemView.bgColorView.backgroundColor = color
        } else if type == .text {
            itemView.isHidden = true
            textColorItemView.isHidden = false
            textColorItemView.icon.image = itemView.icon.image
            textColorItemView.colorLine.backgroundColor = color
            textColorItemView.tmpLabel.textColor = color
            textColorItemView.tmpLabel.isHidden = false
            textColorItemView.icon.isHidden = true
            textColorItemView.colorLine.isHidden = true
        }
    }
}

class DocsToolBarTextColorItemView: UIView {
    lazy var icon: UIImageView = UIImageView()
    lazy var colorLine = UIView()
    lazy var tmpLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 28)
        label.textColor = UDColor.N900
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(colorLine)
        addSubview(icon)
        addSubview(tmpLabel)
        backgroundColor = .clear
        tmpLabel.text = "A"
        icon.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(18)
        }
        colorLine.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(17)
            make.height.equalTo(4)
        }
        tmpLabel.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
            make.width.height.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DocsToolBarItemView: UIView {
    lazy var contentFrame = UIView()
    lazy var icon: UIImageView = UIImageView()
    lazy var bgColorView: UIView = UIView()
    lazy var colorLine = UIView() //颜色选择器选中颜色
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(contentFrame)
        addSubview(bgColorView)
        addSubview(icon)
        addSubview(colorLine)
        backgroundColor = .clear
        contentFrame.backgroundColor = .clear
        bgColorView.backgroundColor = .clear
        bgColorView.layer.cornerRadius = 6
        colorLine.layer.cornerRadius = 2
        colorLine.isHidden = true
        
        bgColorView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(DocsToolBar.Const.bgColorWidth)
        }
        contentFrame.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(DocsToolBar.Const.imageWidth)
        }
        colorLine.snp.makeConstraints { (make) in
            make.width.equalTo(DocsToolBar.Const.pickerColorWidth)
            make.height.equalTo(DocsToolBar.Const.pickerColorHeight)
            make.centerX.equalTo(contentFrame)
            make.bottom.equalTo(contentFrame).inset(1)
        }
        icon.snp.makeConstraints { (make) in
            make.edges.equalTo(contentFrame)
        }
        self.docs.addHighlight(with: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4), radius: 6)
    }
    
    func showColorLine(colorString: String) {
        icon.snp.remakeConstraints { (make) in
            make.top.centerX.equalTo(contentFrame)
            make.width.height.equalTo(18)
        }
        colorLine.backgroundColor = UIColor.docs.rgb(colorString)
        colorLine.isHidden = false
        if colorString == "#ffffff" { //当选中颜色为白色时需要设置边框颜色
            colorLine.layer.borderWidth = 0.1
            colorLine.layer.ud.setBorderColor(UDColor.N1000)
        }
    }
    
    func hideColorLine() {
        icon.snp.remakeConstraints { (make) in
            make.edges.equalTo(contentFrame)
        }
        colorLine.isHidden = true
        colorLine.layer.borderWidth = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
