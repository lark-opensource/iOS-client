//
//  BTBottomAddConditionView.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/15.
//  

import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import SKResource

/// 底部添加条件视图
final class BTBottomAddConditionView: UIView {
    
    var didTapAddButton: (() -> Void)?
    
    var isWithSafeArea: Bool = true
    
    private let panelBottomView = BTPanelBottomView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        self.backgroundColor = UDColor.bgFloat
        self.addSubview(panelBottomView)
        panelBottomView.buttonTitleLabel.text = BundleI18n.SKResource.Bitable_Relation_AddCondition
        panelBottomView.addTarget(self, action: #selector(addBtnTapped), for: .touchUpInside)
        panelBottomView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(80)
            if isWithSafeArea {
                $0.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
            } else {
                $0.bottom.equalToSuperview()
            }
        }
        setAddable(true)
    }
    
    func updateWillAppear(safeInset: UIEdgeInsets) {
        // 直接加到Controller上拿到的safeAreaLayoutGuide 不对，这里从Controller传过来
        guard panelBottomView.superview != nil else {
            return
        }
        panelBottomView.snp.remakeConstraints() {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(80)
            if isWithSafeArea {
                $0.bottom.equalToSuperview().offset(-safeInset.bottom)
            } else {
                $0.bottom.equalToSuperview()
            }
        }
    }
    
    
    func setAddable(_ isAddable: Bool) {
        let color: UIColor = isAddable ? UDColor.iconN1 : UDColor.textPlaceholder
        panelBottomView.buttonTitleLabel.textColor = color
        let size = CGSize(width: 20, height: 20)
        var icon =  UDIcon.addOutlined.ud.resized(to: size)
        icon = icon.ud.withTintColor(color)
        panelBottomView.buttonIconView.image = icon
    }
    
    @objc
    private func addBtnTapped(_ btn: UIButton) {
        self.didTapAddButton?()
    }
    
    func updateButtonConstraints(letfMargin: CGFloat, rightMargin: CGFloat) {
        panelBottomView.updateButtonConstrains(letfMargin: letfMargin, rightMargin: rightMargin)
    }
    
    // 获取内容全展开最小宽度
    func minWidth() -> CGFloat {
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 80)
        let textWidth = panelBottomView.buttonTitleLabel.sizeThatFits(size).width
        let iconWidth: CGFloat = 20.0
        let iconPadding: CGFloat = 4.0
        return textWidth + iconWidth + iconPadding
    }
}
