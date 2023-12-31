//
//  LinkEditChoiceCell.swift
//  SpaceKit
//
//  Created by liweiye on 2020/4/9.
//

import Foundation
import UIKit
import SKResource
import UniverseDesignColor
import UniverseDesignCheckBox

enum EditLinkInfoCellType {
    case checkBox
    case password
}

protocol EditLinkInfoProtocol {
    var type: EditLinkInfoCellType { get }
}

class EditLinkInfo {
    var mainStr: String
    var isSelect: Bool = false
    let chosenType: ShareLinkChoice
    var isGray: Bool = false
    var blockType: BlockOptions.BlockType?
    init(mainStr: String,
         chosenType: ShareLinkChoice) {
        self.mainStr = mainStr
        self.chosenType = chosenType
    }

    //更新置灰状态之类的
    func updateState(publicPermissionMeta: PublicPermissionMeta) {
        if let type = publicPermissionMeta.blockOptions?.linkShareEntity(with: chosenType.rawValue + 1), type != .none {
            isGray = true
            blockType = type
        } else if chosenType == .partnerRead || chosenType == .partnerEdit,
                // admin 不是关联组织共享，但仍出现这个选项，说明是从关联组织切换到对外共享的场景，后续 blockType 会被忽略
                publicPermissionMeta.adminExternalAccess != .partnerTenant || !publicPermissionMeta.partnerTenantAccessEnable {
            // 部分场景没有返回 block_options, 但仍要置灰, 这里暂时额外处理一下
            isGray = true
            blockType = .currentLimit
        } else {
            isGray = false
            blockType = nil
        }
    }
}

extension EditLinkInfo: EditLinkInfoProtocol {
    var type: EditLinkInfoCellType {
        return .checkBox
    }
}

class LinkEditChoiceCell: SKGroupTableViewCell {
    static let reuseIdentifier = "LinkEditChoiceCell"
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpCellUI()
    }

    private func setUpCellUI() {
        containerView.addSubview(checkBox)
        containerView.addSubview(mainLabel)
        checkBox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(12)
            make.height.width.equalTo(18)
            make.centerY.equalToSuperview()
        }
        mainLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
            make.left.equalTo(checkBox.snp.right).offset(10)
            make.right.equalToSuperview().offset(-16)
        }
    }

    func config(info: EditLinkInfo) {
        mainLabel.text = info.mainStr
        isItemSelected = info.isSelect
        mainLabel.textColor = info.isGray ? UIColor.ud.N400 : UIColor.ud.N900
        checkBox.isEnabled = !info.isGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
