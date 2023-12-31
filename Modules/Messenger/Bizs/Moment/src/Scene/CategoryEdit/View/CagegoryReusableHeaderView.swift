//
//  CagegoryReusableHeaderView.swift
//  Moment
//
//  Created by liluobin on 2021/5/19.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignButton
import LarkInteraction

final class CagegoryReusableFooterView: UICollectionReusableView {
    static let reuseId: String = "CagegoryReusableFooterView"
}
final class CagegoryReusableHeaderView: UICollectionReusableView {
    static let reuseId: String = "CagegoryReusableHeaderView"
    let titleLabel = UILabel()
    let desLabel = UILabel()
    var editCallBack: (() -> Void)?
    var isEditing: Bool = false {
        didSet {
            updateEditStatus()
        }
    }
    let editBtn = UIButton()
    private lazy var loadingView: UDButton = {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                      backgroundColor: UIColor.clear,
                                                      textColor: UIColor.ud.colorfulBlue)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.colorfulBlue)
        let config = UDButtonUIConifg(normalColor: normalColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.colorfulBlue,
                                      type: .big,
                                      radiusStyle: .square)
        let btn = UDButton(config)
        btn.isUserInteractionEnabled = false
        return btn
    }()

    var currentStyle: CategoryEditHeaderStyle = .single
    var item: CategoryEditHeaderItem? {
        didSet {
            updateStyle()
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateUIWithTitle(_ title: String, des: String, showEdit: Bool) {
        if item?.hadEditItems ?? true {
            desLabel.text = des
            titleLabel.text = title
        } else {
            desLabel.text = ""
            titleLabel.text = isEditing ? title : ""
        }
        editBtn.isHidden = !showEdit
    }

    private func updateStyle() {
        guard let item = item else {
            return
        }
        updateUIWithTitle(item.title, des: item.des, showEdit: item.showEditBtn)
        if item.settingTab {
            showloading()
        } else {
            hideLoading()
        }
        if currentStyle == item.style {
            return
        }
        switch item.style {
        case .single:
            setSingleStyle()
        case .multiline(let desHeight):
            setMultilineStyleWithDesHeight(desHeight)
        }
        currentStyle = item.style
    }

    private func setSingleStyle() {
        titleLabel.snp.remakeConstraints { (make) in
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        desLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.right).offset(8)
            make.centerY.equalTo(titleLabel)
            make.right.lessThanOrEqualTo(editBtn.snp.left).offset(-8)
        }
        editBtn.snp.remakeConstraints { (make) in
            make.right.equalToSuperview()
            make.centerY.equalTo(titleLabel)
        }
    }
    private func setMultilineStyleWithDesHeight(_ height: CGFloat) {
        titleLabel.snp.remakeConstraints { (make) in
            make.left.equalToSuperview()
            make.bottom.equalTo(desLabel.snp.top).offset(-8)
        }
        desLabel.snp.remakeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(height)
            make.bottom.equalToSuperview()
        }
        editBtn.snp.remakeConstraints { (make) in
            make.right.equalToSuperview()
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.height.equalTo(40)
        }
    }

    // 配置UI
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(desLabel)
        addSubview(editBtn)
        addSubview(loadingView)
        desLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        desLabel.numberOfLines = 0
        editBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        editBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .selected)
        editBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        editBtn.addTarget(self, action: #selector(editBtnClick(_:)), for: .touchUpInside)
        editBtn.titleLabel?.textAlignment = .right
        editBtn.setTitle(BundleI18n.Moment.Lark_Community_Edit, for: .normal)
        editBtn.setTitle(BundleI18n.Moment.Lark_Community_Done, for: .selected)
        editBtn.addPointer(.highlight)
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor.ud.N900
        desLabel.font = UIFont.systemFont(ofSize: 14)
        desLabel.textColor = UIColor.ud.N500
        setSingleStyle()
        updateEditStatus()
        loadingView.snp.makeConstraints { (make) in
            make.center.equalTo(editBtn)
        }
    }

    private func updateEditStatus() {
        editBtn.isSelected = isEditing
        hideDesLabelIfNeed()
        if let item = item {
            updateUIWithTitle(item.title, des: item.des, showEdit: item.showEditBtn)
            switch item.style {
            case .single:
                break
            case .multiline(let desHeight):
                var height: CGFloat = isEditing ? desHeight : desLabel.font.rowHeight(forLines: 1)
                height = desLabel.isHidden ? 0 : height
                desLabel.snp.updateConstraints { (make) in
                    make.height.equalTo(height)
                }
            }
        }
    }

    private func hideDesLabelIfNeed() {
        if isEditing {
            desLabel.isHidden = false
        } else {
            desLabel.isHidden = (item?.loadingTab ?? false) ? false : true
            if item?.loadingTab ?? false {
                desLabel.text = BundleI18n.Moment.Lark_Community_LoadingToast
            }
        }
    }

    func showloading() {
        loadingView.showLoading()
        loadingView.isHidden = false
        editBtn.isHidden = true
    }

    func hideLoading() {
        loadingView.hideLoading()
        loadingView.isHidden = true
        editBtn.isHidden = !(self.item?.showEditBtn ?? true)
    }

    @objc
    private func editBtnClick(_ btn: UIButton) {
        editCallBack?()
    }
}
