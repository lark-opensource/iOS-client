//
//  CommentFoucusTipsView.swift
//  SKCommon
//
//  Created by huayufan on 2022/3/9.
//  


import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import SKResource
import SKFoundation

class CommentFoucusTipsView: UIView {

    private var bgView = UIView()
    
    private var iconView = UIImageView()
    
    private var textLabel = UILabel()
    
    private enum Status {
        case hidden
        case show
        case invincible
    }

    private var status: Status = .hidden
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupInit()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupInit() {
        addSubview(bgView)
        bgView.addSubview(iconView)
        bgView.addSubview(textLabel)
        
        bgView.construct {
            $0.backgroundColor = UDColor.functionInfoFillSolid02
            $0.layer.cornerRadius = 6
        }
        
        iconView.construct {
            $0.image = UDIcon.infoColorful
            $0.contentMode = .scaleAspectFit
        }
        
        textLabel.construct {
            $0.font = UIFont.systemFont(ofSize: 14)
            $0.textColor = UDColor.textTitle
            $0.numberOfLines = 0
            $0.text = BundleI18n.SKResource.CreationMobile_Docs_CheckComments_StartNoticeForPad
        }
        self.innerUpdate(isHidden: true)
        self.status = .hidden
    }
    
    private func setupLayout() {
        bgView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(4)
        }

        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(12)
            make.width.height.equalTo(15)
        }
        
        textLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView)
            make.left.equalTo(iconView.snp.right).offset(8)
            make.right.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().inset(10)
        }
        
    }
    
    func innerUpdate(isHidden: Bool) {
        self.isHidden = isHidden
        self.bgView.isHidden = isHidden
        self.textLabel.isHidden = isHidden
        self.iconView.isHidden = isHidden
    }

}

extension CommentFoucusTipsView {
    
    func update(isHidden: Bool) {
        if status == .hidden { // 隐藏中：
            if !isHidden {
                self.status = .show
                self.innerUpdate(isHidden: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_5000) { [weak self] in
                    guard let self = self else { return }
                    self.status = .hidden
                    UIView.animate(withDuration: 0.25) {
                        self.innerUpdate(isHidden: true)
                    }
                }
            } // 正在隐藏中不需要在处理了
        } 
    }
}
