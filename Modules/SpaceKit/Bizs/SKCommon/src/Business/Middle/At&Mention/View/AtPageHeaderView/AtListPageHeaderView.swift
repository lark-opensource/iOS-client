//
//  AtListPageHeaderView.swift
//  SKCommon
//
//  Created by zengsenyuan on 2021/11/10.
//  

import Foundation
import UIKit
import SKResource
import UniverseDesignColor
import SKFoundation

enum ATPageHeaderType {
    case normal(title: String)
    case checkbox(data: AtCheckboxData)
}

class AtListPageHeaderView: UIView {
    
    /// 处于普通状态时，是否隐藏取消按钮
    var isSetCancelButtonHiddenWhenInNormal: Bool = false {
        didSet {
            normalHeaderView.setCancelButtonHidden(isSetCancelButtonHiddenWhenInNormal)
        }
    }
    /// 处于普通状态时点击取消按钮回调
    var cancelActionWhenInNormal: AtPageNormalHeaderView.CancelAction? {
        didSet {
            normalHeaderView.cancelAction = cancelActionWhenInNormal
        }
    }
    /// 处于checkbox 状态时点击 checkbox 按钮回调
    var checkboxActionWhenInCheckbox: AtPageCheckboxHeaderView.CheckboxAction? {
        didSet {
            checkboxView.checkboxAction = checkboxActionWhenInCheckbox
        }
    }
    
    
    struct Metric {
        static var normalHeaderHeight: CGFloat = 48
    }

    
    private(set) var type: ATPageHeaderType = .normal(title: BundleI18n.SKResource.Doc_At_MentionTip)
    private let normalHeaderView = AtPageNormalHeaderView()
    private let checkboxView = AtPageCheckboxHeaderView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func changeHeaderType(_ type: ATPageHeaderType) {
        self.type = type
        switch type {
        case .normal(let title):
            checkboxView.isHidden = true
            normalHeaderView.isHidden = false
            normalHeaderView.updateNoticeText(title)
        case .checkbox(let checkboxData):
            normalHeaderView.isHidden = true
            checkboxView.isHidden = false
            checkboxView.updateCheckboxData(checkboxData)
        }
    }
    
    static func getHeaderHeight(_ type: ATPageHeaderType, headerWidth: CGFloat) -> CGFloat {
        switch type {
        case .normal:
            return Metric.normalHeaderHeight
        case .checkbox(let checkboxData):
            let height = AtPageCheckboxHeaderView.calculateHeight(with: headerWidth, text: checkboxData.text)
            DocsLogger.debug("AtPageCheckboxHeaderView height: \(height), by width: \(headerWidth)")
            return height
        }
    }
    
    private func setupViews() {
        self.addSubview(normalHeaderView)
        self.addSubview(checkboxView)
        self.clipsToBounds = true
    }
    
    private func setupLayouts() {
        normalHeaderView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(Metric.normalHeaderHeight)
        }
        checkboxView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
