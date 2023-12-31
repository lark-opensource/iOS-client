//
//  SearchSettingCell.swift
//  SKCommon
//
//  Created by peilongfei on 2023/3/6.
//  


import UIKit
import SKResource
import UniverseDesignColor
import UniverseDesignCheckBox
import UniverseDesignIcon

class SearchSettingInfo {
    var mainStr: String
    var isSelect: Bool = false
    let chosenType: SearchEntity
    var preChosenType: SearchEntity
    var isGray: Bool = false
    var blockType: BlockOptions.BlockType?
    var tips: String
    init(mainStr: String,
         chosenType: SearchEntity,
         tips: String = "") {
        self.mainStr = mainStr
        self.chosenType = chosenType
        self.preChosenType = chosenType
        self.tips = tips
    }

    //更新置灰状态之类的
    func updateState(publicPermissionMeta: PublicPermissionMeta) {
        if let type = publicPermissionMeta.blockOptions?.searchEntity(with: chosenType.rawValue), type != .none {
            isGray = true
            blockType = type
        } else {
            isGray = false
            blockType = nil
        }
    }
}

class SearchSettingCell: SKGroupTableViewCell {
    static let reuseIdentifier = "SearchSettingCell"
    
    var tipsCallBack: (() -> Void)?
    
    private lazy var seprateLine: UIView = {
        let v = UIView()
        v.backgroundColor = UDColor.bgBody
        return v
    }()

    private lazy var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .single, config: .init(style: .circle)) { (_) in }
        checkBox.isUserInteractionEnabled = false
        return checkBox
    }()

    var isItemSelected: Bool = false {
        didSet {
            checkBox.isSelected = isItemSelected
        }
    }

    private var mainLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.ud.N900
        l.font = UIFont.systemFont(ofSize: 16)
        l.numberOfLines = 0
        return l
    }()
    
    private lazy var tipsButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.infoOutlined.ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        button.addTarget(self, action: #selector(clickTipsAction), for: .touchUpInside)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpCellUI()
    }

    private func setUpCellUI() {
        containerView.addSubview(checkBox)
        containerView.addSubview(mainLabel)
        containerView.addSubview(tipsButton)
        checkBox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(12)
            make.height.width.equalTo(18)
            make.centerY.equalToSuperview()
        }
        mainLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
            make.left.equalTo(checkBox.snp.right).offset(10)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        tipsButton.snp.makeConstraints { make in
            make.left.equalTo(mainLabel.snp.right).offset(8)
            make.height.width.equalTo(18)
            make.centerY.equalToSuperview()
        }
    }

    func config(info: SearchSettingInfo) {
        mainLabel.text = info.mainStr
        isItemSelected = info.isSelect
        mainLabel.textColor = info.isGray ? UIColor.ud.N400 : UIColor.ud.N900
        checkBox.isEnabled = !info.isGray
        tipsButton.isHidden = info.tips.isEmpty
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func clickTipsAction() {
        tipsCallBack?()
    }
}
