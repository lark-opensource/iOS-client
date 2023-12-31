//
//  BitableHomeStateView.swift
//  SKBitable
//
//  Created by justin on 2023/9/11.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignEmpty
import UniverseDesignColor
import FigmaKit
import SKResource


public enum BitableHomePageState: Int {
    case loading
    case dataEmpty
    case requestFail
}

public protocol StateViewDelegate: AnyObject {
    func tapStateView(state: BitableHomePageState)
}

public class BitableHomeStateView: UIView {
    
    let centerView: UIView
    weak var delegate: StateViewDelegate?
    
    lazy var stateImage: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    lazy var tipsLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(hexString: "#646A73")
        return label
    }()
    
    var state: BitableHomePageState
    
    public init(frame: CGRect, state: BitableHomePageState, delegate: StateViewDelegate? = nil) {
        
        centerView = UIView(frame: .zero)
        centerView.backgroundColor = .clear
        
        self.state = state
        self.delegate = delegate
        super.init(frame: frame)
        self.backgroundColor = UDColor.bgBody
        
        addSubview(centerView)
        centerView.addSubview(stateImage)
        
        let imageInfo = Self.stateImageInfo(state: state)
        stateImage.image = imageInfo.image
        stateImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(imageInfo.size.width)
            make.height.equalTo(imageInfo.size.height)
            make.top.equalToSuperview()
        }
        
        centerView.addSubview(tipsLabel)
        let tips = Self.stateTips(state: state)
        tipsLabel.text = tips
        tipsLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(stateImage.snp.bottom)
            make.height.equalTo(CGFloat(20.0))
            make.bottom.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        
        centerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        self.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapStateView))
        self.addGestureRecognizer(tapGesture)
    }
    
    
    @objc func tapStateView() {
        guard let tapDelegate = self.delegate else {
            return
        }
        tapDelegate.tapStateView(state: self.state)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateViewState(state: BitableHomePageState) {
        let imageInfo = Self.stateImageInfo(state: state)
        stateImage.image = imageInfo.image
        stateImage.snp.updateConstraints { make in
            make.width.equalTo(imageInfo.size.width)
            make.height.equalTo(imageInfo.size.height)
        }
        
        let tips = Self.stateTips(state: state)
        tipsLabel.text = tips

    }
    
    static func stateImageInfo(state: BitableHomePageState) -> (image: UIImage, size: CGSize) {
        switch state {
        case .loading:
            return (UDIcon.getIconByKey(.loadingOutlined), CGSize(width: 125.0, height: 125.0))
        case .dataEmpty:
            return (UDEmptyType.noContent.defaultImage(), CGSize(width: 110.0, height: 120.0))
        case .requestFail:
            return (UDEmptyType.code404.defaultImage(), CGSize(width: 110.0, height: 110.0))
        }
    }
    
    static func stateTips(state: BitableHomePageState) -> String {
        switch state {
        case .loading:
            return  BundleI18n.SKResource.Bitable_Homepage_Loading_Desc
        case .dataEmpty:
            return  BundleI18n.SKResource.Bitable_Homepage_Mobile_NoContent_Desc
        case .requestFail:
            return BundleI18n.SKResource.Bitable_Homepage_Mobile_TapToRetry_Desc
        }
    }
    
}
