//
//  TemplateCreateBlankDocsCell.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/9/8.
//  


import UIKit
import UniverseDesignIcon
import UniverseDesignColor

class TemplateCreateBlankDocsCell: UICollectionViewCell {
    static let cellID = "TemplateCreateBlankDocsCellID"
    
    var disable: Bool = false {
        didSet {
            self.contentView.backgroundColor = disable ? UIColor.ud.bgBody.withAlphaComponent(0.4) : UIColor.ud.bgBody
        }
    }
    
    let label: UILabel = {
        let lb = UILabel()
        lb.textColor = .ud.textCaption
        lb.font = UIFont.docs.pfsc(12)
        return lb
    }()
    
    private let plusImageView: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UDIcon.getIconByKey(.addOutlined, size: CGSize(width: 40, height: 40)).ud.withTintColor(UDColor.functionInfoContentDefault)

        return imgView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UDColor.bgBody
        contentView.layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)
        contentView.layer.shadowOpacity = 1
        contentView.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.layer.shadowRadius = 12
        contentView.layer.cornerRadius = 6

        contentView.addSubview(plusImageView)
        plusImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.bottom.equalTo(self.contentView.snp.centerY).offset(6)
            make.centerX.equalToSuperview()
        }
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(plusImageView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
