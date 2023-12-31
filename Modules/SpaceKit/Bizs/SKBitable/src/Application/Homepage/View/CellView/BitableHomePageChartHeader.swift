//
//  BitableHomePageChartHeader.swift
//
//  Created by ByteDance on 2023/10/29.
//

import UIKit
import UniverseDesignColor
import SnapKit
import SKResource

struct BitableHomeChartHeaderLayoutConfig {
    static let titleLabelFont: UIFont = UIFont.systemFont(ofSize: 17.0)
    static let editButtonFont: UIFont = UIFont.systemFont(ofSize: 14.0)
    static let maskCorner: CGFloat = 20.0
    static let buttonCorner8: CGFloat = 8.0
    static let editbuttonSize: CGSize = CGSizeMake(44.0, 28.0)
}

class BitableHomePageChartFooter: UICollectionReusableView {
}

class BitableHomePageChartHeader: UICollectionReusableView {
    
    private lazy var bgView: UIView = {
        let bgView = UIView(frame: .zero)
        bgView.backgroundColor = BitableHomeChartCellLayoutConfig.chartCellBackgroundColor
        return bgView
    }()
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = BundleI18n.SKResource.Bitable_HomeDashboard_MyChart_Text
        titleLabel.textAlignment = .center
        titleLabel.font = BitableHomeChartHeaderLayoutConfig.titleLabelFont
        titleLabel.textColor = UDColor.textTitle
        titleLabel.sizeToFit()
        return titleLabel
    }()
    
    lazy var editButton: UIButton = {
        let editButton = UIButton(frame: CGRect(origin: .zero, size: BitableHomeChartHeaderLayoutConfig.editbuttonSize))
        editButton.isExclusiveTouch = true
        editButton.setTitle(BundleI18n.SKResource.Bitable_HomeDashboard_Edit_Button, for: .normal)
        editButton.setTitleColor(UDColor.N900, for: .normal)
        editButton.titleLabel?.textAlignment = .center
        editButton.titleLabel?.font = BitableHomeChartHeaderLayoutConfig.editButtonFont
        editButton.backgroundColor = UDColor.N200
        editButton.layer.cornerRadius = BitableHomeChartHeaderLayoutConfig.buttonCorner8
        editButton.isHidden = true
        return editButton
    }()
    
    private lazy var bottomLine: UIView = {
        let bottomLine = UIView(frame: .zero)
        bottomLine.backgroundColor = UDColor.lineDividerDefault.withAlphaComponent(0.15)
        bottomLine.isHidden = true
        return bottomLine
    }()
    
    private var sticky: Bool = false
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UDColor.rgb("#EEF2F6") & UDColor.rgb("#1B1B1B")
        
        addSubview(bgView)
        
        bgView.addSubview(titleLabel)
        bgView.addSubview(editButton)
        bgView.addSubview(bottomLine)
        
        bgView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.right.bottom.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        var buttonSize =  BitableHomeChartHeaderLayoutConfig.editbuttonSize
        if let font = editButton.titleLabel?.font {
            let width = max((editButton.titleLabel?.text?.getWidth(font: font) ?? 0) + 8, BitableHomeChartHeaderLayoutConfig.editbuttonSize.width)
            buttonSize = CGSizeMake(width, buttonSize.height)
        }
        
        editButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.size.equalTo(buttonSize)
        }
        
        bottomLine.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }
        
        // 设置背景裁剪
        let maskPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: frame.size), byRoundingCorners: [.topLeft,.topRight], cornerRadii: CGSize(width: BitableHomeChartHeaderLayoutConfig.maskCorner, height: BitableHomeChartHeaderLayoutConfig.maskCorner))
        let mask = CAShapeLayer()
        mask.path = maskPath.cgPath
        bgView.layer.mask = mask
    }
    
    func toggleEditMode(_ editMode: Bool) {
        editButton.setTitle(editMode ? BundleI18n.SKResource.Bitable_HomeDashboard_Done_Button : BundleI18n.SKResource.Bitable_HomeDashboard_Edit_Button, for: .normal)
        let titleColor = editMode ? UDColor.primaryContentDefault : UDColor.N900
        let backgroundColor = editMode ? UDColor.primaryFillSolid01 : UDColor.N200
        if let font = editButton.titleLabel?.font {
            let width = max((editButton.titleLabel?.text?.getWidth(font: font) ?? 0) + 8, BitableHomeChartHeaderLayoutConfig.editbuttonSize.width)
            editButton.snp.updateConstraints { make in
                make.size.equalTo(CGSizeMake(width,
                                             BitableHomeChartHeaderLayoutConfig.editbuttonSize.height))
            }
        }
        editButton.setTitleColor(titleColor, for: .normal)
        editButton.backgroundColor = backgroundColor
    }
    
    func stickTop(_ sticky: Bool) {
        if self.sticky == sticky {
            return
        }
        self.sticky = sticky
        // 触发吸顶/离开吸顶状态的UI状态更新
        bottomLine.isHidden = !sticky
    }
    
    func showEditButton(_ visible: Bool) {
        editButton.isHidden = !visible
    }
}
