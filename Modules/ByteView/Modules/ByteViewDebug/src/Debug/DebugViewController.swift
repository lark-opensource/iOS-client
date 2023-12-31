//
//  DebugViewController.swift
//  ByteView
//
//  Created by huangshun on 2019/5/5.
//

import UIKit
import RxSwift
import SnapKit
import LarkMedia
import ByteView
import RustPB
import ByteViewSetting

typealias VideoChatInfo = Videoconference_V1_VideoChatInfo

class DebugItem {
    enum DebugItemType: Int {
        case meetingWindowEnable = 1007
        case autoRotationDuration = 1008
        case audioSessionDebugEnable = 1010
        case rtcVendorType = 1011
        case rtcClientMode = 1012
        case pipEnable = 1013
        case callKitEnable = 1014
        case callKitOutgoingEnable = 1015
        case pipSampleBufferRenderEnable = 1016
    }
    enum ItemStyle {
        case detail(_ detail: String, type: DebugItemType)
        case switchButton(isOn: Bool, type: DebugItemType)
    }
    var title: String
    var style: ItemStyle
    var type: DebugItemType {
        switch style {
        case .detail(_, let type):
            return type
        case .switchButton(_, let type):
            return type
        }
    }

    init(title: String, style: ItemStyle) {
        self.title = title
        self.style = style
    }
}

public func createByteViewDebugVC() -> UIViewController {
    DebugViewController()
}
class DebugViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var tableView: UITableView = .init(frame: .zero)
    private let defaultCellIdentifier = "defaultCellIdentifier"
    private let switchCellIdentifier = "switchCellIdentifier"
    private let disposeBag = DisposeBag()

    var sectionItems: [(String, [DebugItem])] = []
    let formEntries: [DebugFormEntry] = DebugConfigs.entries
    let formCellBuilder = FormCellBuilder()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "视频会议调试"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(didClose))

        tableView = UITableView(frame: view.bounds, style: .grouped)
        formCellBuilder.registerCells(tableView: tableView)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        addMeetingItems()
        addCallKitItems()
        addOtherUtilityItems()
    }

    @objc private func didClose() {
        if let nav = self.navigationController, self != nav.viewControllers.first {
            nav.popViewController(animated: true)
        } else if let p = self.presentingViewController {
            p.dismiss(animated: true, completion: nil)
        }
    }

    func addMeetingItems() {
        let meeting = (
            "会议配置",
            [
                DebugItem(
                    title: "会议窗口",
                    style: .switchButton(
                        isOn: DebugConfig.shared.meetingWindowEnable,
                        type: .meetingWindowEnable
                    )
                ),
                DebugItem(
                    title: "设备自动旋转间隔",
                    style: .detail(
                        String(DebugConfig.shared.autoRotationDuration),
                        type: .autoRotationDuration
                    )
                )
            ]
        )
        sectionItems.append(meeting)
    }

    func addCallKitItems() {
        let callKit = (
            "Callkit",
            [
                DebugItem(
                    title: "本地开启 CallKit",
                    style: .switchButton(
                        isOn: DebugSettings.isCallKitEnabled,
                        type: .callKitEnable
                    )
                ),
                DebugItem(
                    title: "主动入会开启 Callkit",
                    style: .switchButton(
                        isOn: DebugSettings.isCallKitOutgoingEnabled,
                        type: .callKitOutgoingEnable
                    )
                )
            ]
        )
        sectionItems.append(callKit)
    }

    func addOtherUtilityItems() {
        let utility = (
            "其他工具",
            [
                DebugItem(
                    title: "音频调试",
                    style: .switchButton(
                        isOn: !AudioSessionDebugManager.shared.isEntryHidden,
                        type: .audioSessionDebugEnable
                    )
                ),
                DebugItem(
                    title: "开启画中画",
                    style: .switchButton(
                        isOn: DebugSettings.isPiPEnabled,
                        type: .pipEnable
                    )
                ),
                DebugItem(
                    title: "开启画中画SampleBuffer渲染",
                    style: .switchButton(
                        isOn: DebugSettings.isPiPSampleBufferRenderEnabled,
                        type: .pipSampleBufferRenderEnable
                    )
                )
            ]
        )
        sectionItems.append(utility)
    }

    func isPureDouble(_ string: String) -> Bool {
        let scanner = Scanner(string: string)
        return scanner.scanDouble(nil) && scanner.isAtEnd
    }

    // MARK: - Action
    func showTextFieldAlterViewController(item: DebugItem) {
        if item.type == .rtcVendorType || item.type == .rtcClientMode {
            return
        }
        switch item.style {
        case .detail(let detail, _):
            let alert = UIAlertController(title: item.title,
                                          message: nil,
                                          preferredStyle: .alert)

            alert.addTextField { textField in
                textField.placeholder = item.title
                textField.text = detail
            }
            let okAction = buildOkAction(item, for: alert)

            let ok = UIAlertAction.init(title: "确定", style: .default, handler: okAction)
            let cancle = UIAlertAction(title: "取消", style: .cancel)
            alert.addAction(cancle)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        default:
            break
        }
    }

    @objc func didClickSwitchButton(sender: UISwitch) {
        switch sender.tag {
        case DebugItem.DebugItemType.meetingWindowEnable.rawValue:
            DebugConfig.shared.meetingWindowEnable = sender.isOn
        case DebugItem.DebugItemType.audioSessionDebugEnable.rawValue:
            if sender.isOn {
                AudioSessionDebugManager.shared.showEntry()
            } else {
                AudioSessionDebugManager.shared.hideEntry()
            }
        case DebugItem.DebugItemType.pipEnable.rawValue:
            DebugSettings.isPiPEnabled = sender.isOn
        case DebugItem.DebugItemType.pipSampleBufferRenderEnable.rawValue:
            DebugSettings.isPiPSampleBufferRenderEnabled = sender.isOn
        case DebugItem.DebugItemType.callKitEnable.rawValue:
            DebugSettings.isCallKitEnabled = sender.isOn
        case DebugItem.DebugItemType.callKitOutgoingEnable.rawValue:
            DebugSettings.isCallKitOutgoingEnabled = sender.isOn
        default:
            break
        }
    }

    // MARK: - UITableViewDelegate & UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionItems.count + 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == sectionItems.count {
            return formEntries.count
        }
        return sectionItems[section].1.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == sectionItems.count {
            return formCellBuilder.createCell(tableView: tableView,
                                              indexPath: indexPath,
                                              for: formEntries[indexPath.row])
        }
        let item = sectionItems[indexPath.section].1[indexPath.row]
        var cell: UITableViewCell!
        switch item.style {
        case .detail(let detail, _):
            cell = tableView.dequeueReusableCell(withIdentifier: defaultCellIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: defaultCellIdentifier)
            }
            cell.detailTextLabel?.text = detail
        case .switchButton(let isOn, let type):
            cell = tableView.dequeueReusableCell(withIdentifier: switchCellIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .value1, reuseIdentifier: switchCellIdentifier)
                let switchButton = UISwitch()
                switchButton.isOn = isOn
                switchButton.tag = type.rawValue
                switchButton.addTarget(self, action: #selector(didClickSwitchButton(sender:)), for: .valueChanged)
                cell.accessoryView = switchButton
                cell.selectionStyle = .none
            }
            if let itemSwitch = cell.accessoryView as? UISwitch {
                itemSwitch.isOn = isOn
            }
        }
        cell.textLabel?.text = item.title
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == sectionItems.count {
            return "动态配置"
        }
        return sectionItems[section].0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section >= sectionItems.count {
            formEntries[indexPath.row].tableViewDidSelectEntry(tableView, vc: self)
            return
        }
        let item = sectionItems[indexPath.section].1[indexPath.row]
        switch item.style {
        case .detail:
            showTextFieldAlterViewController(item: item)
        default:
            break
        }
    }
}

extension DebugViewController {

    func buildOkAction(_ item: DebugItem, for alert: UIAlertController) -> ((UIAlertAction) -> Void)? {
        switch item.type {
        case .autoRotationDuration:
            return autoRotationDurationAction(item, for: alert)
        default:
            break
        }
        return nil
    }

    private func autoRotationDurationAction(_ item: DebugItem,
                                            for alert: UIAlertController) -> ((UIAlertAction) -> Void)? {
        return { [weak self, weak alert] _ in
            if let string = alert?.textFields?.first?.text,
                self?.isPureDouble(string) ?? false, let duration = Double(string) {
                DebugConfig.shared.autoRotationDuration = duration
                item.style = .detail(
                    String(duration),
                    type: .autoRotationDuration
                )
                self?.tableView.reloadData()

                DebugConfig.shared.autoRotationDispose = DisposeBag()
                if duration > 0 {
                    Observable<Int>.timer(0.0, period: duration, scheduler: MainScheduler.instance)
                        .subscribe(onNext: {
                            let value = ($0 % 4) + 1
                            UIDevice.current.setValue(value, forKey: "orientation")
                            UIViewController.attemptRotationToDeviceOrientation()
                        })
                        .disposed(by: DebugConfig.shared.autoRotationDispose)
                }
            }
        }
    }
}
