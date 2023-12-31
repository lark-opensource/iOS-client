//
//  SpaceHiddenFolderCell.swift
//  SKSpace
//
//  Created by majie.7 on 2022/2/18.
//

import SKUIKit
import UniverseDesignIcon
import UniverseDesignColor
import UIKit
import SKResource

class HiddenFolderView: UIView {
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBase
        return view
    }()
    
    private let bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()
    
    private let textLabel: UILabel = {
        let view = UILabel()
        view.text = BundleI18n.SKResource.Doc_List_HiddenFolders
        view.textAlignment = .left
        view.backgroundColor = .clear
        view.font = UIFont.systemFont(ofSize: 17)
        return view
    }()
    
    private let icon: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.rightSmallCcmOutlined
        view.backgroundColor = .clear
        return view
    }()
    
    private let sperator: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBase
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = UDColor.bgBody
        self.addSubview(headerView)
        self.addSubview(bottomView)
        self.addSubview(sperator)
        self.bottomView.addSubview(textLabel)
        self.bottomView.addSubview(icon)
        
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(8)
        }
        
        bottomView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(70)
        }
        
        textLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-60)
            make.height.equalTo(24)
        }
        
        icon.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-22)
            make.centerY.equalToSuperview()
            make.width.equalTo(20)
            make.height.equalTo(20)
        }
        
        sperator.snp.makeConstraints { make in
            make.top.equalTo(bottomView.snp.bottom)
            make.left.equalTo(bottomView.snp.left).offset(16)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}

class SpaceHiddenFolderCell: UICollectionViewCell {
    private var hiddenContentView: UIView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hiddenContentView?.removeFromSuperview()
        hiddenContentView = nil
    }
    
    func update(hiddenContentView: UIView) {
        self.hiddenContentView = hiddenContentView
        contentView.addSubview(hiddenContentView)
        hiddenContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
