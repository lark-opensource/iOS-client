//
//  LanguagePickerViewController.swift
//  LarkChatSetting
//
//  Created by bytedance on 3/23/22.
//

import Foundation
import LarkUIKit
import LarkSetting
import RxSwift
import LarkSDKInterface
import LarkContainer
import UniverseDesignColor
import UniverseDesignIcon
import UIKit
import LarkModel
import LarkCore
import UniverseDesignToast
import LarkMessengerInterface

final class LanguagePickerViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy private var chatAPI: ChatAPI?

    let chatId: String
    var closeRealTimeTranslateCallBack: ((Chat) -> Void)?
    var targetLanguageChangeCallBack: ((Chat) -> Void)?

    private let disposeBag = DisposeBag()
    /// 数据源，里面只存了语言key
    private var dataSource: [String] = []

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(LanguagePickTableViewCell.self, forCellReuseIdentifier: LanguagePickTableViewCell.lu.reuseIdentifier)
        tableView.backgroundColor = .ud.bgBody
        return tableView
    }()

    private let chatFromWhere: ChatFromWhere

    lazy var closeTranslateView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.bgBody
        let button = UIButton()
        button.setTitleColor(.ud.textTitle, for: .normal)
        button.setTitle(BundleI18n.LarkMessageCore.Lark_IM_TranslationAsYouType_Disable_Option, for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = .systemFont(ofSize: 16)
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(52)
        }
        button.addTarget(self, action: #selector(closeTranslte), for: .touchUpInside)
        return view
    }()

    var selectedKey: String

    let userResolver: UserResolver
    init(userResolver: UserResolver, chatId: String, currentTargetLanguage: String, chatFromWhere: ChatFromWhere) {
        self.userResolver = userResolver
        self.chatId = chatId
        self.selectedKey = currentTargetLanguage.uppercased()
        self.chatFromWhere = chatFromWhere
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkMessageCore.Lark_IM_TranslationAsYouType_TranslateInto_LanguageSelection_Title
        addCloseItem()
        view.backgroundColor = .ud.bgBase
        view.addSubview(closeTranslateView)
        closeTranslateView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(52 + view.safeAreaInsets.bottom)
            make.bottom.equalToSuperview()
        }
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(closeTranslateView.snp.top).offset(-8)
        }
        setTranslateLanguageSettingDriver()
    }

    override func viewSafeAreaInsetsDidChange() {
        closeTranslateView.snp.updateConstraints { make in
            make.height.equalTo(52 + view.safeAreaInsets.bottom)
        }
    }

    @objc
    private func closeTranslte() {
        chatAPI?.updateChat(chatId: self.chatId, isRealTimeTranslate: false, realTimeTranslateLanguage: selectedKey)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chat in
                IMTracker.Chat.Main.Click.closeTranslation(chat, self?.chatFromWhere.rawValue, location: .input_box_view)
                self?.closeRealTimeTranslateCallBack?(chat)
                self?.dismiss(animated: true)
            }, onError: { [weak self](error) in
                // 把服务器返回的错误显示出来
                let showMessage = BundleI18n.LarkMessageCore.Lark_Setting_PrivacySetupFailed
                if let view = self?.viewIfLoaded {
                    UDToast.showFailure(with: showMessage, on: view, error: error)
                }
            }).disposed(by: self.disposeBag)
    }
    /// 实时获取最新的数据
    private func setTranslateLanguageSettingDriver() {
        self.userGeneralSettings?.translateLanguageSettingDriver
            .drive(onNext: { [weak self] (setting) in
                guard let `self` = self else { return }
                /// 重新构造数据源
                var tempDataSource: [String] = []
                setting.languageKeys.forEach({ languageKey in
                    guard setting.supportedLanguages.keys.contains(languageKey) else { return }
                    tempDataSource.append(languageKey)
                })
                self.dataSource = tempDataSource

                self.tableView.reloadData()
            }).disposed(by: self.disposeBag)
    }

    // MARK: - UITableViewDelegate & UITableViewDataSource

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let count = self.dataSource.count
        guard indexPath.row < count else {
            return UITableViewCell()
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LanguagePickTableViewCell.lu.reuseIdentifier) as? LanguagePickTableViewCell else {
            return UITableViewCell()
        }
        let languageKey: String = self.dataSource[indexPath.row]
        let languageName: String = self.userGeneralSettings?.translateLanguageSetting.getTrgLanguageI18nStringFor(languageKey) ?? ""
        cell.languageKey = languageKey
        cell.languageName = languageName
        cell.isUserSelected = languageKey.uppercased() == self.selectedKey
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let languageKey: String = self.dataSource[indexPath.row]
        if self.selectedKey == languageKey.uppercased() {
            return
        }
        self.selectedKey = languageKey.uppercased()
        self.tableView.reloadData()
        chatAPI?.updateChat(chatId: self.chatId, isRealTimeTranslate: true, realTimeTranslateLanguage: languageKey)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chat in
                self?.targetLanguageChangeCallBack?(chat)
                self?.dismiss(animated: true)
            }, onError: { [weak self] (error) in
                /// 把服务器返回的错误显示出来
                let showMessage = BundleI18n.LarkMessageCore.Lark_Setting_PrivacySetupFailed
                if let view = self?.viewIfLoaded {
                    UDToast.showFailure(with: showMessage, on: view, error: error)
                }
            }).disposed(by: self.disposeBag)
    }
}

final class LanguagePickTableViewCell: UITableViewCell {
    //2个字母的语言缩写，如Ch、En
    var languageKey: String = "" {
        didSet {
            languageKeyLabel.text = languageKey
        }
    }
    //语言的i18n文案，如简体中文、英语
    var languageName: String = "" {
        didSet {
            languageNameLabel.text = languageName
        }
    }
    var isUserSelected: Bool = false {
        didSet {
            rightImage.isHidden = !isUserSelected
        }
    }
    private lazy var languageKeyLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.textTitle
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    private lazy var languageKeyBorderView: UIView = {
        let view = UIView()
        view.layer.ud.setBorderColor(.ud.lineBorderComponent)
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 6
        view.backgroundColor = .clear
        return view
    }()

    private lazy var languageNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.textTitle
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    private lazy var rightImage: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .ud.primaryContentDefault
        imageView.image = UDIcon.getIconByKey(.listCheckBoldOutlined).withRenderingMode(.alwaysTemplate)
        imageView.isHidden = true
        return imageView
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUI()
    }

    private func setupUI() {
        self.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(languageKeyBorderView)
        languageKeyBorderView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(36)
            make.height.equalTo(26)
        }
        languageKeyBorderView.addSubview(languageKeyLabel)
        languageKeyLabel.snp.makeConstraints { make in
            make.left.greaterThanOrEqualTo(8)
            make.right.lessThanOrEqualTo(-8)
            make.center.equalToSuperview()
            make.height.equalToSuperview()
        }
        contentView.addSubview(languageNameLabel)
        languageNameLabel.snp.makeConstraints { make in
            make.left.equalTo(languageKeyBorderView.snp.right).offset(8)
            make.centerY.equalToSuperview()
        }
        contentView.addSubview(rightImage)
        rightImage.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
