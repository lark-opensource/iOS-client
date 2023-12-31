//
//  NotificationSoundViewController.swift
//  LarkMine
//
//  Created by Yaoguoguo on 2022/10/8.
//

import UIKit
import AVFoundation
import Foundation
import LarkUIKit
import FigmaKit
import RxSwift
import RxCocoa
import SnapKit
import LarkContainer
import LarkSDKInterface
import RustPB

///// 铃声
public enum NotificationSoundType: String {
    case `default`
    case chord
    case aurora
    case circles
    case silence
    case at
    case normal
    case urgent

    var soundName: String {
        switch self {
        case .`default`:
            return "sound_default.mp3"
        case .chord:
            return "sound_chord.mp3"
        case .aurora:
            return "sound_aurora.mp3"
        case .circles:
            return "sound_circles.mp3"
        case .silence:
            return "silence.m4a"
        case .at:
            return "sound_at.mp3"
        case .normal:
            return "sound_normal.mp3"
        case .urgent:
            return "sound_urgent.mp3"
        }
    }

    var title: String {
        switch self {
        case .`default`:
            return BundleI18n.LarkMine.Lark_Core_Notification_SoundAndVibration_FollowsSystem
        case .chord:
            return BundleI18n.LarkMine.Lark_Core_Notification_SoundAndVibration_Chord
        case .aurora:
            return BundleI18n.LarkMine.Lark_Core_Notification_SoundAndVibration_Aurora
        case .circles:
            return BundleI18n.LarkMine.Lark_Core_Notification_SoundAndVibration_Circles
        case .silence:
            return BundleI18n.LarkMine.Lark_Core_Notification_SoundAndVibration_None
        case .at:
            return BundleI18n.LarkMine.Lark_Core_Notification_SoundAndVibration_ForMentions
        case .urgent:
            return BundleI18n.LarkMine.Lark_Core_Notification_SoundAndVibration_ForBuzz
        case .normal:
            return BundleI18n.LarkMine.Lark_Core_Notification_SoundAndVibration_ForOtherMessages
        }
    }

    var soundURL: URL? {
        switch self {
        case .`default`:
            return Bundle.main.url(forResource: "sound_default", withExtension: "mp3")
        case .chord:
            return Bundle.main.url(forResource: "sound_chord", withExtension: "mp3")
        case .aurora:
            return Bundle.main.url(forResource: "sound_aurora", withExtension: "mp3")
        case .circles:
            return Bundle.main.url(forResource: "sound_circles", withExtension: "mp3")
        case .silence:
            return Bundle.main.url(forResource: "silence", withExtension: "m4a")
        case .at:
            return Bundle.main.url(forResource: "sound_at", withExtension: "mp3")
        case .normal:
            return Bundle.main.url(forResource: "sound_normal", withExtension: "mp3")
        case .urgent:
            return Bundle.main.url(forResource: "sound_urgent", withExtension: "mp3")
        }
    }

    static func getKeyByName(_ name: String) -> NotificationSoundType {
        switch name {
        case "sound_chord.mp3":
            return .chord
        case "sound_aurora.mp3":
            return .aurora
        case "sound_circles.mp3":
            return .circles
        case "silence.m4a":
            return .silence
        case "sound_at.mp3":
            return .at
        case "sound_normal.mp3":
            return .normal
        case "sound_urgent.mp3":
            return .urgent
        default:
            return .default
        }
    }
}

public final class NotificationSoundViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    private let userGeneralSettings: UserGeneralSettings
    public override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private var data: [NotificationSoundType] = []

    private var selectedType: NotificationSoundType

    private let key: String

    private let disposeBag = DisposeBag()

    private var avplayer: AVAudioPlayer?

    private var lastIndexPath: IndexPath?

    /// 表格视图
    private lazy var tableView = self.createTableView()

    init(title: String, key: String, selectedValue: String, userGeneralSettings: UserGeneralSettings) {
        let type = NotificationSoundType.getKeyByName(selectedValue)
        self.selectedType = type
        self.key = key
        self.userGeneralSettings = userGeneralSettings

        super.init(nibName: nil, bundle: nil)

        var specialType: NotificationSoundType = .normal
        switch key {
        case "Lark_Core_Notification_SoundAndVibration_Messages":
            specialType = .normal
        case "Lark_Core_Notification_SoundAndVibration_Mentions":
            specialType = .at
        case "Lark_Core_Notification_SoundAndVibration_Buzz":
            specialType = .urgent
        default:
            specialType = .normal
        }

        self.data = [.silence, .default, specialType, .chord, .aurora, .circles]

        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if self.avplayer?.isPlaying ?? false {
            self.avplayer?.stop()
        }

        self.avplayer = nil
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        /// 添加表格视图
        self.view.addSubview(self.tableView)
        self.view.backgroundColor = UIColor.ud.bgBody
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.data.count else { return UITableViewCell() }

        let cell = NotificationSoundSettingSelectCell(style: .default,
                                                      reuseIdentifier: NotificationSoundSettingSelectCell.lu.reuseIdentifier)

        let type = data[indexPath.row]

        let status: NotificationSoundSettingStatus = selectedType != type ? .normal : .selected

        if status == .selected {
            self.lastIndexPath = indexPath
        }
        let model = NotificationSoundSettingSelectModel(
            cellIdentifier: NotificationSoundSettingSelectCell.lu.reuseIdentifier,
            title: type.title,
            subTitle: "",
            status: status,
            selectedHandler: { [weak self, weak cell] in
                guard let self = self else { return }

                if let index = self.lastIndexPath,
                   let lastCell = self.tableView.cellForRow(at: index) as? NotificationSoundSettingSelectCell {
                    lastCell.status = .normal
                }
                self.lastIndexPath = indexPath
                cell?.status = .loading
                self.updateSelectedType(type)
            })

        cell.item = model
        return cell
    }

    // swiftlint:disable did_select_row_protection
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.lastIndexPath = indexPath
    }
    // swiftlint:enable did_select_row_protection

    private func updateSelectedType(_ type: NotificationSoundType) {

        self.avplayer?.stop()

        if let url = type.soundURL, let player = try? AVAudioPlayer(contentsOf: url) {
            self.avplayer = player
            player.play()
        }

        guard self.selectedType != type else {
            self.tableView.reloadData()
            return
        }

        var item = Basic_V1_NotificationSoundSetting.NotificationSoundSettingItem()
        item.key = key
        item.value = type.soundName
        self.userGeneralSettings
            .updateNotificationStatus(items: [item])
            .subscribe(onNext: { [weak self] success in
                if success {
                    self?.selectedType = type
                }
                self?.tableView.reloadData()
            }, onError: { [weak self] (_) in
                self?.tableView.reloadData()
            }).disposed(by: self.disposeBag)
    }

    /// 创建表格视图
    private func createTableView() -> UITableView {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 16)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.estimatedRowHeight = 68
        tableView.estimatedSectionFooterHeight = 10
        tableView.estimatedSectionHeaderHeight = 10
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        registerTableViewCells(tableView)
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }

    private func registerTableViewCells(_ tableView: UITableView) {
        tableView.lu.register(cellSelf: NotificationSoundSettingSelectCell.self)
    }
}
