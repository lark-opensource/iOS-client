//
//  InterpreterLanguageViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2020/10/22.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//
import SnapKit
import ByteViewUI
import ByteViewCommon
import UniverseDesignIcon
import ByteViewNetwork

final class InterpreterLanguageViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    private let icon = UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN1, size: CGSize(width: 20, height: 20))

    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(icon, for: .normal)
        button.addTarget(self, action: #selector(doBack), for: .touchUpInside)
        return button
    }()

    lazy var searchView = SearchBarView()

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: CGRect.zero, style: .plain)
        tableView.showsVerticalScrollIndicator = true
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = 48
        let footerView = UIView()
        footerView.backgroundColor = .clear
        footerView.frame = CGRect(x: 0, y: 0, width: 100, height: 16)
        tableView.tableFooterView = footerView
        tableView.register(InterpreterLanguageCell.self, forCellReuseIdentifier: "InterpreterLanguageCell")
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    let i18nService: I18nNetworkAPI
    let supportInterpretationLanguage: [InterpreterSetting.LanguageType]
    var selectedLanguage: InterpreterSetting.LanguageType?
    let callback: (InterpreterSetting.LanguageType) -> Void
    init(i18nService: I18nNetworkAPI, supportInterpretationLanguage: [InterpreterSetting.LanguageType],
         selectedLanguage: InterpreterSetting.LanguageType?,
         callback: @escaping (InterpreterSetting.LanguageType) -> Void) {
        self.i18nService = i18nService
        self.supportInterpretationLanguage = supportInterpretationLanguage
        self.selectedLanguage = selectedLanguage
        self.callback = callback
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = .bottom
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        title = I18n.View_G_SelectLanguage

        view.addSubview(searchView)
        view.addSubview(tableView)

        searchView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.height.equalTo(54)
            make.left.right.equalTo(self.view.safeAreaLayoutGuide)
        }
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(searchView.snp.bottom)
        }

        searchView.textDidChange = { [weak self] in
            self?.searchText = $0
            self?.reloadData()
        }
        reloadData()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    @RwAtomic
    private var searchText = ""
    @RwAtomic
    private var languageInfos: [InterpreterLanguageInfo] = []

    func reloadData() {
        let languages = self.supportInterpretationLanguage
        let i18nKeys = languages.map { $0.despI18NKey }
        i18nService.get(i18nKeys) { [weak self] result in
            guard let self = self, case let .success(map) = result else { return }
            var infos = languages.compactMap { language in
                if let i18nText = map[language.despI18NKey] {
                    return InterpreterLanguageInfo(languageType: language, i18nText: i18nText,
                                                   isSelected: self.selectedLanguage?.languageType == language.languageType)
                } else {
                    return nil
                }
            }
            if !self.searchText.isEmpty {
                infos = infos.filter({ $0.i18nText.lowercased().contains(self.searchText.lowercased()) })
            }
            Util.runInMainThread {
                self.languageInfos = infos
                self.tableView.reloadData()
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.bounces = scrollView.contentOffset.y > scrollView.contentInset.top
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.languageInfos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InterpreterLanguageCell", for: indexPath)
        if let cell = cell as? InterpreterLanguageCell {
            cell.config(with: self.languageInfos[indexPath.row])
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let language = self.languageInfos[indexPath.row]
        self.callback(language.languageType)
        self.doBack()
    }
}

private class InterpreterLanguageCell: UITableViewCell {
    let iconView = UIImageView()
    let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.ud.fillHover
        self.selectedBackgroundView = selectedBackgroundView
        setupLayouts()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayouts() {
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)

        iconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
    }

    private var model: InterpreterLanguageInfo?
    func config(with model: InterpreterLanguageInfo) {
        self.model = model
        titleLabel.attributedText = NSAttributedString(string: model.i18nText, config: .r_16_24)
        if model.isSelected {
            titleLabel.textColor = .ud.textDisabled
            iconView.image = LanguageIconManager.get(by: model.languageType, foregroundColor: .ud.udtokenBtnPriTextDisabled, backgroundColor: .ud.N400)
            isUserInteractionEnabled = false
        } else {
            titleLabel.textColor = .ud.textTitle
            iconView.image = LanguageIconManager.get(by: model.languageType)
            isUserInteractionEnabled = true
        }
    }
}

private struct InterpreterLanguageInfo {
    let languageType: InterpreterSetting.LanguageType
    let i18nText: String
    let isSelected: Bool
}
