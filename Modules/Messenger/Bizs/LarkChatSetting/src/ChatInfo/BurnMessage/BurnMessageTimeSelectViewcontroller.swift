//
//  BurnMessageTimeSelectViewcontroller.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/2/14.
//

import Foundation
import LarkUIKit
import UniverseDesignCheckBox
import FigmaKit
import LarkSDKInterface
import RxSwift
import LarkModel
import LarkCore
import UniverseDesignToast

public extension RestrictedModeMessageBurnTime {
    //关闭状态文案有差异，需要外部传入
    func description(closeStatusText: String) -> String {
        switch self {
        case .close:
            return closeStatusText
        case .time(let time):
            if time == Self.minutes_1 {
                return BundleI18n.LarkChatSetting.Lark_IM_MessageSelfDestruct_1min_Option
            } else if time == Self.hours_1 {
                return BundleI18n.LarkChatSetting.Lark_IM_MessageSelfDestruct_1hour_Option
            } else if time == Self.day_1 {
                return BundleI18n.LarkChatSetting.Lark_IM_MessageSelfDestruct_1day_Option
            } else if time == Self.week_1 {
                return BundleI18n.LarkChatSetting.Lark_IM_MessageSelfDestruct_1week_Option
            } else if time == Self.month_1 {
                return BundleI18n.LarkChatSetting.Lark_IM_MessageSelfDestruct_1month_Option
            }
        }
        return ""
    }
}

class TimeInfo {
    let value: RestrictedModeMessageBurnTime
    var isSelected: Bool = false
    init(_ value: RestrictedModeMessageBurnTime) {
        self.value = value
    }
}

class BurnMessageTimeSelectViewcontroller: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private lazy var tableView: InsetTableView = {
        let table = InsetTableView(frame: .zero)
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = UIColor.clear
        table.tableFooterView = UIView()
        return table
    }()

    private let naviBar: TitleNaviBar

    private let datas: [TimeInfo] = [TimeInfo(.close),
                                     TimeInfo(.time(RestrictedModeMessageBurnTime.minutes_1)),
                                     TimeInfo(.time(RestrictedModeMessageBurnTime.hours_1)),
                                     TimeInfo(.time(RestrictedModeMessageBurnTime.day_1)),
                                     TimeInfo(.time(RestrictedModeMessageBurnTime.week_1)),
                                     TimeInfo(.time(RestrictedModeMessageBurnTime.month_1))]
    private let disposeBag = DisposeBag()
    private let chatAPI: ChatAPI
    private let chatId: String
    private var updating: Bool = false
    init(selectedTime: RestrictedModeMessageBurnTime,
         chatId: String,
         chatAPI: ChatAPI) {
        self.naviBar = TitleNaviBar(titleString: BundleI18n.LarkChatSetting.Lark_IM_SelfDestructTimer_Hover)
        self.chatAPI = chatAPI
        self.chatId = chatId
        super.init(nibName: nil, bundle: nil)
        let selectTimeInfo = self.datas.first { timeInfo in
            return timeInfo.value == selectedTime
        }
        selectTimeInfo?.isSelected = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .none
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.isNavigationBarHidden = true
        self.view.addSubview(tableView)
        self.view.backgroundColor = UIColor.ud.bgFloatBase
        naviBar.addBackButton()
        naviBar.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(naviBar)
        naviBar.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
        }
        tableView.register(BurnMessageTimeSelectCell.self, forCellReuseIdentifier: "BurnMessageTimeSelectCell")
        tableView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(naviBar.snp.bottom).offset(16)
        }
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.backgroundColor = UIColor.clear
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BurnMessageTimeSelectCell", for: indexPath) as? BurnMessageTimeSelectCell else {
            return UITableViewCell(frame: .zero)
        }
        cell.update(info: self.datas[indexPath.row])
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedInfo = self.datas[indexPath.row]
        guard !selectedInfo.isSelected, !updating else {
            return
        }
        updating = true
        let status: Bool
        let aliveTime: Int64
        switch selectedInfo.value {
        case .close:
            status = false
            aliveTime = 0
        case .time(let time):
            status = true
            aliveTime = time
        }
        var setting: Chat.RestrictedModeSetting = Chat.RestrictedModeSetting()
        var timeSetting = Chat.RestrictedModeSetting.OnTimeDelMsgSetting()
        timeSetting.status = status
        timeSetting.aliveTime = aliveTime
        setting.onTimeDelMsgSetting = timeSetting
        let ob = self.chatAPI.updateChat(chatId: self.chatId,
                                restrictedModeSetting: setting)
        DelayLoadingObservableWraper
            .wraper(observable: ob, showLoadingIn: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.datas.first { info in
                    return info.isSelected
                }?.isSelected = false
                selectedInfo.isSelected = true
                self?.tableView.reloadData()
                self?.updating = false
            }, onError: { [weak self] error in
                self?.updating = false
                UDToast.showFailure(with: BundleI18n.LarkChatSetting.Lark_Legacy_ErrorMessageTip, on: self?.view ?? UIView(), error: error)
            }).disposed(by: self.disposeBag)
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: .zero)
        headerView.backgroundColor = UIColor.ud.bgFloatBase
        let title = UILabel(frame: .zero)
        title.textColor = UIColor.ud.textPlaceholder
        title.text = BundleI18n.LarkChatSetting.Lark_IM_WhenWillMsgSelfDestruct_Desc
        title.font = UIFont.systemFont(ofSize: 14)
        headerView.addSubview(title)
        title.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
}

private class BurnMessageTimeSelectCell: BaseTableViewCell {
    private let titleLabel: UILabel
    private let checkbox: UDCheckBox

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        titleLabel = UILabel(frame: .zero)
        checkbox = UDCheckBox(boxType: .list)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ud.bgBody
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        self.contentView.addSubview(checkbox)
        checkbox.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-19)
        }
        checkbox.isUserInteractionEnabled = false
        self.setupBackgroundViews(highlightOn: true)
    }

    func update(info: TimeInfo) {
        self.titleLabel.text = info.value.description(closeStatusText: BundleI18n.LarkChatSetting.Lark_IM_Closeit_Options)
        self.checkbox.isSelected = info.isSelected
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }
}
