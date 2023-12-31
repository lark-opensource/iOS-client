//
//  SceneSwitcherViewController.swift
//  LarkSceneManager
//
//  Created by Saafo on 2021/4/1.
//

import UIKit
import Foundation
import Homeric
import LarkBlur
import LarkKeyCommandKit
import LKCommonsLogging
import LKCommonsTracker
import SnapKit
import UniverseDesignColor

// MARK: ViewController

@available(iOS 13.4, *)
public final class SceneSwitcherViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // Components
    static let logger = Logger.log(SceneSwitcherViewController.self, category: "Module.LarkSceneManager.SceneSwitcher")
    public var selectedIndex: Int {
        get { return _selectedIndex }
        set {
            if newValue >= table.numberOfRows(inSection: 0) {
                _selectedIndex = 0
            } else if newValue < 0 {
                _selectedIndex = table.numberOfRows(inSection: 0) - 1
            } else {
                _selectedIndex = newValue
            }
        }
    }
    private var _selectedIndex: Int = 0 {
        willSet {
            guard _selectedIndex != newValue else { return }
            let path = IndexPath(row: _selectedIndex, section: 0)
            table.cellForRow(at: path)?.setHighlighted(false, animated: true)
        }
        didSet {
            let path = IndexPath(row: _selectedIndex, section: 0)
            table.scrollToRow(at: path, at: .none, animated: true)
            table.cellForRow(at: path)?.setHighlighted(true, animated: true)
        }
    }
    /// 透明底板，点击退出 Switcher
    var transparentView = UIView()
    /// Switcher 主体
    var containerView = UIView()
    /// 选择列表
    var table = UITableView()
    /// 唤起 Switcher 时，按序排列的 scenes 列表，每次出现时会刷新
    var scenes: [UIScene] = []

    // MARK: 选择快捷键
    /// 窗口数量大于这个量才会显示快捷键
    let ignoringSceneNum = 3
    let sceneKeyBindingMap: [String] = ["1", "2", "3", "Q", "W", "E", "A", "S"]
    func getKeyBindingInput(for sceneIndex: Int) -> String? {
        guard scenes.count > ignoringSceneNum && (0..<sceneKeyBindingMap.count).contains(sceneIndex) else { return nil }
        return sceneKeyBindingMap[sceneIndex]
    }
    public override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + upKeyBindings + downKeyBindings + jumpKeyBindings
    }
    let upBaseInfo = [
        KeyCommandBaseInfo(input: UIKeyCommand.inputTab, modifierFlags: [.control, .shift]),
        KeyCommandBaseInfo(input: UIKeyCommand.inputUpArrow, modifierFlags: [.control])
    ]
    let downBaseInfo = [
        KeyCommandBaseInfo(input: UIKeyCommand.inputTab, modifierFlags: [.control]),
        KeyCommandBaseInfo(input: UIKeyCommand.inputDownArrow, modifierFlags: [.control])
    ]
    lazy var upKeyBindings: [KeyBindingWraper] = {
        upBaseInfo.map {
            $0.binding { [weak self] in
                self?.selectedIndex -= 1
                if let index = self?.selectedIndex, let number = self?.table.numberOfRows(inSection: 0) {
                    Self.logger.info("select next index: \(index) out of \(number)")
                }
            }.wraper
        }
    }()
    lazy var downKeyBindings: [KeyBindingWraper] = {
        downBaseInfo.map {
            $0.binding { [weak self] in
                self?.selectedIndex += 1
                if let index = self?.selectedIndex, let number = self?.table.numberOfRows(inSection: 0) {
                    Self.logger.info("select next index: \(index) out of \(number)")
                }
            }.wraper
        }
    }()
    var jumpKeyBindings: [KeyBindingWraper] {
        var keyBindings: [KeyBindingWraper] = []
        for index in 0..<scenes.count {
            guard let input = getKeyBindingInput(for: index) else { continue }
            keyBindings.append(
                KeyCommandBaseInfo(input: input, modifierFlags: [.control])
                    .binding {
                        let path = IndexPath(row: index, section: 0)
                        self.table.selectRow(at: path, animated: true, scrollPosition: .none)
                        self.table.delegate?.tableView?(self.table, didSelectRowAt: path)
                    }.wraper
            )
        }
        return keyBindings
    }

    // MARK: Life Cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        // transparent view
        view.addSubview(transparentView)
        transparentView.backgroundColor = .clear
        transparentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissSwitcher)))
        transparentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        // background ui
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowOffset = CGSize(width: 0, height: 8)
        containerView.ud.setLayerShadowColor(UIColor.ud.N900)
        containerView.layer.shadowRadius = 24
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 0.5
        containerView.ud.setLayerBorderColor(UIColor.ud.N900.withAlphaComponent(0.10))
        let blurView = LarkBlurEffectView()
        blurView.blurRadius = 12
        blurView.colorTint = UIColor.ud.N100
        blurView.colorTintAlpha = 0.7
        blurView.layer.cornerRadius = 12
        blurView.clipsToBounds = true
        containerView.addSubview(blurView)
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        // table ui
        table.tableHeaderView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0.1, height: 0.1)))
        table.tableFooterView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 0.1, height: 0.1)))
        table.estimatedRowHeight = 56
        table.rowHeight = 56
        table.backgroundColor = .clear
        table.separatorStyle = .none
        containerView.addSubview(table)
        table.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(25)
        }
        // background layout
        view.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16).priority(.low)
            $0.width.lessThanOrEqualTo(540)
            $0.center.equalToSuperview()
            $0.height.equalTo(table.contentSize.height + 50).priority(.low)
            $0.height.lessThanOrEqualTo(8 * table.rowHeight + 50)
            $0.height.lessThanOrEqualToSuperview().inset(80)
        }
        // table data
        table.delegate = self
        table.dataSource = self
    }

    // MARK: Private

    func reload() {
        reloadScenes()
        table.reloadData()
        containerView.snp.updateConstraints {
            $0.height.equalTo(table.contentSize.height + 50).priority(.low)
        }
        // 窗口数量大于 1 时，默认选中第 2 个
        selectedIndex = table.numberOfRows(inSection: 0) > 1 ? 1 : 0
    }

    func reloadScenes() {
        scenes = Array(UIApplication.shared.connectedScenes.filter { $0 is UIWindowScene })
            .sorted(by: { $0.sceneInfo.activeTime > $1.sceneInfo.activeTime })
        Self.logger.info("reloaded scenes: \(scenes)")
    }

    func switchToSelectedScene() {
        let path = IndexPath(row: self.selectedIndex, section: 0)
        self.table.selectRow(at: path,
                             animated: true, scrollPosition: .none)
        self.table.delegate?.tableView?(self.table, didSelectRowAt: path)
    }

    @objc
    func dismissSwitcher() {
        SceneSwitcher.shared.window.isHidden = true
    }

    // MARK: TableView Delegate
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UIApplication.shared.connectedScenes.filter { $0 is UIWindowScene }.count
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let scene = scenes[indexPath.row]
        let text: String = scene.sceneInfo.isMainScene() ?
            BundleI18n.LarkSceneManager.Lark_Core_MainWindowButton() :
            !scene.title.isEmpty ? scene.title : ""
        let icon = scene.sceneInfo.isMainScene() ?
            Resources.mainSceneIcon :
            SceneManager.shared.icons[scene.sceneInfo.key]?()
        let keyBindingInput = getKeyBindingInput(for: indexPath.row)
        let cell = SceneSwitcherTableViewCell(image: icon, text: text, keyBindingInput: keyBindingInput)
        SceneManager.shared.contextualIcons[scene.sceneInfo.key]?(cell.iconView, scene.sceneInfo)
        return cell
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let selectedScene = scenes[index]
        SceneManager.shared.active(
            scene: selectedScene.sceneInfo,
            from: UIApplication.shared.keyWindow?.windowScene,
            keepLayout: true,
            callback: { _, _ in
                selectedScene.rootWindow()?.makeKey()
            })
        dismissSwitcher()
        // active 之后立即主动 makeKey，让可能产生的按键事件传递到即将被激活的 window 上
        // 避免由于接收不到 control ended 事件 导致窗口卡住问题
        selectedScene.rootWindow()?.makeKey()
        Tracker.post(TeaEvent(Homeric.PUBLIC_SHORTCUT_SCENE_SWITCHER))
        Self.logger.info("Switch to index: \(selectedIndex) out of \(table.numberOfRows(inSection: 0))")
        Self.logger.info("Switch to scene: \(String(describing: selectedScene))")
    }
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == selectedIndex {
            cell.setHighlighted(true, animated: false)
        } else {
            cell.setHighlighted(false, animated: false)
        }
    }
}
