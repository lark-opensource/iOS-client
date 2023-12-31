//
//  SortApplyView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/9/6.
//

import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import SKResource

/// 底部添加条件视图
final class SortApplyView: UIView {
    
    var didTapApplyButton: (() -> Void)?
    
    var isWithSafeArea: Bool = true
    
    private let panelBottomView = BTPanelBottomView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateTopLine(hidden: Bool) {
        panelBottomView.updateTopLine(hidden: hidden)
    }
    
    private func setupViews() {
        self.backgroundColor = UDColor.bgFloat
        self.addSubview(panelBottomView)
        panelBottomView.buttonTitleLabel.text = BundleI18n.SKResource.Bitable_Common_Apply_Button
        panelBottomView.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        let themColor = UDColor.primaryContentDefault
        panelBottomView.buttonTitleLabel.textColor = themColor
        panelBottomView.button.layer.ud.setBorderColor(themColor)
        let size = CGSize(width: 20, height: 20)
        panelBottomView.buttonIconView.image = UDIcon.doneOutlined.ud.withTintColor(themColor).ud.resized(to: size)
        panelBottomView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(80)
            if isWithSafeArea {
                $0.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
            } else {
                $0.bottom.equalToSuperview()
            }
        }
    }
    
    func updateButtonConstraints(letfMargin: CGFloat, rightMargin: CGFloat) {
        panelBottomView.updateButtonConstrains(letfMargin: letfMargin, rightMargin: rightMargin)
    }
    
    @objc
    private func applyTapped(_ btn: UIButton) {
        self.didTapApplyButton?()
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
