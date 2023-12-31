//
//  SceneListTableViewCell.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/7.
//

import Foundation
import UIKit
import LarkExtensions // hitTestEdgeInsets
import UniverseDesignColor // UIColor.ud.
import UniverseDesignIcon // UDIcon.
import LarkTag // LarkTag
import ServerPB // ServerPB_Office_ai_MyAIScene
import ByteWebImage // bt.
import RustPB // Basic_V1_ImageSetPassThrough

protocol SceneListCellDelegate: AnyObject {
    /// 点击了more
    func didClickMore(button: UIButton, scene: ServerPB_Office_ai_MyAIScene)
}

final class SceneListTableViewCell: UITableViewCell {
    /// 具有左、右、下边距，子视图应该添加到这里
    private lazy var cellContentView = UIView()
    /// icon
    private lazy var iconView = UIImageView()
    /// title
    private lazy var titleLabel = UILabel()
    /// tag
    private lazy var tagView = TagWrapperView()
    /// more
    private lazy var moreButton = UIButton()
    /// detail
    private lazy var detailLabel = UILabel()

    /// delegate
    weak var delegate: SceneListCellDelegate?
    private var scene: ServerPB_Office_ai_MyAIScene = ServerPB_Office_ai_MyAIScene()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // 背景透明，除选中态的背景色
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        self.contentView.backgroundColor = UIColor.clear
        // 配置cellContentView
        do {
            self.cellContentView.backgroundColor = UIColor.ud.bgBody
            self.cellContentView.layer.cornerRadius = 10
            self.cellContentView.layer.masksToBounds = true
            self.contentView.addSubview(self.cellContentView)
            self.cellContentView.snp.makeConstraints { make in
                make.top.equalTo(self.contentView)
                make.height.equalTo(98)
                make.left.equalTo(self.contentView).offset(16)
                make.right.equalTo(self.contentView).offset(-16)
            }
        }
        // 添加icon
        do {
            self.iconView.layer.masksToBounds = true
            self.iconView.layer.cornerRadius = 14
            self.iconView.backgroundColor = UIColor.ud.N100
            self.cellContentView.addSubview(self.iconView)
            self.iconView.snp.makeConstraints { make in
                make.left.equalTo(self.cellContentView).offset(16)
                make.top.equalTo(self.cellContentView).offset(12)
                make.width.height.equalTo(28)
            }
        }
        // 添加...
        do {
            self.moreButton.hitTestEdgeInsets = .init(top: -12, left: -12, bottom: -12, right: -12)
            self.moreButton.addTarget(self, action: #selector(self.didClickMore(button:)), for: .touchUpInside)
            self.moreButton.setImage(UDIcon.moreOutlined, for: .normal)
            self.cellContentView.addSubview(self.moreButton)
            self.moreButton.snp.makeConstraints { make in
                make.width.height.equalTo(20)
                make.right.equalTo(self.cellContentView).offset(-18)
                make.centerY.equalTo(self.iconView)
            }
        }
        // 添加title
        do {
            self.titleLabel.font = UIFont.systemFont(ofSize: 16)
            self.titleLabel.textColor = UIColor.ud.textTitle
            self.cellContentView.addSubview(self.titleLabel)
        }
        // 添加tag
        do {
            self.cellContentView.addSubview(self.tagView)
        }
        // 添加detail
        do {
            self.detailLabel.numberOfLines = 2
            self.cellContentView.addSubview(self.detailLabel)
            self.detailLabel.snp.makeConstraints { make in
                make.left.equalTo(self.cellContentView).offset(16)
                make.right.equalTo(self.cellContentView).offset(-16)
                make.top.equalTo(self.cellContentView).offset(46)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configScene(scene: ServerPB_Office_ai_MyAIScene) {
        self.scene = scene
        // 配置头像
        self.iconView.bt.setLarkImage(
            with: .default(key: scene.scenePhoto.key),
            placeholder: nil, // 不需要占位图，错误时背景色代替
            passThrough: ImagePassThrough.transform(passthrough: scene.scenePhoto)
        )
        // 配置title
        self.titleLabel.text = scene.sceneName
        // 配置detail
        let paragraphStyle = NSMutableParagraphStyle(); paragraphStyle.minimumLineHeight = 20; paragraphStyle.lineSpacing = 0; paragraphStyle.lineBreakMode = .byTruncatingTail
        let detailAttributedString = NSMutableAttributedString(
            string: scene.description_p,
            attributes: [.paragraphStyle: paragraphStyle, .foregroundColor: UIColor.ud.textPlaceholder, .font: UIFont.systemFont(ofSize: 14)]
        )
        self.detailLabel.attributedText = detailAttributedString
        // 配置tag
        var sceneTags: [Tag] = []
        if !scene.isOfficial {
            sceneTags.append(Tag(title: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_UserContributed_Label,
                                 style: Style(textColor: UIColor.ud.textTitle,
                                              backColor: UIColor.ud.udtokenTagNeutralBgNormal),
                                 type: .customTitleTag))
        }
        if scene.status == .stop {
            sceneTags.append(Tag(title: BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Suspended_Label,
                                 style: Style(textColor: UIColor.ud.udtokenTagTextOrange,
                                              backColor: UIColor.ud.udtokenTagBgOrange),
                                 type: .customTitleTag))
        }
        self.tagView.set(tags: sceneTags)

        // tag是否隐藏
        self.tagView.isHidden = sceneTags.isEmpty
        // more是否隐藏，官方预制场景不支持操作
        self.moreButton.isHidden = scene.isPreset
        // 调整title、tag的布局
        if sceneTags.isEmpty {
            self.titleLabel.snp.remakeConstraints { make in
                make.left.equalTo(self.cellContentView).offset(52)
                make.right.lessThanOrEqualTo(self.cellContentView).offset(-46)
                make.centerY.equalTo(self.iconView)
            }
            self.tagView.snp.removeConstraints()
        } else {
            self.titleLabel.snp.remakeConstraints { make in
                make.left.equalTo(self.cellContentView).offset(52)
                make.centerY.equalTo(self.iconView)
            }
            self.tagView.snp.remakeConstraints { make in
                make.right.lessThanOrEqualTo(self.cellContentView).offset(-46)
                make.left.equalTo(self.titleLabel.snp.right).offset(8)
                make.height.equalTo(18)
                make.centerY.equalTo(self.iconView)
            }
        }

        // 如果当前场景被禁用，则头像、title、detail的样式需要调整
        self.iconView.alpha = scene.status == .stop ? 0.5 : 1
        self.titleLabel.alpha = scene.status == .stop ? 0.5 : 1
        self.detailLabel.alpha = scene.status == .stop ? 0.5 : 1
    }

    @objc
    private func didClickMore(button: UIButton) {
        self.delegate?.didClickMore(button: button, scene: self.scene)
    }
}
