//
//  SecretGridViewController+cell.swift
//  SKCommon
//
//  Created by tanyunpeng on 2023/4/20.
//  


import Foundation
import UIKit
import SnapKit
import UniverseDesignColor

class UICollectionGridViewCell: UICollectionViewCell {
    
    //内容标签
    lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    lazy var avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private lazy var colorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    private lazy var colorLine1: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    //标签左边距
    var paddingLeft:CGFloat = 5
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //单元格边框
        self.backgroundColor = UDColor.udtokenTableBgHead
        self.clipsToBounds = true
        
        self.contentView.addSubview(label)
        self.contentView.addSubview(colorLine)
        self.contentView.addSubview(colorLine1)
        self.contentView.addSubview(avatarView)

        colorLine.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-1)
            make.height.equalTo(0.5)
        }
        
        colorLine1.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(0.5)
            make.height.right.equalToSuperview()
        }
        
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(18)
        }
        
        avatarView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.width.equalTo(20)
        }
                
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateLine() {
        colorLine.isHidden = false
    }
    
    func hideLine() {
        colorLine.isHidden = true
    }
    
    func updateLine2() {
        colorLine1.isHidden = false
    }
    
    func hideLine2() {
        colorLine1.isHidden = true
    }
    
}
