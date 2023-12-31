//
//  BitableTabSwitchView.swift
//  CCMMod
//
//  Created by ByteDance on 2023/7/16.
//

import UIKit
import UniverseDesignColor
import SKResource
import SKCommon
import SKFoundation
import LarkSetting

public class BitableTabSwitchView: UIView {
    public enum Event {
       case recommendVC
       case baseHomeVC
    }
    
    var buttonAction: ((Event) -> Void)
    var firstShowBaseHomeVC: Bool
    
    //MARK: childViews
    private lazy var recommendBtn : UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UDColor.textCaption, for: .normal)
        btn.setTitleColor(UDColor.textTitle, for: .selected)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.backgroundColor = .clear
        btn.sizeToFit()
        return btn
    }()
    
    private lazy var baseHomeBtn : UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UDColor.textCaption, for: .normal)
        btn.setTitleColor(UDColor.textTitle, for: .selected)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.backgroundColor = .clear
        btn.sizeToFit()
        return btn
    }()
        
    private lazy var leftSelectLine : UIView = {
        let selectLine = UIView()
        selectLine.layer.cornerRadius = 1
        selectLine.layer.masksToBounds = true
        selectLine.backgroundColor = UDColor.primaryContentDefault
        selectLine.isUserInteractionEnabled = false
        return selectLine
    }()
    
    private lazy var rightSelectLine : UIView = {
        let selectLine = UIView()
        selectLine.layer.cornerRadius = 1
        selectLine.layer.masksToBounds = true
        selectLine.backgroundColor = UDColor.primaryContentDefault
        selectLine.isUserInteractionEnabled = false
        return selectLine
    }()
    
    private lazy var bottomLine : UIView = {
        let bottomLine = UIView()
        bottomLine.backgroundColor = UDColor.lineDividerDefault
        bottomLine.isUserInteractionEnabled = false
        return bottomLine
    }()
    
    //MARK: 构造方法
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(firstShowBaseHomeVC: Bool = false, buttonAction: @escaping ((Event) -> Void)) {
        self.buttonAction = buttonAction
        self.firstShowBaseHomeVC = firstShowBaseHomeVC
        super.init(frame: .zero)
        setupUI()
    }
    
    private func setupUI() {
        var recommendTitle = BundleI18n.SKResource.Bitable_Homepage_Mobile_Recommended_Header
        var baseHomeTitle = BundleI18n.SKResource.Bitable_Homepage_Mobile_Home_Header
        do {
            let homepageConfig = try SettingManager.shared.setting(with: .make(userKeyLiteral: "ccm_base_homepage"))
            if let remoteRecommendT = homepageConfig["homePageLeftTabTitle"] as? String {
                recommendTitle = remoteRecommendT
            }
            if let remoteHomeT = homepageConfig["homePageRightTabTitle"] as? String {
                baseHomeTitle = remoteHomeT
            }
        } catch {
            DocsLogger.error("ccm_base_homepage get settings error", error: error)
        }
        
        recommendBtn.isSelected = !self.firstShowBaseHomeVC
        recommendBtn.setTitle(recommendTitle, for: .normal)
        recommendBtn.addTarget(self, action: #selector(didClickRecommend(button:)), for: .touchUpInside)
        self.addSubview(recommendBtn)
        recommendBtn.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.equalToSuperview()
            make.left.top.equalToSuperview().offset(0)
        }
        
        baseHomeBtn.isSelected = self.firstShowBaseHomeVC
        baseHomeBtn.setTitle(baseHomeTitle, for: .normal)
        baseHomeBtn.addTarget(self, action: #selector(didClickBaseHome(button: )), for: .touchUpInside)
        self.addSubview(baseHomeBtn)
        baseHomeBtn.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.equalToSuperview()
            make.right.top.equalToSuperview().offset(0)
        }
       
        self.addSubview(bottomLine)
        bottomLine.snp.makeConstraints ({ make in
            make.height.equalTo(1)
            make.left.right.bottom.equalToSuperview().offset(0)
        })
      
        self.addSubview(leftSelectLine)
        leftSelectLine.snp.makeConstraints ({ make in
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.equalTo(2)
            make.left.equalToSuperview().offset(0)
            make.bottom.equalToSuperview().offset(0)
        })
        
        self.addSubview(rightSelectLine)
        rightSelectLine.snp.makeConstraints ({ make in
            make.width.equalToSuperview().multipliedBy(0.5)
            make.height.equalTo(2)
            make.right.equalToSuperview().offset(0)
            make.bottom.equalToSuperview().offset(0)
        })
        
        self.leftSelectLine.isHidden = self.firstShowBaseHomeVC
        self.rightSelectLine.isHidden = !self.firstShowBaseHomeVC
    }
    
    //MARK: event
    @objc func didClickRecommend(button:UIButton){
        recommendBtn.isSelected = true
        baseHomeBtn.isSelected = false
        leftSelectLine.isHidden = false
        rightSelectLine.isHidden = true
        buttonAction(.recommendVC)
    }
    
    @objc func didClickBaseHome(button:UIButton){
        baseHomeBtn.isSelected = true
        recommendBtn.isSelected = false
        leftSelectLine.isHidden = true
        rightSelectLine.isHidden = false
        buttonAction(.baseHomeVC)
    }
}
