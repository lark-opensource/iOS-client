//
//  ChatAvatarLayoutSettingViewController.swift
//  LarkMine
//
//  Created by zc09v on 2021/7/13.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignCheckBox
import LarkStorage
import LarkSDKInterface
import UniverseDesignToast
import LarkContainer
import LarkSetting

private enum AvatarLayoutType {
    case left
    case leftRight
}

final class ChatAvatarLayoutSettingViewController: BaseUIViewController, OptionViewDelegate {
    private var hasLayout: Bool = false
    private let itemWidth: CGFloat = 128
    private let padding: CGFloat = 16.0
    private var optionViews: [OptionView] = []
    private var currentLayout: AvatarLayoutType?
    private var supportLeftRight: Bool {
        didSet {
            KVPublic.Setting.chatSupportAvatarLeftRight(fgService: try? userResolver.resolve(assert: FeatureGatingService.self)).setValue(supportLeftRight)
            NotificationCenter.default.post(name: NSNotification.Name("ChatSupportAvatarLeftRightChanged"), object: nil)
        }
    }

    private let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.supportLeftRight = KVPublic.Setting.chatSupportAvatarLeftRight(fgService: try? userResolver.resolve(assert: FeatureGatingService.self)).value()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !hasLayout {
            hasLayout = true
            let containerView = UIView(frame: .zero)
            containerView.backgroundColor = UIColor.ud.bgFloat
            self.view.addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(16)
                make.left.equalToSuperview().offset(padding)
                make.right.equalToSuperview().offset(-(padding))
            }
            containerView.layer.cornerRadius = 10
            let setLeftLayoutView: OptionView = OptionView(info: OptionInfo(image: Resources.chat_avatar_layout_left,
                                                                            content: BundleI18n.LarkMine.Lark_Settings_MessageAlignLeft,
                                                                            isSelected: !supportLeftRight,
                                                                            layoutType: .left),
                                                           itemWidth: itemWidth)
            setLeftLayoutView.delegate = self
            let setLeftAndRightLayoutView: OptionView = OptionView(info: OptionInfo(image: Resources.chat_avatar_layout_leftRight,
                                                                              content: BundleI18n.LarkMine.Lark_Settings_MessageAlignLeftAndRight,
                                                                              isSelected: supportLeftRight,
                                                                              layoutType: .leftRight),
                                                                   itemWidth: itemWidth)
            setLeftAndRightLayoutView.delegate = self
            containerView.addSubview(setLeftLayoutView)
            optionViews.append(setLeftLayoutView)
            optionViews.append(setLeftAndRightLayoutView)
            let spacing: CGFloat = (self.view.frame.width - 2 * padding - itemWidth * 2) / 3 // 要减去两边的padding
            setLeftLayoutView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(32)
                make.left.equalToSuperview().offset(spacing)
                make.bottom.equalToSuperview().offset(-28)
                make.width.equalTo(itemWidth)
            }
            containerView.addSubview(setLeftAndRightLayoutView)
            setLeftAndRightLayoutView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(32)
                make.right.equalToSuperview().offset(-spacing)
                make.bottom.equalToSuperview().offset(-28)
                make.width.equalTo(itemWidth)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkMine.Lark_Settings_MessageAlignment
        self.view.backgroundColor = UIColor.ud.bgFloatBase
    }

    fileprivate func clicked(info: OptionInfo) {
        if info.layoutType != currentLayout {
            currentLayout = info.layoutType
            for optionView in self.optionViews {
                optionView.set(selected: optionView.info.layoutType == info.layoutType)
                switch info.layoutType {
                case .left:
                    supportLeftRight = false
                case .leftRight:
                    supportLeftRight = true
                }
            }
            UDToast.showSuccess(with: BundleI18n.LarkMine.Lark_Legacy_SaveSuccess, on: self.view, delay: 0.5)
            MineTracker.trackChatAvatarLayout(leftLayout: !supportLeftRight)
        }
    }
}

private final class OptionInfo {
    let image: UIImage
    let content: String
    var isSelected: Bool
    var layoutType: AvatarLayoutType
    init(image: UIImage, content: String, isSelected: Bool, layoutType: AvatarLayoutType) {
        self.image = image
        self.content = content
        self.isSelected = isSelected
        self.layoutType = layoutType
    }
}

private protocol OptionViewDelegate: AnyObject {
    func clicked(info: OptionInfo)
}

private final class OptionView: UIView {
    let info: OptionInfo
    private let checkbox = UDCheckBox()
    weak var delegate: OptionViewDelegate?

    init(info: OptionInfo, itemWidth: CGFloat) {
        self.info = info
        super.init(frame: .zero)
        let imageView = UIImageView(frame: .zero)
        imageView.image = info.image
        self.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.width.equalTo(itemWidth)
            make.height.equalTo(268)
        }

        let label = UILabel(frame: .zero)
        label.text = info.content
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        self.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.width.equalTo(itemWidth)
        }

        checkbox.isUserInteractionEnabled = false
        checkbox.isSelected = info.isSelected

        self.addSubview(checkbox)
        checkbox.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.centerX.equalToSuperview()
            make.top.equalTo(label.snp.bottom).offset(8)
            make.bottom.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(viewClick))
        self.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(selected: Bool) {
        self.info.isSelected = selected
        self.checkbox.isSelected = selected
    }

    @objc
    private func viewClick() {
        self.delegate?.clicked(info: self.info)
    }
}
