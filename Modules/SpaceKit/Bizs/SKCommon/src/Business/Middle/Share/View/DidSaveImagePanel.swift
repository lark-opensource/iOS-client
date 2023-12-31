//
//  DidSaveImagePanel.swift
//  SpaceKit
//
//  Created by 吴珂 on 2020/4/22.
//  


import Foundation
import UIKit
import SnapKit
import RxCocoa
import RxSwift
import SKResource

class DidSaveImagePanel: UIView {
    
    lazy var titleLabel: UILabel = {
        return UILabel(frame: .zero).construct { (it) in
            it.font = UIFont.systemFont(ofSize: 17)
            it.text = BundleI18n.SKResource.Doc_Share_ImageSavedToAlbum
            it.textAlignment = .center
            it.textColor = UIColor.ud.N900
        }
    }()
    
    lazy var shareButton: UIButton = {
        return UIButton(type: .custom).construct { (it) in
            it.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            it.backgroundColor = UIColor.ud.colorfulBlue
            it.layer.masksToBounds = true
            it.layer.cornerRadius = 4
            it.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
            it.imageView?.contentMode = .scaleAspectFit
            it.imageView?.layer.allowsEdgeAntialiasing = true
        }
    }()
    
    lazy var exitButton: UIButton = {
        return UIButton(type: .custom).construct { (it) in
            it.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            it.setTitle(BundleI18n.SKResource.Doc_Share_Cancel, for: .normal)
            it.setTitleColor(UIColor.ud.N600, for: .normal)
        }
    }()
    
    var type: ShareAssistType = .wechat {
        didSet {
            var image = UIImage()
            var color: UIColor?
            var appName: String = ""
            if type == .wechat {
                image = BundleResources.SKResource.Common.Pop.icon_pop_wechat_small_nor
                appName = BundleI18n.SKResource.Doc_BizWidget_WeChat
                color = UIColor.ud.G600
            } else if type == .wechatMoment {
                image = BundleResources.SKResource.Common.Pop.pop_moments_small
                appName = BundleI18n.SKResource.Doc_BizWidget_Moments
                
                color = UIColor.ud.G600
            } else if type == .qq {
                image = BundleResources.SKResource.Common.Pop.icon_pop_qq_small_nor
                appName = BundleI18n.SKResource.Doc_BizWidget_QQ
                color = UIColor.ud.colorfulWathet
            } else if type == .weibo {
                appName = BundleI18n.SKResource.Doc_BizWidget_Weibo
                image = BundleResources.SKResource.Common.Pop.icon_pop_weibo_small_nor
                color = UIColor.ud.colorfulRed
            }
            let formatString: String = BundleI18n.SKResource.Doc_Share_ContinueShare(appName)
            shareButton.setImage(image, for: .normal)
            shareButton.setImage(image, for: .highlighted)
            shareButton.setTitle(formatString, for: .normal)
            shareButton.backgroundColor = color
        }
    }
    
    let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        backgroundColor = UIColor.ud.N00
        layer.cornerRadius = 8
        
        self.addSubview(titleLabel)
        self.addSubview(shareButton)
        self.addSubview(exitButton)
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        

        shareButton.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.left.right.equalTo(titleLabel)
            make.height.equalTo(40)
        }

        exitButton.snp.makeConstraints { (make) in
            make.top.equalTo(shareButton.snp.bottom).offset(16)
            make.left.right.equalTo(shareButton)
            make.height.equalTo(22)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
}

extension DidSaveImagePanel {
    func setShareButtonClickCallback(_ callback: @escaping () -> Void) {
        shareButton.rx.tap.subscribe(onNext: { _ in
            callback()
        })
        .disposed(by: disposeBag)
    }
    
    func setExitButtonClickCallback(_ callback: @escaping () -> Void) {
        exitButton.rx.tap.subscribe(onNext: { _ in
            callback()
        })
        .disposed(by: disposeBag)
    }
}
