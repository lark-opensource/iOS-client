////
////  SceneDetailIconCell.swift
////  LarkAI
////
////  Created by Zigeng on 2023/10/10.
////

import Foundation
import UIKit
import EENavigator
import LarkEmotion
import LarkInteraction
import UniverseDesignIcon
import UniverseDesignInput
import UniverseDesignShadow
import UniverseDesignActionPanel
import LarkNavigator
import LarkContainer
import ByteWebImage
import RustPB
import LarkImageEditor
import LarkVideoDirector
import LarkAssetsBrowser
import UniverseDesignToast

final class SceneDetailIconCell: UITableViewCell, SceneDetailCell {

    static let identifier: String = "SceneDetailIconCell"
    typealias VM = SceneDetailIconCellViewModel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none // 去掉点击高亮效果
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var tapAction: ((UIView) -> Void)?

    func setCell(vm: VM) {
        switch vm.image {
        case .passThrough(let passThrough):
            self.iconView.bt.setLarkImage(with: .default(key: passThrough.key ?? ""), placeholder: nil, passThrough: passThrough)
        case .uiimage(let image):
            self.iconView.bt.setImage(image)
        }
        self.tapAction = { sender in
            vm.cellVMDelegate?.showSelectActionSheet(sender: sender) { image in
                vm.image = .uiimage(image)
                vm.cellVMDelegate?.reloadCell(cellVM: vm)
            }
        }
    }

    private lazy var iconWrapper: UIButton = {
        let view = UIButton()
        return view
    }()

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        // 配置头像
        return imageView
    }()

    private lazy var editButtonWrapper = UIView()

    private lazy var iconEditButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.ud.bgFloat
        let icon = UDIcon.getIconByKey(.cameraFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.iconN2)
        button.setImage(icon, for: .normal)
        return button
    }()

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        contentView.addSubview(iconWrapper)
        iconWrapper.addSubview(iconView)
        contentView.addSubview(editButtonWrapper)
        editButtonWrapper.addSubview(iconEditButton)
    }

    private func setupConstraints() {
        iconWrapper.snp.makeConstraints { make in
            make.width.height.equalTo(72)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-3)
        }
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(72)
        }
        editButtonWrapper.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.bottom.equalTo(iconWrapper).offset(-1)
            make.trailing.equalTo(iconWrapper).offset(2)
        }
        iconEditButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupAppearance() {
        backgroundColor = .clear
        iconWrapper.backgroundColor = UIColor.ud.bgFloat
        iconWrapper.layer.cornerRadius = 36
        iconWrapper.layer.masksToBounds = true
        iconWrapper.addTarget(self, action: #selector(didTapIcon(_:)), for: .touchUpInside)
        iconEditButton.addTarget(self, action: #selector(didTapIcon(_:)), for: .touchUpInside)
        iconEditButton.backgroundColor = .ud.N300
        iconEditButton.layer.cornerRadius = 12
        iconEditButton.layer.masksToBounds = true
        iconEditButton.ud.setLayerBorderColor(.ud.bgFloatBase)

        iconEditButton.layer.borderWidth = 2
        if #available(iOS 13.4, *) {
            let iconAction = PointerInteraction(style: PointerStyle(effect: .lift))
            iconWrapper.addLKInteraction(iconAction)
        }
    }

    @objc
    private func didTapIcon(_ sender: UIButton) {
        tapAction?(sender)
    }
}
