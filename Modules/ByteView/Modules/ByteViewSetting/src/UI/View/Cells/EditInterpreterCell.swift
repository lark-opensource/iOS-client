//
//  EditInterpreterCell.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/5.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI

extension SettingCellType {
    static let editInterpreterCell = SettingCellType("editInterpreterCell", cellType: EditInterpreterCell.self)
}

extension SettingSectionBuilder {
    @discardableResult
    func editInterpreterCell(channel: InterpretationChannelInfo, delegate: EditInterpreterCellDelegate) -> Self {
        let data: [String: Any] = ["editInterpreterViewModel": EditInterpreterViewModel(channel: channel, delegate: delegate)]
        return row(.editInterpreter, reuseIdentifier: .editInterpreterCell, title: "", data: data)
    }
}

struct InterpretationChannelInfo: Equatable {
    var user: ByteviewUser
    var interpreterSetting: InterpreterSetting?
    var index: Int = 0
    // 用于标记即将被移除的interpreter
    var willBeRemoved: Bool = false
    /// 入会状态，默认已入会
    var joined: Bool = true

    init(index: Int, interpreter: SetInterpreter) {
        self.index = index
        self.user = interpreter.user
        self.interpreterSetting = interpreter.interpreterSetting
    }
}

protocol EditInterpreterCellDelegate: AnyObject {
    var service: UserSettingManager { get }
    var hostViewController: UIViewController? { get }
    var selectedInterpreters: [SetInterpreter] { get }
    var supportedInterpretationLanguage: [InterpreterSetting.LanguageType] { get }

    func canEditInterpreter(_ channel: InterpretationChannelInfo) -> Bool
    func didRemoveInterpreter(_ channel: InterpretationChannelInfo)
    func didModifyInterperter(_ channel: InterpretationChannelInfo, action: (inout SetInterpreter) -> Void)
}

final class EditInterpreterCell: BaseSettingCell {
    private struct Layout {
        static let commonSpacing: CGFloat = 16
        static let defaultInterpreterTitleColor: UIColor = UIColor.ud.textPlaceholder
        static let defaultLanguageTitleColor: UIColor = UIColor.ud.textPlaceholder
        static let rightIcon: UIImage? = UDIcon.getIconByKey(.downOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16, height: 16))
    }

    lazy var closeView: UIView = {
        let icon = UDIcon.getIconByKey(.closeBoldOutlined, iconColor: .ud.iconN3, size: CGSize(width: 12, height: 12))
        let img = UIImageView(image: icon)
        let view = UIView()
        view.addSubview(img)
        img.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(12)
        }
        return view
    }()


    private lazy var interpreterView = SelectInterpreterButton()
    private lazy var firstLanguageView = SelectLanguageButton()
    private lazy var secondLanguageView = SelectLanguageButton()

    override func setupViews() {
        super.setupViews()

        self.selectionStyle = .none
        self.backgroundView?.backgroundColor = .ud.bgFloat
        self.contentView.addSubview(interpreterView)
        self.contentView.addSubview(firstLanguageView)
        self.contentView.addSubview(secondLanguageView)
        self.contentView.addSubview(closeView)

        interpreterView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(12)
            maker.left.equalToSuperview().inset(16)
            maker.right.equalTo(closeView.snp.left)
            maker.height.equalTo(38)
        }

        firstLanguageView.snp.makeConstraints { (maker) in
            maker.top.equalTo(interpreterView.snp.bottom).offset(8)
            maker.left.equalTo(interpreterView)
            maker.height.equalTo(38)
            maker.bottom.equalToSuperview().offset(-12)
        }

        secondLanguageView.snp.makeConstraints { (maker) in
            maker.top.width.height.equalTo(firstLanguageView)
            maker.right.equalTo(interpreterView)
            maker.left.equalTo(firstLanguageView.snp.right).offset(8)
        }

        closeView.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.right.centerY.equalToSuperview()
        }

        let gesture = UITapGestureRecognizer(target: self, action: #selector(didClickRemove))
        closeView.addGestureRecognizer(gesture)
        interpreterView.addTarget(self, action: #selector(didClickSelectUser), for: .touchUpInside)
        firstLanguageView.addTarget(self, action: #selector(didClickSelectFirstLanguage), for: .touchUpInside)
        secondLanguageView.addTarget(self, action: #selector(didClickSelectSecondLanguage), for: .touchUpInside)
    }

    private var viewModel: EditInterpreterViewModel? { row?.data["editInterpreterViewModel"] as? EditInterpreterViewModel }

    override func config(for row: SettingDisplayRow, indexPath: IndexPath) {
        super.config(for: row, indexPath: indexPath)
        guard let viewModel = self.viewModel, let delegate = viewModel.delegate else { return }
        let channel = viewModel.channel
        let httpClient = delegate.service.httpClient
        interpreterView.config(SelectInterpreterInfo(user: channel.user, joined: channel.joined), httpClient: httpClient)
        firstLanguageView.config(channel.interpreterSetting?.firstLanguage, httpClient: httpClient)
        secondLanguageView.config(channel.interpreterSetting?.secondLanguage, httpClient: httpClient)
    }

    @objc private func didClickRemove() {
        guard let viewModel = self.viewModel, viewModel.canEditInterpreter() else { return }
        viewModel.removeInterpreter()
    }

    @objc private func didClickSelectUser() {
        guard let viewModel = self.viewModel, viewModel.canEditInterpreter() else { return }
        viewModel.selectInterpreter()
    }

    @objc private func didClickSelectFirstLanguage() {
        guard let viewModel = self.viewModel, viewModel.canEditInterpreter() else { return }
        viewModel.selectLanguage(isFirstLanguage: true)
    }

    @objc private func didClickSelectSecondLanguage() {
        guard let viewModel = self.viewModel, viewModel.canEditInterpreter() else { return }
        viewModel.selectLanguage(isFirstLanguage: false)
    }
}

final class EditInterpreterViewModel {
    let channel: InterpretationChannelInfo
    weak var delegate: EditInterpreterCellDelegate?

    init(channel: InterpretationChannelInfo, delegate: EditInterpreterCellDelegate?) {
        self.channel = channel
        self.delegate = delegate
    }

    func canEditInterpreter() -> Bool {
        if let delegate = delegate, delegate.canEditInterpreter(channel) {
            return true
        } else {
            return false
        }
    }

    func removeInterpreter() {
        delegate?.didRemoveInterpreter(channel)
    }

    func selectInterpreter() {
        guard let delegate = self.delegate else { return }
        let selectedIds = delegate.selectedInterpreters.map { $0.user.id }.filter { !$0.isEmpty }
        let vc = CalendarInterpreterSettingsVC(service: delegate.service, selectedIds: selectedIds) { [weak self] id in
            guard let self = self else { return }
            self.delegate?.didModifyInterperter(self.channel, action: { $0.user = ByteviewUser(id: id, type: .larkUser) })
        }
        delegate.hostViewController?.presentDynamicModal(vc, config: DynamicModalConfig(presentationStyle: .formSheet, needNavigation: true))
    }

    func selectLanguage(isFirstLanguage: Bool) {
        guard let delegate = self.delegate else { return }
        let lang = isFirstLanguage ? channel.interpreterSetting?.secondLanguage : channel.interpreterSetting?.firstLanguage
        let vc = InterpreterLanguageViewController(i18nService: delegate.service.httpClient.i18n, supportInterpretationLanguage: delegate.supportedInterpretationLanguage, selectedLanguage: lang) { [weak self] selectedLang in
            guard let self = self else { return }
            if isFirstLanguage {
                self.delegate?.didModifyInterperter(self.channel, action: { $0.interpreterSetting?.firstLanguage = selectedLang })
            } else {
                self.delegate?.didModifyInterperter(self.channel, action: { $0.interpreterSetting?.secondLanguage = selectedLang })
            }
        }
        let nav = NavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        delegate.hostViewController?.present(nav, animated: true)
    }
}

private class EditInterpreterButton: UIButton {
    let placeholderLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = 8.0
        layer.masksToBounds = true
        self.vc.setBackgroundColor(.ud.bgFloatOverlay, for: .normal)
        self.vc.setBackgroundColor(.ud.fillPressed, for: .highlighted)

        addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        placeholderLabel.textColor = .ud.textPlaceholder
        placeholderLabel.font = VCFontConfig.r_16_24.font
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {}
}

private class SelectInterpreterButton: EditInterpreterButton {
    lazy var avatarView = AvatarView()
    lazy var nameLabel = UILabel()
    lazy var joinStateLabel = UILabel()

    override func setupSubviews() {
        super.setupSubviews()
        addSubview(avatarView)
        addSubview(nameLabel)
        addSubview(joinStateLabel)

        avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(6)
            make.centerY.equalToSuperview()
        }
        joinStateLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel.snp.right)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().inset(12)
        }

        joinStateLabel.setContentHuggingPriority(.required, for: .horizontal)
        joinStateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        joinStateLabel.font = VCFontConfig.h4.font
        joinStateLabel.textColor = .ud.textPlaceholder
        nameLabel.font = VCFontConfig.h4.font
        nameLabel.textColor = .ud.textTitle
        placeholderLabel.text = I18n.View_G_AddInterpreter
    }

    private var selectedInfo: SelectInterpreterInfo?
    func config(_ info: SelectInterpreterInfo, httpClient: HttpClient) {
        self.selectedInfo = info
        if let user = info.user, !user.id.isEmpty {
            placeholderLabel.isHidden = true
            joinStateLabel.text = info.joined ? "" : I18n.View_G_NotJoined_StatusGrey
            joinStateLabel.isHidden = false

            avatarView.setAvatarInfo(.asset(nil))
            nameLabel.text = ""
            avatarView.isHidden = false
            nameLabel.isHidden = false
            httpClient.participantService.participantInfo(pid: user, meetingId: info.meetingId) { [weak self] userInfo in
                if let self = self, self.selectedInfo?.user == user {
                    Util.runInMainThread {
                        self.avatarView.setAvatarInfo(userInfo.avatarInfo)
                        self.nameLabel.text = userInfo.name
                    }
                }
            }
        } else {
            placeholderLabel.isHidden = false
            nameLabel.isHidden = true
            avatarView.isHidden = true
            joinStateLabel.isHidden = true
        }
    }
}

private struct SelectInterpreterInfo {
    let user: ByteviewUser?
    var joined: Bool = true
    var meetingId: String?
}

private class SelectLanguageButton: EditInterpreterButton {
    lazy var iconView = UIImageView()
    lazy var nameLabel = UILabel()

    override func setupSubviews() {
        super.setupSubviews()
        addSubview(iconView)
        addSubview(nameLabel)
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(12)
        }

        nameLabel.font = VCFontConfig.r_16_24.font
        nameLabel.textColor = .ud.textTitle
        placeholderLabel.text = I18n.View_G_Language
    }

    private var selectedLanguage: InterpreterSetting.LanguageType?
    func config(_ language: InterpreterSetting.LanguageType?, httpClient: HttpClient) {
        self.selectedLanguage = language
        if let language = language, !language.languageType.isEmpty {
            iconView.image = LanguageIconManager.get(by: language)
            nameLabel.text = ""
            httpClient.i18n.get(language.despI18NKey) { [weak self] result in
                Util.runInMainThread {
                    guard let self = self, self.selectedLanguage?.languageType == language.languageType,
                          case .success(let text) = result else { return }
                    self.nameLabel.text = text
                }
            }
            self.placeholderLabel.isHidden = true
            self.iconView.isHidden = false
            self.nameLabel.isHidden = false
        } else {
            self.placeholderLabel.isHidden = false
            self.iconView.isHidden = true
            self.nameLabel.isHidden = true
        }
    }
}
