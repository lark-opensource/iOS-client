//
//  ByteViewSettingsViewController.swift
//  ByteView_Example
//
//  Created by liujianlong on 2021/12/22.
//

import Foundation
import UIKit
import ByteViewInterface
import SnapKit
import UniverseDesignColor
import LarkStorage
import LarkContainer
import ByteViewUI
import ByteViewSetting
import ByteViewNetwork

class DemoSettingViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: .zero, style: .grouped)
    lazy var storage = KVStores.udkv(space: .user(id: resolver.userID), domain: Domain.biz.byteView.child("Demo"), mode: .normal)
    private var sections: [DemoCellSection] = []

    let resolver: UserResolver
    init?(resolver: UserResolver) {
        self.resolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "个人设置"
        tableView.rowHeight = 48
        tableView.separatorColor = .ud.commonTableSeparatorColor
        tableView.register(DemoSwitchCell.self, forCellReuseIdentifier: DemoCellType.swCell.rawValue)
        tableView.register(DemoCheckmarkCell.self, forCellReuseIdentifier: DemoCellType.checkmark.rawValue)
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.delegate = self
        tableView.dataSource = self
        self.reloadData()
    }

    func reloadData() {
        let translateSettings = self.translateLanguageSetting
        self.sections = [
            DemoCellSection(title: "CallKit", rows: [
                .swCell(title: "use system call",
                        isOn: storage.bool(forKey: "UniversalSetting_BYTEVIEW_USE_SYS_CALL"),
                        action: { [weak self] isOn in
                            self?.storage.set(isOn, forKey: "UniversalSetting_BYTEVIEW_USE_SYS_CALL")
                        }),
                .swCell(title: "include in recents",
                        isOn: storage.bool(forKey: "UniversalSetting_BYTEVIEW_USE_SYS_RECENT"),
                        action: { [weak self] isOn in
                            self?.storage.set(isOn, forKey: "UniversalSetting_BYTEVIEW_USE_SYS_RECENT")
                        })
            ]),
            DemoCellSection(title: "将内容翻译为", rows: [
                .checkmark(title: "English", isOn: translateSettings.targetLanguage == "en",
                           action: { [weak self] _ in
                               self?.updateTranslateLanguage(targetLanguage: "en")
                           }),
                .checkmark(title: "简体中文", isOn: translateSettings.targetLanguage == "zh",
                           action: { [weak self] _ in
                               self?.updateTranslateLanguage(targetLanguage: "zh")
                           }),
                .checkmark(title: "日本語", isOn: translateSettings.targetLanguage == "ja",
                           action: { [weak self] _ in
                               self?.updateTranslateLanguage(targetLanguage: "ja")
                           }),
                .checkmark(title: "ไทย", isOn: translateSettings.targetLanguage == "th",
                           action: { [weak self] _ in
                               self?.updateTranslateLanguage(targetLanguage: "th")
                           })
            ]),
            DemoCellSection(title: "翻译后的显示效果", rows: [
                .checkmark(title: "显示原文和译文", isOn: translateSettings.globalConf.rule == .withOriginal,
                           action: { [weak self] _ in
                               self?.updateTranslateLanguage(rule: .withOriginal)
                           }),
                .checkmark(title: "仅显示译文", isOn: translateSettings.globalConf.rule == .onlyTranslation,
                           action: { [weak self] _ in
                               self?.updateTranslateLanguage(rule: .onlyTranslation)
                           })
            ]),
            DemoCellSection(title: nil, rows: [
                .swCell(title: "会中聊天自动翻译", isOn: translateSettings.isAutoTranslationOn,
                        action: { [weak self] isOn in
                            self?.updateTranslateLanguage(isAutoTranslationOn: isOn)
                            self?.reloadData()
                        })
            ])
        ]
        self.tableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.type.rawValue, for: indexPath)
        if let cell = cell as? DemoTableViewCell {
            cell.updateItem(row)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        if row.type == .checkmark {
            row.swAction(!row.isOn)
        }
    }

    var translateLanguageSetting: ByteViewSetting.TranslateLanguageSetting {
        let availableLanguages: [ByteViewSetting.TranslateLanguage] = [
            ByteViewSetting.TranslateLanguage(key: "en", name: "English"),
            ByteViewSetting.TranslateLanguage(key: "zh", name: "简体中文"),
            ByteViewSetting.TranslateLanguage(key: "ja", name: "日本語"),
            ByteViewSetting.TranslateLanguage(key: "th", name: "ไทย")
        ]
        return ByteViewSetting.TranslateLanguageSetting(
            targetLanguage: storage.string(forKey: "demo_target_language") ?? "en",
            isAutoTranslationOn: storage.bool(forKey: "demo_is_vc_auto_translation_on"),
            availableLanguages: availableLanguages,
            globalConf: .init(rule: storage.string(forKey: "demo_translation_display_rule") == "onlyTranslation" ? .onlyTranslation : .withOriginal)
        )
    }

    func updateTranslateLanguage(isAutoTranslationOn: Bool? = nil, targetLanguage: String? = nil, rule: TranslateDisplayRule? = nil) {
        var setting = translateLanguageSetting
        if let isOn = isAutoTranslationOn {
            setting.isAutoTranslationOn = isOn
            storage.set(isOn, forKey: "demo_is_vc_auto_translation_on")
        }
        if let targetLanguage = targetLanguage {
            setting.targetLanguage = targetLanguage
            storage.set(targetLanguage, forKey: "demo_target_language")
        }
        if let rule = rule {
            setting.globalConf.rule = rule
            storage.set(rule == .onlyTranslation ? "onlyTranslation" : "withOriginal", forKey: "demo_target_language")
        }
        self.reloadData()
    }
}
