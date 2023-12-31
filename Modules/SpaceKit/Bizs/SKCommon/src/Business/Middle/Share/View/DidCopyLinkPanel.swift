//
//  CopyLinkPanel.swift
//  TestCollectionView
//
//  Created by 吴珂 on 2020/4/15.
//  Copyright © 2020 bytedance. All rights reserved.


import Foundation
import UIKit
import SnapKit
import RxCocoa
import RxSwift
import SKResource
import UniverseDesignColor
// nolint: duplicated_code
class DidCopyLinkPanel: UIView {
    
    var type: ShareAssistType = .wechat {
        didSet {
            var image = UIImage()
            var color: UIColor?
            var appName: String = ""
            var formatString: String = ""
            if type == .wechat {
                image = BundleResources.SKResource.Common.Pop.icon_pop_wechat_small_nor
                appName = BundleI18n.SKResource.Doc_BizWidget_WeChat
                formatString = BundleI18n.SKResource.Doc_Share_PasteToFriends(appName)
                color = UIColor.ud.G600
            } else if type == .wechatMoment {
                image = BundleResources.SKResource.Common.Pop.pop_moments_small
                appName = BundleI18n.SKResource.Doc_BizWidget_Moments
                formatString = BundleI18n.SKResource.Doc_Share_ShareToExternalApp(appName)
                color = UIColor.ud.G600
            } else if type == .qq {
                image = BundleResources.SKResource.Common.Pop.icon_pop_qq_small_nor
                appName = BundleI18n.SKResource.Doc_BizWidget_QQ
                formatString = BundleI18n.SKResource.Doc_Share_PasteToFriends(appName)
                color = UIColor.ud.colorfulWathet
            } else if type == .weibo {
                appName = BundleI18n.SKResource.Doc_BizWidget_Weibo
                image = BundleResources.SKResource.Common.Pop.icon_pop_weibo_small_nor
                formatString = BundleI18n.SKResource.Doc_Share_ShareToExternalApp(appName)
                color = UIColor.ud.colorfulRed
            }
            shareButton.setImage(image, for: .normal)
            shareButton.setImage(image, for: .highlighted)
            shareButton.setTitle(formatString, for: .normal)
            shareButton.backgroundColor = color
        }
    }
    
    lazy var titleLabel: UILabel = {
        return UILabel(frame: .zero).construct { (it) in
            it.font = UIFont.systemFont(ofSize: 17).medium
            it.text = BundleI18n.SKResource.Doc_Share_LinkCopied
            it.textAlignment = .center
            it.textColor = UIColor.ud.N900
        }
    }()
    
    lazy var contentLabel: UILabel = {
        return UILabel(frame: .zero).construct { (it) in
            it.font = UIFont.systemFont(ofSize: 15)
            it.lineBreakMode = .byTruncatingTail
            it.textAlignment = .left
            it.numberOfLines = 3
            it.textColor = UIColor.ud.N600
        }
    }()
    
    lazy var contentBackgroundView: UIView = {
        return UIView(frame: .zero).construct { (it) in
            it.backgroundColor = UDColor.bgBody
            it.layer.cornerRadius = 4
        }
    }()
    
    lazy var shareButton: UIButton = {
        return UIButton(type: .custom).construct { (it) in
            it.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            it.backgroundColor = .purple
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
    
    let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        backgroundColor = UDColor.bgBody
        layer.cornerRadius = 8
        
        addSubview(titleLabel)
        addSubview(shareButton)
        addSubview(exitButton)
        addSubview(contentBackgroundView)
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        
        contentBackgroundView.addSubview(contentLabel)
        contentBackgroundView.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalTo(titleLabel)
        }
        
        contentLabel.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview().offset(12)
            make.right.bottom.equalToSuperview().offset(-12)
        }

        shareButton.snp.makeConstraints { (make) in
            make.top.equalTo(contentLabel.snp.bottom).offset(34)
            make.left.right.equalTo(contentBackgroundView)
            make.height.equalTo(40)
        }

        exitButton.snp.makeConstraints { (make) in
            make.top.equalTo(shareButton.snp.bottom).offset(16)
            make.left.right.equalTo(shareButton)
            make.height.equalTo(22)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
    
    func setContentString(_ content: String) {
        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = 4
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15),
                          NSAttributedString.Key.paragraphStyle: paraph,
                          NSAttributedString.Key.foregroundColor: UIColor.ud.N600
        ]
        contentLabel.attributedText = NSAttributedString(string: content, attributes: attributes)
        contentLabel.lineBreakMode = .byTruncatingTail
    }
}

extension DidCopyLinkPanel {
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
