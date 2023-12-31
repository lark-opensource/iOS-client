//
//  ChatThemeItemCell.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2022/12/21.
//

import Foundation
import UIKit
import SnapKit
import ServerPB
import LarkUIKit
import ByteWebImage
import UniverseDesignColor
import UniverseDesignTheme
import LarkMessengerInterface
import UniverseDesignCheckBox

struct ChatThemeItemCellModel {
    let reuseIdentify = NSStringFromClass(ChatThemeItemCell.self)

    var bgImageStyle: ChatBgImageStyle = .unknown
    var themeId: Int64?
    var scene: ChatThemeBody.Scene?
    var componentScene: ServerPB_Entities_ChatTheme.Scene = .defaultScene
    var desciption: String = ""
    var isSelected = false
    var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return UDThemeManager.getRealUserInterfaceStyle() == .dark
        } else {
            return false
        }
    }
}

// 聊天主题单个cell
final class ChatThemeItemCell: UICollectionViewCell {
    struct Config {
        static let descriptionLabelHeight: CGFloat = 20
        static let descriptionTopMargin: CGFloat = 4
    }

    var model: ChatThemeItemCellModel? {
        didSet {
            setCellInfo()
        }
    }

    private let imageViewContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        view.layer.borderWidth = 0
        view.clipsToBounds = true
        return view
    }()

    private let displayImageView: ByteImageView = {
        let imageView = ByteImageView()
        imageView.layer.cornerRadius = 8
        imageView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        imageView.layer.borderWidth = 0
        imageView.contentMode = .scaleAspectFill
        imageView.autoPlayAnimatedImage = false
        imageView.clipsToBounds = true
        return imageView
    }()

    private let shadowView: UIView = {
        let view = UIView()
        view.isHidden = true
        // 这里设置为0.7预览使用0.8主要是ux觉得在小视图下使用0.8看不清楚某些图片的内容
        view.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.7)
        return view
    }()

    private lazy var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .multiple, config: UDCheckBoxUIConfig(borderEnabledColor: UIColor.ud.colorfulBlue, style: .circle))
        checkBox.isSelected = true
        checkBox.isEnabled = true
        return checkBox
    }()

    // 用来显示描述
    private var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.height.equalTo(Self.Config.descriptionLabelHeight)
            make.centerX.bottom.equalToSuperview()
        }

        contentView.addSubview(imageViewContainer)
        imageViewContainer.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(descriptionLabel.snp.top).offset(-Self.Config.descriptionTopMargin)
        }
        contentView.addSubview(displayImageView)
        displayImageView.snp.makeConstraints { make in
            make.edges.equalTo(imageViewContainer).inset(UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2))
        }

        displayImageView.addSubview(shadowView)
        shadowView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.addSubview(checkBox)
        checkBox.snp.makeConstraints { make in
            make.top.equalTo(15)
            make.right.equalTo(-15)
            make.width.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.reloadUI()
    }

    private func reloadUI() {
        guard let model = model else { return }
        var bgColor: UIColor?
        switch model.bgImageStyle {
        case .image, .key:
            bgColor = .clear
            shadowView.isHidden = !model.isDarkMode
        case .color(let color):
            bgColor = color
            shadowView.isHidden = !model.isDarkMode
        case .defalut:
            shadowView.isHidden = true
            bgColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        case .unknown:
            break
        }
        displayImageView.backgroundColor = bgColor
    }

    func setCellInfo() {
        guard let model = model else { return }
        descriptionLabel.text = model.desciption
        checkBox.isHidden = !model.isSelected
        imageViewContainer.layer.borderWidth = model.isSelected ? 1 : 0
        displayImageView.layer.borderWidth = model.isSelected ? 0 : 0.5
        switch model.bgImageStyle {
        case .defalut:
            self.displayImageView.bt.setLarkImage(with: .default(key: ""))
        case .color(let color):
            self.displayImageView.bt.setLarkImage(with: .default(key: ""))
        case .image(let img):
            self.displayImageView.bt.setLarkImage(with: .default(key: ""),
                                                  placeholder: img)
        case .key(let identify, let fsUnit):
            var pass = ImagePassThrough()
            pass.key = identify
            pass.fsUnit = fsUnit
            self.displayImageView.bt.setLarkImage(with: .default(key: identify),
                                                  passThrough: pass)
        case .unknown:
            break
        }
        reloadUI()
    }
}
