//
//  LanguagePickerViewController.swift
//  LarkAudio
//
//  Created by 白镜吾 on 2023/2/16.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import Reachability
import LarkLocalizations
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignToast
import LKCommonsLogging
import UniverseDesignActionPanel
import LarkRustClient
import LarkContainer

final class LanguagePickerViewController: BaseUIViewController,
                                          LanguagePickerHeaderDelegate,
                                          UITableViewDelegate,
                                          UITableViewDataSource,
                                          UserResolverWrapper {
    private static let logger = Logger.log(LanguagePickerViewController.self, category: "LarkAudio")

    var currentTargetLanguage: Lang

    let dividerHeight = 1 / UIScreen.main.scale
    let disposeBag = DisposeBag()

    private var supportLangs: [Lang]
    private var supportLangsi18nMap: [Lang: String]
    private var recognizeType: AudioTracker.RecognizeType

    private lazy var panelHeader: LanguagePickerHeader = {
        let header = LanguagePickerHeader()
        header.delegate = self
        return header
    }()

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(LanguagePickerCell.self, forCellReuseIdentifier: LanguagePickerCell.lu.reuseIdentifier)
        tableView.backgroundColor = UIColor.ud.bgBody
        return tableView
    }()

    let userResolver: UserResolver
    init(userResolver: UserResolver, currentTargetLanguage: Lang, supportLangs: [Lang], supportLangsi18nMap: [Lang: String], recognizeType: AudioTracker.RecognizeType) {
        self.userResolver = userResolver
        self.currentTargetLanguage = currentTargetLanguage
        self.supportLangs = supportLangs
        self.supportLangsi18nMap = supportLangsi18nMap
        self.recognizeType = recognizeType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addSubViews()
        self.setConstraints()
    }

    func addSubViews() {
        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(panelHeader)
        self.view.addSubview(divider)
        self.view.addSubview(tableView)
    }

    func setConstraints() {
        panelHeader.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(48)
            make.top.equalToSuperview()
        }

        divider.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(dividerHeight)
            make.top.equalTo(panelHeader.snp.bottom)
        }

        let tableViewHeight = 48 * self.supportLangs.count
        tableView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(tableViewHeight)
            make.top.equalTo(divider.snp.bottom)
        }
    }

// MARK: Delegate

    func closePanel() {
        self.dismiss(animated: true)
    }

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
        return self.supportLangs.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.supportLangs.count else {
            return UITableViewCell()
        }

        guard supportLangs.count == supportLangsi18nMap.count else {
            return UITableViewCell()
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: LanguagePickerCell.lu.reuseIdentifier) as? LanguagePickerCell else {
            return UITableViewCell()
        }

        // 当前 cell 对应语种
        let cellShownLang = supportLangs[indexPath.row]
        // 当前 cell 对应语种的 i18n 文案
        let cellShownLangi18n = supportLangsi18nMap[cellShownLang]
        // 当前 cell 是否是被选中状态
        let isChecked = cellShownLang == currentTargetLanguage
        cell.configure(cellShownLangi18n, isChecked: isChecked)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        let selectItem = supportLangs[indexPath.row]

        guard currentTargetLanguage != selectItem else { return }
        AudioTracker.imVoiceSwitchLanguaeClick(viewType: self.recognizeType,
                                                beforeLanguage: self.currentTargetLanguage,
                                                selectLanguage: selectItem)
        self.currentTargetLanguage = selectItem
        self.tableView.reloadData()

        guard checkNetworkConnection() else { return }

        guard let i18n = self.supportLangsi18nMap[selectItem] else { return }

        /// 设置选择的语种的类型和文案
        RecognizeLanguageManager.shared.recognitionLanguageI18n = i18n
        RecognizeLanguageManager.shared.recognitionLanguage = selectItem

        self.dismiss(animated: true)

        /// 用户设置语种后， 1. 同步本地配置 2. 同步服务端
        AudioKeyboardDataService.shared.putSpeechConfig(client: try? userResolver.resolve(assert: RustService.self), manualConfLang: selectItem)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { response in
                Self.logger.error("Successed to sync selected language, code:\(response.code), requestNo: \(response.requestNo)")
            }, onError: { error in
                Self.logger.error("Failed to sync selected language, error: \(error)")
            })
            .disposed(by: self.disposeBag)
    }

    private func checkNetworkConnection() -> Bool {
        guard let reach = Reachability() else { return false }
        guard let window = self.view.window else {
            assertionFailure("Lost Window To show Toast")
            return true
        }
        if reach.connection == .none {
            UDToast.showFailure(with: BundleI18n.LarkAudio.Lark_Legacy_ErrorMessageTip, on: window)
            Self.logger.error("Network can't connect")
            return false
        }
        return true
    }
}
