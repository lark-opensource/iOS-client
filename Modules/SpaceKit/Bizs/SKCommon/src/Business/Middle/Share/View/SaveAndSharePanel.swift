//
//  SaveAndSharePanel.swift
//  TestCollectionView
//
//  Created by 吴珂 on 2020/4/16.
//  Copyright © 2020 bytedance. All rights reserved.


import Foundation
import UIKit
import RxCocoa
import RxSwift
import SKResource

public final class SaveAndSharePanel: UIView {
    
    lazy var operateButton: UIButton = {
        return UIButton(type: .custom).construct { (it) in
            it.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            it.backgroundColor = UIColor.ud.colorfulBlue
            it.layer.cornerRadius = 20
            it.layer.masksToBounds = true
            it.imageView?.contentMode = .scaleAspectFit
            it.imageEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: 0)
            it.contentEdgeInsets = UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 20)
            it.setImage(BundleResources.SKResource.Common.Pop.icon_pop_download_small_nor, for: .normal)
            it.setImage(BundleResources.SKResource.Common.Pop.icon_pop_download_small_nor, for: .highlighted)
        }
    }()
    
    let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        addSubview(operateButton)
        operateButton.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(40)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public func setType(_ type: ShareAssistType) {
        var name = ""
        switch type {
        case .wechat:
            name = BundleI18n.SKResource.Doc_BizWidget_WeChat
        case .wechatMoment:
            name = BundleI18n.SKResource.Doc_BizWidget_Moments
        case .qq:
            name = BundleI18n.SKResource.Doc_BizWidget_QQ
        case .weibo:
            name = BundleI18n.SKResource.Doc_BizWidget_Weibo
        default: ()
        }
        name = BundleI18n.SKResource.Doc_Share_DownloadAndShare(name)
        operateButton.setTitle(name, for: .normal)
    }
    
    public func setButtonClickCallback(_ callback: @escaping () -> Void) {
        operateButton.rx.tap.subscribe(onNext: { (_) in
            callback()
        }).disposed(by: disposeBag)
    }
}
