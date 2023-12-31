//
//  ThemeSettingViewController.swift
//  LarkMine
//
//  Created by 姚启灏 on 2021/3/31.
//

import Foundation
import UIKit
import RxSwift
import LarkUIKit
import UniverseDesignTheme
import Homeric
import LKCommonsTracker
import FigmaKit

@available(iOS 13.0, *)
final class ThemeSettingViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {

    private lazy var tableView = self.createTableView()

    private var themes: [ThemeSettingItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkMine.Lark_Settings_DisplayAppearanceSubtitle
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        reloadThemeItems()
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private func reloadThemeItems() {
        themes = [
            ThemeSettingItem(
                name: BundleI18n.LarkMine.Lark_Settings_DisplayFollowSystem,
                image: Resources.mine_theme_followsystem,
                isSelected: UDThemeManager.userInterfaceStyle == .unspecified,
                isEnabled: true,
                onSelect: { [weak self] in
                    self?.switchUserInterfaceStyle(.unspecified)
                }
            ),
            ThemeSettingItem(
                name: BundleI18n.LarkMine.Lark_Settings_DisplayLight,
                image: Resources.mine_theme_light,
                isSelected: UDThemeManager.userInterfaceStyle == .light,
                isEnabled: true,
                onSelect: { [weak self] in
                    self?.switchUserInterfaceStyle(.light)
                }
            ),
            ThemeSettingItem(
                name: BundleI18n.LarkMine.Lark_Settings_DisplayDark,
                image: Resources.mine_theme_dark,
                isSelected: UDThemeManager.userInterfaceStyle == .dark,
                isEnabled: true,
                onSelect: { [weak self] in
                    self?.switchUserInterfaceStyle(.dark)
                }
            )
        ]
        tableView.reloadData()
    }

    private func switchUserInterfaceStyle(_ newStyle: UIUserInterfaceStyle) {
        reportThemeClicking(old: UDThemeManager.userInterfaceStyle, new: newStyle)
        guard UDThemeManager.userInterfaceStyle != newStyle else { return }
        UDThemeManager.setUserInterfaceStyle(newStyle)
        reloadThemeItems()
        reportThemeSwitching()
    }

    /// 创建表格视图
    private func createTableView() -> UITableView {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 8)))
        tableView.estimatedRowHeight = 50
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.lu.register(cellSelf: ThemeSettingCell.self)
        tableView.contentInsetAdjustmentBehavior = .automatic
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        return tableView
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view: UIView = UIView()
        view.snp.makeConstraints { (make) in
            make.height.equalTo(8)
        }
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView()
        let detailLabel: UILabel = UILabel()
        detailLabel.font = Cons.footerFont
        detailLabel.numberOfLines = 0
        detailLabel.textColor = Cons.footerColor
        detailLabel.text = UDThemeManager.userInterfaceStyle == .unspecified
            ? BundleI18n.LarkMine.Lark_Settings_DisplayFollowSystemToast : nil
        view.contentView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(-10)
            make.top.equalTo(4)
            make.left.equalTo(16)
            make.right.equalTo(-16)
        }
        return view
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ThemeSettingCell.lu.reuseIdentifier, for: indexPath) as? ThemeSettingCell ?? ThemeSettingCell()
        cell.configure(with: themes)
        return cell
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    enum Cons {
        static var footerFont: UIFont { UIFont.ud.body2 }
        static var footerColor: UIColor { UIColor.ud.textPlaceholder }
    }
}

// MARK: - Analytics

@available(iOS 13.0, *)
extension ThemeSettingViewController {

    private func reportThemeClicking(old: UIUserInterfaceStyle, new: UIUserInterfaceStyle) {
        // Analytics
        let clickType: String = {
            switch new {
            case .light:    return "light"
            case .dark:     return "dark"
            default:        return "default"
            }
        }()
        let viewType: String = {
            switch old {
            case .light:    return "light"
            case .dark:     return "dark"
            default:        return view.traitCollection.userInterfaceStyle == .dark ? "default_dark" : "dafault_light"
            }
        }()
        Tracker.post(TeaEvent(Homeric.SETTING_DETAIL_CLICK, params: [
            "click": "appearance_dark_mode",
            "target": "none",
            "click_type": clickType,
            "view_type": viewType
        ]))
    }

    private func reportThemeSwitching() {
        Tracker.post(TeaEvent(Homeric.SETTING_APP_APPR_MODE_VIEW, params: [
            "real_mode": realAppearance,
            "os_mode": systemAppearance,
            "app_mode": appAppearance,
            "upload_type": "user"  // 上报类型：主动切换
        ]))
    }

    private var systemAppearance: String {
        switch UIScreen.main.traitCollection.userInterfaceStyle {
        case .dark: return "dark"
        default:    return "light"
        }
    }

    private var appAppearance: String {
        switch UDThemeManager.userInterfaceStyle {
        case .light:    return "light"
        case .dark:     return "dark"
        default:        return "default"
        }
    }

    private var realAppearance: String {
        guard let keyWindow = UIApplication.shared.keyWindow else {
            return "light"
        }
        switch keyWindow.traitCollection.userInterfaceStyle {
        case .dark: return "dark"
        default:    return "light"
        }
    }
}
