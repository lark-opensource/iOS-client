//
//  BitableInsertChartHeader.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/12.
//

import Foundation
import UniverseDesignColor
import SnapKit
import UniverseDesignIcon

struct BitableInsertChartHeaderLayoutConfig {
    static let titleLabelFont: UIFont = UIFont.systemFont(ofSize: 17.0)
    static let editButtonFont: UIFont = UIFont.systemFont(ofSize: 14.0)
    static let maskCorner: CGFloat = 20.0
    static let buttonCorner8: CGFloat = 8.0
    static let editbuttonSize: CGSize = CGSizeMake(44.0, 28.0)
}


protocol BitableInsertChartHeaderDelegate: AnyObject {
    func headerArrowActionTrigger(isOpen: Bool, headerView: BitableInsertChartHeader)
}

class BitableInsertChartHeader: UICollectionReusableView {
    var sectionNumber: Int = 0
    private var isOpen = true
    weak var delegate: BitableInsertChartHeaderDelegate?
    
    private lazy var bgView: UIView = {
        let bgView = UIView(frame: .zero)
        bgView.backgroundColor = .clear
        return bgView
    }()
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        titleLabel.textAlignment = .left
        titleLabel.font =  UIFont(name: "PingFangSC-Regular", size: 14)
        titleLabel.textColor = UDColor.textTitle
        titleLabel.sizeToFit()
        return titleLabel
    }()
    
    private lazy var arrowButton: UIButton = {
        let image = UDIcon.getIconByKey(.rightBoldOutlined, iconColor: UDColor.iconN3)
        let arrowButton = UIButton(frame: .zero)
        arrowButton.transform = CGAffineTransformRotate(arrowButton.transform, -.pi/2)
        arrowButton.setImage(image, for: .normal)
        arrowButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        arrowButton.hitTestEdgeInsets = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        return arrowButton
    }()
    
    private lazy var titleImageView: UIImageView = {
        let titleImageView = UIImageView(frame: .zero)
        titleImageView.image = UDIcon.getIconByKey(.burnlifeNotimeOutlined, iconColor: UDColor.iconN1)
        return titleImageView
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UDColor.bgFloatBase
        
        addSubview(bgView)
        
        bgView.addSubview(titleImageView)
        bgView.addSubview(titleLabel)
        bgView.addSubview(arrowButton)
        
        bgView.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(0)
            make.width.height.equalToSuperview()
        }
        
        titleImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(titleImageView.snp.right).offset(6)
            make.right.lessThanOrEqualTo(arrowButton.snp.left).offset(-6)
            make.centerY.equalToSuperview()
        }
        
        arrowButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        arrowButton.addTarget(self,
                              action: #selector(arrowButtonTapped),
                              for: .touchUpInside)
    }
    
    func updateTitleText(title: String?)  {
        self.titleLabel.text = title
    }
    
    @objc private func arrowButtonTapped(button: UIButton){
        self.delegate?.headerArrowActionTrigger(isOpen: self.isOpen, headerView: self)
    }

    func changeArrowDirection(isOpen: Bool, withAnimation: Bool = true, complete: (() ->Void)? = nil) {
        if isOpen != self.isOpen,
           self.arrowButton.tag == 0 {
            //0 表示动画播放结束，max 表示动画中
            self.isOpen = isOpen
            if withAnimation {
                if self.arrowButton.tag == 0 {
                    self.arrowButton.tag = .max
                    UIView.animate(withDuration: 0.3) {
                        self.arrowButton.transform = CGAffineTransformRotate(self.arrowButton.transform, .pi)
                    } completion: { _ in
                        self.arrowButton.tag = 0
                        complete?()
                    }
                }
            } else {
                self.arrowButton.tag = 0
                self.arrowButton.transform = CGAffineTransformRotate(self.arrowButton.transform, .pi)
                complete?()
            }
        }
    }
}
