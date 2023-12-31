//
//  BTStageItemView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/5/29.
//

import Foundation
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon
import SKBrowser
import SnapKit

final class BTStageItemView: UIView {
    
    enum Style {
        case normal // 普通状态，icon大小为8，间距为6
        case big // 较大状态，icon大小为10，间距为8
        case cardView // 卡片视图内部使用
    }
    
    private lazy var icon: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        return label
    }()
    
    let style: Style
    
    var iconSize: CGFloat {
        switch style {
        case .normal:
            return 8.0
        case .big:
            return 10.0
        case .cardView:
            return 8.0
        }
    }
    
    var itemSpace: CGFloat {
        switch style {
        case .normal:
            return 8.0
        case .big:
            return 6.0
        case .cardView:
            return 5.0
        }
    }
    
    private let iconCompleteIconSizeInCardView: CGFloat = 14.0
    private var iconCompleteSizeConstraintInCardView: SnapKit.ConstraintMakerEditable?
    private var iconNormalSizeConstraint: SnapKit.ConstraintMakerEditable?
        
    required init(with style: Style) {
        self.style = style
        super.init(frame: .zero)
        addSubview(icon)
        addSubview(textLabel)
        
        icon.snp.makeConstraints { make in
            iconNormalSizeConstraint = make.size.equalTo(iconSize)
            iconCompleteSizeConstraintInCardView = make.size.equalTo(iconCompleteIconSizeInCardView)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
        }
        textLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(icon.snp.right).offset(itemSpace)
            make.right.equalToSuperview()
        }
        iconCompleteSizeConstraintInCardView?.constraint.isActive = false
    }
    
    func configInDetail(name: String, status: BTStageModel.StageNodeState, isInConvert: Bool = false, bold: Bool = false) {
        icon.layer.cornerRadius = iconSize / 2.0
        icon.layer.borderWidth = iconSize / 10.0
        switch status {
        case .pending:
            icon.backgroundColor = UDColor.N350
            icon.layer.borderColor = UDColor.N500.cgColor
        case .progressing:
            icon.backgroundColor = UDColor.O200
            icon.layer.borderColor = UDColor.O350.cgColor
        case .finish:
            icon.backgroundColor = UDColor.G300
            icon.layer.borderColor = UDColor.G500.cgColor
        }
        textLabel.text = name
        if isInConvert {
            textLabel.textColor = UDColor.textTitle
        } else {
            textLabel.textColor = status == .finish ? UDColor.staticWhite : UDColor.textTitle
        }
        textLabel.font =  UDFont.systemFont(ofSize: 14, weight: bold ? .medium : .regular)
    }
    
    func configInField(name: String,
                       type: BTStageModel.StageType,
                       font: UIFont = UDFont.systemFont(ofSize: 14, weight: .medium)) {
        if type != .endDone {
            icon.layer.cornerRadius = iconSize / 2.0
            icon.layer.borderWidth = iconSize / 10.0
        }
        switch type {
        case .defualt:
            icon.image = nil
            icon.backgroundColor = UDColor.O200
            icon.layer.borderColor = UDColor.O350.cgColor
            textLabel.textColor = UDColor.textTitle
        case .endCancel:
            icon.image = nil
            icon.backgroundColor = UDColor.R300
            icon.layer.borderColor = UDColor.R500.cgColor
            textLabel.textColor = UDColor.staticWhite
        case .endDone:
            icon.image = UDIcon.listCheckBoldOutlined.ud.withTintColor(UDColor.staticWhite)
            icon.backgroundColor = UIColor.clear
            icon.layer.cornerRadius = 0
            icon.layer.borderWidth = 0
            icon.layer.borderColor = UIColor.clear.cgColor
            textLabel.textColor = UDColor.staticWhite
        }
        let iconCompleteSizeActive = type == .endDone && style == .cardView
        iconCompleteSizeConstraintInCardView?.constraint.isActive = iconCompleteSizeActive
        iconNormalSizeConstraint?.constraint.isActive = !iconCompleteSizeActive
        textLabel.text = name
        textLabel.textColor = type == .defualt ? UDColor.textTitle : UDColor.staticWhite
        textLabel.font =  font
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func width() -> CGFloat {
        let font = textLabel.font ?? UDFont.systemFont(ofSize: 14)
        let textWidth = textLabel.text?.getWidth(font: font) ?? 0
        let itemSpace = style == .big ? 6.0 : 8.0
        return textWidth + itemSpace + iconSize
    }
    
    static func width(with text: String, style: Style = .normal) -> CGFloat {
        let font = UDFont.systemFont(ofSize: 14, weight: .medium)
        let textWidth = text.getWidth(font: font)
        return textWidth + (style == .normal ? 14 : 18)
    }
}
