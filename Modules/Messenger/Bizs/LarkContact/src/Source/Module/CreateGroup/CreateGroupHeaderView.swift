//
//  CreateGroupHeaderView.swift
//  LarkContact
//
//  Created by 赵家琛 on 2021/1/5.
//

import UIKit
import Foundation
import SnapKit
import LarkFeatureGating
import LarkMessengerInterface
import LarkUIKit
import LarkSetting

final class CreateGroupHeaderView: UIView {
    static let topPadding: CGFloat = 30
    static let bottomPadding: CGFloat = 8
    static let viewHeight: CGFloat = {
        return GroupModeInfoView.viewHeight + topPadding + bottomPadding
    }()

    let groupModeInfoView: GroupModeInfoView

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkContact.Lark_NearbyGroup_SelectContacts
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    init(ability: CreateAbility, modeType: ModelType) {
        self.groupModeInfoView = GroupModeInfoView(ability: ability, modeType: modeType)
        super.init(frame: .zero)

        self.addSubview(groupModeInfoView)
        groupModeInfoView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(Self.bottomPadding)
            make.height.equalTo(GroupModeInfoView.viewHeight)
        }
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalTo(groupModeInfoView.snp.top).offset(-4)
        }
        self.lu.addBottomBorder()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CreateGroupHeaderSubView: UIView {
    private let highlightColor = UIColor.ud.fillHover
    private let normalColor = UIColor.ud.bgBody
    private lazy var highlightView: UIView = {
        let view = UIView()
        view.backgroundColor = normalColor
        view.layer.cornerRadius = 6.0
        return view
    }()

    var tappedFunc: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = normalColor
        self.addSubview(highlightView)
        self.sendSubviewToBack(highlightView)
        highlightView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(6.0)
            make.bottom.equalToSuperview().offset(-6.0)
            make.left.equalToSuperview().offset(6.0)
            make.right.equalToSuperview().offset(-6.0)
        }

        self.lu.addTopBorder()
        self.lu.addBottomBorder()
        self.lu.addTapGestureRecognizer(action: #selector(tapped), target: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func tapped() {
        self.tappedFunc?()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.highlightView.backgroundColor = highlightColor
        super.touchesBegan(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.highlightView.backgroundColor = normalColor
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.highlightView.backgroundColor = normalColor
        super.touchesCancelled(touches, with: event)
    }

}

final class GroupModeInfoView: CreateGroupHeaderSubView {
    private lazy var promatLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkContact.Lark_Group_CreateGroup_GroupType
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        return label
    }()

    private lazy var valuePromatImageView: UIImageView = {
        let imageView = UIImageView(image: Resources.dark_right_arrow)
        return imageView
    }()

    private let ability: CreateAbility
    static let viewHeight: CGFloat = 54

    init(ability: CreateAbility, modeType: ModelType) {
        self.ability = ability
        super.init(frame: .zero)

        setupUI()
        setProps(modeType: modeType)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setProps(modeType: ModelType) {
        let modelName: String
        switch modeType {
        case .chat:
            modelName = BundleI18n.LarkContact.Lark_Group_CreateGroup_Mode_Default_Name
        case .secret:
            modelName = BundleI18n.LarkContact.Lark_Group_CreateGroup_Mode_Secret_Name
        case .thread:
            modelName = BundleI18n.LarkContact.Lark_Group_CreateGroup_Mode_Topic_Name
        case .privateChat:
            modelName = BundleI18n.LarkContact.Lark_IM_EncryptedChat_Short
        }
        // 是否能够看到选择模式
        let showSelectModel = self.ability.contains(.secret) || self.ability.contains(.thread) || self.ability.contains(.privateChat)
        if showSelectModel {
            promatLabel.text = BundleI18n.LarkContact.Lark_Group_CreateGroup_Mode_Title
            valueLabel.text = modelName
        }
    }

    private func setupUI() {
        self.addSubview(promatLabel)
        self.addSubview(valueLabel)
        self.addSubview(valuePromatImageView)

        promatLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        valueLabel.snp.makeConstraints { (make) in
            make.trailing.equalTo(valuePromatImageView.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
        valuePromatImageView.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-21)
            make.centerY.equalToSuperview()
        }
    }
}

final class FaceToFaceGroupView: CreateGroupHeaderSubView {
    static let viewHeight: CGFloat = 54

    private lazy var brandImageView: UIImageView = {
        let imageView = UIImageView(image: Resources.createNearbyGroup)
        return imageView
    }()

    private lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView(image: Resources.dark_right_arrow)
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkContact.Lark_NearbyGroup_Title
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.addSubview(brandImageView)
        self.addSubview(titleLabel)
        self.addSubview(arrowImageView)

        brandImageView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(54)
        }
        arrowImageView.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-21)
            make.centerY.equalToSuperview()
        }
    }
}

final class CreateGroupFooterView: UIView {
    var viewHeight: CGFloat { FaceToFaceGroupView.viewHeight + 38 }

    var faceToFaceGroupView: FaceToFaceGroupView?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkContact.Lark_NearbyGroup_OtherWays
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    init() {
        super.init(frame: .zero)

        let faceToFaceGroupView = FaceToFaceGroupView()
        self.addSubview(faceToFaceGroupView)
        faceToFaceGroupView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(FaceToFaceGroupView.viewHeight)
        }
        self.faceToFaceGroupView = faceToFaceGroupView

        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalTo(faceToFaceGroupView.snp.top).offset(-4)
        }

        let topLineView = UIView()
        self.addSubview(topLineView)
        topLineView.backgroundColor = UIColor.ud.lineDividerDefault
        topLineView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
            make.bottom.equalTo(self.snp.top)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
