//
//  BTAutoSortCell.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/27.
//  



import SKUIKit
import SKResource
import UniverseDesignSwitch
import UniverseDesignColor


public final class BTAutoSortCell: UITableViewCell {
 
    var didChangeAutoSortTo: ((Bool) -> Void)?
    
    var didTapSwitch: (() -> Void)?
    
    private let containerView = UIView().construct {
        $0.backgroundColor = UDColor.bgFloat
        $0.layer.cornerRadius = 10
    }
    
    private let titleLabel = UILabel().construct {
        $0.textColor = UDColor.textTitle
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.text = BundleI18n.SKResource.Bitable_Record_AutomaticSort
    }
    
    private let udSwitch = UDSwitch()
   
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func config(autoSort: Bool, enable: Bool) {
        self.udSwitch.setOn(autoSort, animated: false)
        self.udSwitch.isEnabled = enable
    }
    
    private func setupViews() {
        self.backgroundColor = .clear
        self.selectionStyle = .none
        contentView.backgroundColor = .clear
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(udSwitch)
        
        udSwitch.valueChanged = { [weak self] on in
            self?.didChangeAutoSortTo?(on)
        }
        udSwitch.tapCallBack = { [weak self] sender in
            self?.didTapSwitch?()
        }
        
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        udSwitch.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 48, height: 28))
        }
    }
}
