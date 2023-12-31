//
//  DocDetailBasicInfoCell.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/1/17.
//  


import Foundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UIKit
import SKUIKit

// 字数统计/drive基本信息
class DocDetailBasicInfoCell: UITableViewCell {
    
    static let reuseIdentifier = "DocDetailBasicInfoCell"
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UDColor.textTitle
        label.textAlignment = .left
        return label
    }()
    
    private lazy var itemsView: UIStackView = {
        let stackv = UIStackView()
        stackv.axis = .vertical
        stackv.distribution = .fillEqually
        stackv.alignment = .leading
        stackv.spacing = 8
        return stackv
    }()

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentView.addSubview(titleLabel)
        contentView.addSubview(itemsView)
        contentView.addSubview(lineView)
    }
    
    func update(info: DocsDetailInfoBaseInfo) {
        titleLabel.text = info.title
        
        itemsView.arrangedSubviews.forEach {
            itemsView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        for rowText in info.rowTexts {
            let itemView = DocDetailCreateInfoItemView()
            itemView.titleLabel.text = rowText.title + ": "
            itemView.valueLabel.text = rowText.value == "N/A" ? "- -" : rowText.value
            itemsView.addArrangedSubview(itemView)
            itemView.isHidden = rowText.value.isEmpty
        }
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-10)
            make.height.equalTo(20)
            make.top.equalToSuperview().offset(16)
        }
        
        itemsView.snp.makeConstraints {
            $0.leading.trailing.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.bottom.equalTo(-16)
        }
        
        lineView.snp.makeConstraints { (make) in
            make.height.equalTo(1)
            make.leading.equalTo(titleLabel)
            make.trailing.bottom.equalToSuperview()
        }
    }
}

// 单个信息item视图
private class DocDetailCreateInfoItemView: UIView {
    
    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textTitle
        label.textAlignment = .left
        return label
    }()
    
    private(set) lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textTitle
        label.textAlignment = .left
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.height.equalTo(20)
        }
        
        addSubview(valueLabel)
        valueLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing)
            $0.trailing.top.bottom.equalToSuperview()
            $0.height.equalTo(20)
        }
    }
}
