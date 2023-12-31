////
////  SceneDetailAddTextCell.swift
////  LarkAI
////
////  Created by Zigeng on 2023/10/10.
////

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignInput
import UniverseDesignColor
import LarkFeatureGating

class SceneDetailAddTextCell: UITableViewCell, SceneDetailCell {
    static let identifier: String = "SceneDetailAddTextCell"
    typealias VM = SceneDetailAddTextCellViewModel

    private lazy var titleView: UILabel = {
        let view = UILabel()
        view.textColor = .ud.primaryContentDefault
        return view
    }()

    private lazy var addButton: UIImageView = {
        let view = UIImageView()
//        view.setImage(UDIcon.addOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        view.image = UDIcon.addOutlined.withRenderingMode(.alwaysTemplate)
        return view
    }()

    @objc
    func addButtonTapped() {
        tapAction?()
    }

    var tapAction: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none // 去掉点击高亮效果
        let container = UIView()
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.height.equalTo(46)
            make.center.equalToSuperview()
        }
        container.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
            make.width.height.equalTo(16)
        }
        container.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
            make.left.equalTo(addButton.snp.right).offset(4)
            make.right.equalToSuperview()
        }
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addButtonTapped)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCell(vm: VM) {
        titleView.text = vm.title
        tapAction = vm.cellTapAction
        titleView.textColor = .ud.primaryContentDefault
        addButton.tintColor = .ud.primaryContentDefault
    }
}
