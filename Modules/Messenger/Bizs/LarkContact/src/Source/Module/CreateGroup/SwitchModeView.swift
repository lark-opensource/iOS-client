//
//  SwitchModeView.swift
//  LarkContact
//
//  Created by 姚启灏 on 2019/2/27.
//

import UIKit
import Foundation
import LarkUIKit
import LarkButton
import LarkLocalizations
import LarkFeatureGating
import RxSwift
import RxCocoa
import LarkMessengerInterface

final class GroupModeView: UIControl {
    enum StatusStyle {
        case normal
        case selected
        case disable
    }

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = UIColor.ud.textPlaceholder
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        return titleLabel
    }()

    var style: StatusStyle = .normal {
        didSet {
            self.updateStyle(style)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(title: String) {
        super.init(frame: CGRect.zero)

        self.layer.cornerRadius = 17
        self.layer.masksToBounds = true

        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(34)
        }
        self.titleLabel.text = title
    }

    func updateStyle(_ style: StatusStyle) {
        switch style {
        case .normal:
            self.backgroundColor = UIColor.ud.N200
            self.titleLabel.textColor = UIColor.ud.N900
            self.titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        case .selected:
            self.backgroundColor = UIColor.ud.colorfulBlue
            self.titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill
            self.titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        case .disable:
            self.backgroundColor = UIColor.ud.N200
            self.titleLabel.textColor = UIColor.ud.N500
            self.titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        }
    }
}

protocol SwitchGroupModelViewDelegate: AnyObject {
    func shouldSelecteDriver(newModelType: ModelType) -> Driver<Bool>
}

final class DescriptionView: UIView {
    enum BackgroundType {
        case secret
        case thread
        case chat
        case privateChat
    }

    private var backgroundView: UIView?
    func switchBackground(type: BackgroundType) {
        backgroundView?.removeFromSuperview()

        switch type {
        case .secret:
            backgroundView = DescriptionSecretView()

        case .thread:
            backgroundView = DescriptionThreadView()

        case .chat:
            backgroundView = DescriptionChatView()

        case .privateChat:
            backgroundView = DescriptionPrivateChatView()
        }
        backgroundView.flatMap { self.addSubview($0) }
        self.layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView?.snp.makeConstraints { (make) in
            make.top.bottom.left.right.equalToSuperview()
        }
    }
}
final class SwitchModeView: UIView {
    weak var delegate: SwitchGroupModelViewDelegate?
    var hasPrivateModePermission: Bool = false {
        didSet {
            if hasPrivateModePermission != oldValue {
                setupModeButtons()
            }
        }
    }
    private let ability: CreateAbility
    private let disposeBag = DisposeBag()
    private(set) var value: ModelType = .chat {
        didSet {
            switch value {
            case .chat:
                chatModeView.style = .selected
                threadModeView.style = .normal
                screatModeView.style = .normal
                privateModeView.style = .normal
                descriptionView.switchBackground(type: .chat)
                descriptionLabel.text = BundleI18n.LarkContact.Lark_Group_CreateGroup_Mode_Default_Description
            case .thread:
                chatModeView.style = .normal
                threadModeView.style = .selected
                screatModeView.style = .normal
                privateModeView.style = .normal
                descriptionView.switchBackground(type: .thread)
                descriptionLabel.text = BundleI18n.LarkContact.Lark_Group_CreateGroup_Mode_Topic_Description
            case .secret:
                chatModeView.style = .normal
                threadModeView.style = .normal
                screatModeView.style = .selected
                privateModeView.style = .normal
                descriptionView.switchBackground(type: .secret)
                descriptionLabel.text = BundleI18n.LarkContact.Lark_Group_CreateGroup_Mode_Secret_Description
            case .privateChat:
                chatModeView.style = .normal
                threadModeView.style = .normal
                screatModeView.style = .normal
                privateModeView.style = .selected
                descriptionView.switchBackground(type: .privateChat)
                descriptionLabel.text = BundleI18n.LarkContact.Lark_IM_ExclusiveChatSample_FeatureDesc()
            }
        }
    }

    private lazy var chatModeView: GroupModeView = {
        let chatModeView = GroupModeView(title: BundleI18n.LarkContact.Lark_Group_CreateGroup_Mode_Default_Name)
        chatModeView.addTarget(self, action: #selector(tapModeView), for: .touchUpInside)
        return chatModeView
    }()

    private lazy var threadModeView: GroupModeView = {
        let threadModeView = GroupModeView(title: BundleI18n.LarkContact.Lark_Group_CreateGroup_Mode_Topic_Name)
        threadModeView.addTarget(self, action: #selector(tapModeView), for: .touchUpInside)
        return threadModeView
    }()

    private lazy var screatModeView: GroupModeView = {
        let screatModeView = GroupModeView(title: BundleI18n.LarkContact.Lark_Group_CreateGroup_Mode_Secret_Name)
        screatModeView.addTarget(self, action: #selector(tapModeView), for: .touchUpInside)
        return screatModeView
    }()

    private lazy var privateModeView: GroupModeView = {
        let privateModeView = GroupModeView(title: BundleI18n.LarkContact.Lark_IM_EncryptedChat_Short)
        privateModeView.addTarget(self, action: #selector(tapModeView), for: .touchUpInside)
        return privateModeView
    }()

    private lazy var descriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.textColor = UIColor.ud.textPlaceholder
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.numberOfLines = 0
        return descriptionLabel
    }()

    private lazy var descriptionView = DescriptionView()

    private lazy var modeButtonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        return stackView
    }()

    // MARK: - lifeCycle
    init(
        modeType: ModelType,
        ability: CreateAbility
    ) {
        self.ability = ability
        super.init(frame: .zero)
        layoutView()
        defaultModelType(modeType)
    }

    // 在init()方法中使用，确保didset执行。
    func defaultModelType(_ modeType: ModelType) {
       self.value = modeType
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupModeButtons() {
        modeButtonsStackView.arrangedSubviews.forEach {
            modeButtonsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        modeButtonsStackView.addArrangedSubview(chatModeView)
        if self.ability.contains(.thread) {
            modeButtonsStackView.addArrangedSubview(threadModeView)
        }
        if self.ability.contains(.secret) {
            modeButtonsStackView.addArrangedSubview(screatModeView)
        }
        if self.ability.contains(.privateChat) && hasPrivateModePermission {
            modeButtonsStackView.addArrangedSubview(privateModeView)
        }
        changeModeButtonsStackView()
    }

    // MARK: - private methods
    private func layoutView() {
        self.backgroundColor = UIColor.ud.bgBody
        self.addSubview(modeButtonsStackView)
        self.addSubview(descriptionLabel)
        self.addSubview(descriptionView)
        self.lu.addTopBorder()

        modeButtonsStackView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(34)
        }
        setupModeButtons()

        descriptionView.frame = CGRect(x: 0, y: 0, width: 375.0, height: 667)
        descriptionView.layer.shadowColor = UIColor.ud.rgba(0x1F1F2329).cgColor
        descriptionView.layer.shadowOpacity = 1
        descriptionView.layer.shadowRadius = 20
        descriptionView.layer.shadowOffset = CGSize(width: 0, height: 10)

        let wrapperView = UIView()
        self.addSubview(wrapperView)
        wrapperView.backgroundColor = UIColor.ud.bgBody
        wrapperView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        let lineColor = UIColor.ud.bgBody
        let gradientView = GradientView()
        gradientView.backgroundColor = UIColor.clear
        gradientView.colors = [lineColor.withAlphaComponent(0), lineColor.withAlphaComponent(1)]
        gradientView.locations = [0.0, 0.5]
        gradientView.direction = .vertical

        self.addSubview(gradientView)
        gradientView.snp.makeConstraints { (make) in
            make.bottom.equalTo(wrapperView.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(80)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let scale = (self.frame.width - 62 * 2) / 375
        descriptionView.transform = CGAffineTransform(scaleX: scale, y: scale)
        descriptionView.frame = CGRect(x: descriptionView.frame.origin.x, y: descriptionLabel.frame.bottom + 24, width: descriptionView.frame.width, height: descriptionView.frame.height)
        descriptionView.center = CGPoint(x: self.frame.width / 2, y: descriptionView.center.y)
    }

    // MARK: methods
    private func onlyShowChatModeButton() -> Bool {
        guard self.modeButtonsStackView.subviews.filter({ $0.isHidden == false }).count == 1 else { return false }
        guard let view = self.modeButtonsStackView.subviews.first(where: { $0.isHidden == false }) else { return false }

        return view == self.chatModeView
    }

    // 如果当前只展示了对话一个可选的按钮，就隐藏整个按钮选择区域
    private func changeModeButtonsStackView() {
        // 是否应该隐藏StackView
        let needHiddenStackView: Bool = self.onlyShowChatModeButton()
        modeButtonsStackView.isHidden = needHiddenStackView

        if needHiddenStackView {
            descriptionLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(16)
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().offset(-16)
            }
        } else {
            descriptionLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(modeButtonsStackView.snp.bottom).offset(8)
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().offset(-16)
            }
        }
    }

    @objc
    private func tapModeView(_ view: GroupModeView) {
        let newValue: ModelType
        switch view {
        case chatModeView:
            Tracer.trackGoupTypeModeClassic()
            newValue = .chat
        case threadModeView:
            Tracer.trackGoupTypeModeTopic()
            newValue = .thread
        case screatModeView:
            newValue = .secret
        case privateModeView:
            newValue = .privateChat
        default:
            newValue = .chat
        }

        self.delegate?
            .shouldSelecteDriver(newModelType: newValue)
            .drive(onNext: { [weak self] shouldSelect in
                guard let self = self else { return }
                guard shouldSelect else { return }

                self.value = newValue
            }).disposed(by: self.disposeBag)
    }
}
