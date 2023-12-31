//
//  IMMentionSectionHeaderView.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/21.
//

import Foundation
import UIKit

final class IMMentionSectionHeaderView: UITableViewHeaderFooterView {
    var titleLabel = UILabel()
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont(name: "PingFangSC-Regular", size: 14)
        backgroundColor = UIColor.ud.bgBase
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class IMMentionSectionFooterView: UIView {
    var titleLable = UILabel()
    init(title: String){
        titleLable.text = title
        titleLable.textColor = UIColor.ud.textTitle
        titleLable.font = UIFont(name: "PingFangSC-Regular", size: 14)
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.ud.bgBody
        addSubview(titleLable)
        titleLable.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class IMMentionTableFooterView: UIView {
    var titleLable = UILabel()
    init(title: String){
        titleLable.text = title
        titleLable.textColor = UIColor.ud.textPlaceholder
        titleLable.font = UIFont(name: "PingFangSC-Regular", size: 14)
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.ud.bgBody
        addSubview(titleLable)
        titleLable.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
