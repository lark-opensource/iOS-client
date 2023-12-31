//
//  AtPageNormalHeaderView.swift
//  SKCommon
//
//  Created by zengsenyuan on 2021/11/10.
//  

import Foundation
import UIKit
import SKResource
import UniverseDesignColor

class AtPageNormalHeaderView: UIView {
    
    typealias CancelAction = (() -> Void)
    
    var cancelAction: CancelAction?
    
    private lazy var cancelButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(BundleI18n.SKResource.Doc_Facade_Cancel, for: .normal)
        btn.setTitleColor(UIColor.ud.textTitle, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.addTarget(self, action: #selector(cancelBtnDidPressed), for: .touchUpInside)
        return btn
    }()
    
    private lazy var fakeCoupleView = UIView() // 为了让标题居中，放在cancelButton的另一侧的虚拟视图
    
    private let noticeLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Doc_At_MentionTip
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UDColor.textTitle
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        return label
    }()

    private let seperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayouts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateNoticeText(_ text: String) {
        self.noticeLabel.text = text
    }
    
    func setCancelButtonHidden(_ isHidden: Bool) {
        self.cancelButton.isHidden = isHidden
        configCancelButtonLayout(isBtnHidden: isHidden)
    }
    
    @objc
    private func cancelBtnDidPressed(_ btn: UIButton) {
        cancelAction?()
    }
    
    private func setupViews() {
        self.clipsToBounds = true
        addSubview(noticeLabel)
        addSubview(cancelButton)
        addSubview(fakeCoupleView)
        addSubview(seperatorView)
    }
    
    private func setupLayouts() {
        configCancelButtonLayout(isBtnHidden: false)
        seperatorView.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    private func configCancelButtonLayout(isBtnHidden: Bool) {
        
        cancelButton.snp.remakeConstraints { make in
            make.left.equalTo(2)
            if isBtnHidden {
                make.width.equalTo(0)
            } else {
                make.centerX.equalTo(self.snp.left).offset(16 + 20) // 垂直对齐AtCell里的头像
            }
            make.top.height.equalToSuperview()
        }
        
        fakeCoupleView.snp.remakeConstraints { make in
            make.right.equalTo(-2)
            make.width.equalTo(cancelButton)
            make.top.height.equalToSuperview()
        }
        
        noticeLabel.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().labeled("align to top")
            make.left.equalTo(cancelButton.snp.right)
            make.right.equalTo(fakeCoupleView.snp.left)
            make.height.equalToSuperview()
        }
    }
}
