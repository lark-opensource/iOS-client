//
//  BitableHomePageHeader.swift
//  SKBitable
//
//  Created by qiyongka on 2023/11/2.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import SnapKit
import SKResource


final class BitableHomePageHeader: UIView {
    struct Const {
        static let iconViewSice: CGFloat = 20.0
        static let titleHeight: CGFloat = 28.0
    }
    
    var animationBeforeAlpha: CGFloat? = .zero
    
    lazy var titleLabel: UILabel = UILabel().construct { it in
        it.text = SKResource.BundleI18n.SKResource.Bitable_Workspace_Base_Title
        it.textAlignment = .center
        it.textColor = UDColor.textTitle
        it.font = UIFont.boldSystemFont(ofSize: 18)
    }
    
    lazy var searchButton: UIButton = UIButton().construct { it in
        it.isExclusiveTouch = true
        it.setImage(UDIcon.searchOutlined, for: .normal)
        it.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        it.addTarget(self, action: #selector(searchButtonDidClick), for: .touchUpInside)
    }
    
    lazy var closeButton: UIButton = UIButton().construct { it in
        it.isExclusiveTouch = true
        it.setImage(UDIcon.closeOutlined, for: .normal)
        it.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        it.addTarget(self, action: #selector(closeButtonDidClick), for: .touchUpInside)
    }
    
    lazy var specialSearchButton: UIButton = UIButton().construct { it in
        it.isExclusiveTouch = true
        it.setImage(UDIcon.searchOutlined, for: .normal)
        it.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        it.addTarget(self, action: #selector(specialSearchButtonDidClick), for: .touchUpInside)
    }
    
    lazy var zoomButton: UIButton = UIButton().construct { it in
        it.isExclusiveTouch = true
        it.setImage(UDIcon.leftOutlined, for: .normal)
        it.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        it.addTarget(self, action: #selector(zoomButtonDidClick), for: .touchUpInside)
    }
    
    private let searchHandler: (() -> Void)?
    private let closeHandler: (() -> Void)?
    private let zoomHandler: (() -> Void)?
    
    //MARK: lifeCycle
    init(searchBlock: (() -> Void)?, zoomHomePageBlock: (() -> Void)?, exitHomePageBlock: (() -> Void)? ) {
        searchHandler = searchBlock
        closeHandler = exitHomePageBlock
        zoomHandler = zoomHomePageBlock
        super.init(frame: .zero)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    //MARK: public Method    
    func updateStyleForExpand() {
        self.specialSearchButton.isHidden = false
        self.specialSearchButton.alpha = 1.0
        self.zoomButton.isHidden = false
        self.zoomButton.alpha = 1.0
        
        self.searchButton.isHidden = true
        self.searchButton.alpha = 0.0
        self.closeButton.isHidden = true
        self.closeButton.alpha = 0.0
    }
    
    func updateStyleForNormal() {
        self.specialSearchButton.isHidden = true
        self.specialSearchButton.alpha = 0.0
        self.zoomButton.isHidden = true
        self.zoomButton.alpha = 0.0
        
        self.searchButton.isHidden = false
        self.searchButton.alpha = 1.0
        self.closeButton.isHidden = false
        self.closeButton.alpha = 1.0
    }
    
    //MARK: privateMethod
    private func setupSubviews() {
        addSubview(titleLabel)
        titleLabel.sizeToFit()
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        addSubview(searchButton)
        addSubview(closeButton)
        
        closeButton.snp.makeConstraints { make in
            make.height.width.equalTo(Const.iconViewSice)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-18)
        }
    
        searchButton.snp.makeConstraints { make in
            make.height.width.equalTo(Const.iconViewSice)
            make.centerY.equalToSuperview()
            make.right.equalTo(closeButton.snp.left).offset(-20)
        }
        setupSubviewsForZoomStyle()
    }
    
    private func setupSubviewsForZoomStyle() {
        addSubview(zoomButton)
        addSubview(specialSearchButton)
        
        zoomButton.isHidden = true
        zoomButton.alpha = 0.0
        zoomButton.snp.makeConstraints { make in
            make.height.width.equalTo(Const.iconViewSice)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(20)
        }
        
        specialSearchButton.isHidden = true
        specialSearchButton.alpha = 0.0
        specialSearchButton.snp.makeConstraints { make in
            make.height.width.equalTo(Const.iconViewSice)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-18)
        }
    }
    
    //MARK: 交互
    @objc
    func searchButtonDidClick() {
        searchHandler?()
    }
    
    @objc
    func specialSearchButtonDidClick() {
        searchHandler?()
    }
    
    @objc
    func closeButtonDidClick() {
        closeHandler?()
    }
    
    @objc
    func zoomButtonDidClick() {
        zoomHandler?()
    }
}
