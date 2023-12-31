//
//  DemoRingtoneViewController.swift
//  ByteView_Example
//
//  Created by admin on 2022/10/28.
//

import UIKit
import ByteViewSetting
import ByteViewUI
import ByteView
import RxSwift
import UniverseDesignIcon
import UniverseDesignToast

class DemoRingtoneViewController: BaseViewController, UserSettingListener, UITableViewDataSource, UITableViewDelegate {
    enum RingtoneType: Equatable {
        case `default`
        case spring

        var ringtoneTitle: String {
            switch self {
            case .`default`:
                return "默认"
            case .spring:
                return "欢快"
            }
        }

        var ringtoneName: String {
            switch self {
            case .`default`:
                return "vc_call_ringing.mp3"
            case .spring:
                return "vc_call_ringing_spring.mp3"
            }
        }

        var ringtoneURL: URL? {
            switch self {
            case .`default`:
                return Bundle.main.url(forResource: "vc_call_ringing", withExtension: "mp3")
            case .spring:
                return Bundle.main.url(forResource: "vc_call_ringing_spring", withExtension: "mp3")
            }
        }

        static func typeFromName(_ name: String) -> Self {
            switch name {
            case Self.`default`.ringtoneName:
                return .`default`
            case Self.spring.ringtoneName:
                return .spring
            default:
                return .`default`
            }
        }
    }
    private let setting: UserSettingManager
    private let player = CustomRingtonePlayer()
    private let tableView = BaseTableView()
    private var items: [DemoCellRow] = []
    private var ringtoneType: RingtoneType = .`default`
    private let disposeBag = DisposeBag()

    init(setting: UserSettingManager) {
        self.setting = setting
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ringtoneType = RingtoneType.typeFromName(setting.customRingtone)
        self.title = "铃声-\(ringtoneType.ringtoneTitle)"
        view.backgroundColor = .white
        tableView.rowHeight = 68
        tableView.register(DemoCheckmarkCell.self, forCellReuseIdentifier: DemoCellType.checkmark.rawValue)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.top.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        tableView.delegate = self
        tableView.dataSource = self
        reloadData()
        setting.addListener(self, for: .viewUserSetting)
    }

    func reloadData() {
        let ringtones: [RingtoneType] = [.default, .spring]
        self.items = ringtones.map { ringtone in
                .checkmark(title: ringtone.ringtoneTitle, isOn: ringtoneType == ringtone,
                           action: { [weak self] _ in
                    self?.playOrStopRingtone(type: ringtone)
                    self?.reloadData()
                })
        }
        self.tableView.reloadData()
    }

    func didChangeUserSetting(_ settings: UserSettingManager, _ change: UserSettingChange) {
        if case let .viewUserSetting(obj) = change, let ringtone = obj.value.meetingGeneral.ringtone {
            DispatchQueue.main.async {
                self.ringtoneType = RingtoneType.typeFromName(ringtone)
                self.reloadData()
            }
        }
    }

    func playOrStopRingtone(type: RingtoneType) {
        let needStop = type == ringtoneType
        let oldType = ringtoneType
        ringtoneType = type
        self.title = "铃声-\(ringtoneType.ringtoneTitle)"
        if needStop, player.isPlayingRingtone() {
            player.stopPlayRingtone()
            return
        }
        if needStop, !player.isPlayingRingtone() {
            player.stopPlayRingtone()
        }
        setting.updateCustomRingtone(type.ringtoneName) { [weak self] in
            if case .failure = $0 {
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.ringtoneType = oldType
                    self.title = "铃声-\(oldType.ringtoneTitle)"
                    self.tableView.reloadData()
                    UDToast.showTips(with: "更换铃声失败", on: self.view)
                }
            }
        }
        player.playRingtone(url: type.ringtoneURL)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: item.type.rawValue, for: indexPath)
        if let cell = cell as? DemoTableViewCell {
            cell.updateItem(item)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        items[indexPath.row].action()
    }
}
