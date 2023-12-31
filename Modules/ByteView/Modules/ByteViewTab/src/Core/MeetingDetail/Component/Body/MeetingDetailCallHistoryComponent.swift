//
//  MeetingDetailCallHistoryComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/25.
//

import Foundation
import RxSwift
import ByteViewNetwork
import ByteViewTracker

class MeetingDetailCallHistoryComponent: MeetingDetailComponent {

    private static let cellID = "MeetingCallsCell"

    lazy var tableView: FitContentTableView = {
        let tableView = FitContentTableView(frame: .zero, style: .plain)
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.register(MeetingCallsCell.self, forCellReuseIdentifier: Self.cellID)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.ud.bgFloat
        return tableView
    }()

    var items: [HistoryInfo] = []
    var groupedItems: [MeetingCalls] = []
    var titles: [[CallDescription]] = []

    required init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupViews() {
        super.setupViews()
        backgroundColor = UIColor.ud.bgFloat
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(Util.rootTraitCollection?.horizontalSizeClass == .regular ? 28 : 16)
        }
    }

    override func updateLayout() {
        super.updateLayout()
        tableView.snp.updateConstraints { (make) in
            make.left.right.equalToSuperview().inset(Util.rootTraitCollection?.horizontalSizeClass == .regular ? 28 : 16)
        }
    }

    override func bindViewModel(viewModel: MeetingDetailViewModel) {
        super.bindViewModel(viewModel: viewModel)
        viewModel.commonInfo.addObserver(self)
        viewModel.historyInfos.addObserver(self)
    }

    override var shouldShow: Bool {
        items.isEmpty == false
    }

    override func updateViews() {
        super.updateViews()
        groupedItems = groupByDays(items)

        if groupedItems.isEmpty {
            titles = []
            tableView.reloadData()
            return
        }

        guard let viewModel = self.viewModel,
              let meetingID = viewModel.meetingID,
              let meetingType = viewModel.commonInfo.value?.meetingType else { return }

        let httpClient = viewModel.httpClient
        var newTitles: [[CallDescription]] = []
        let maxLoop1 = groupedItems.count - 1

        for (loop1, groupedCalls) in groupedItems.enumerated() {
            var descriptions: [Int: CallDescription] = [:]
            let maxLoop2 = groupedCalls.calls.count
            var counterIn: Int = 0

            for (loop2, call) in groupedCalls.calls.enumerated() {
                let userID = call.interacterUserID
                call.stateDescription(for: meetingType, meetingID: meetingID, httpClient: httpClient) { [weak self] pair in
                    let description = CallDescription(content: pair.0, highlightRange: pair.1, userID: userID)
                    descriptions[loop2] = description
                    counterIn += 1
                    if counterIn == maxLoop2 {
                        let sortedDict = descriptions.sorted { $0.0 < $1.0}
                        var outDescriptions: [CallDescription] = []
                        for element in sortedDict {
                            outDescriptions.append(element.1)
                        }
                        newTitles.append(outDescriptions)
                        if loop1 == maxLoop1 {
                            self?.titles = newTitles
                            self?.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }

    private func groupByDays(_ historyInfos: [HistoryInfo]) -> [MeetingCalls] {
        guard !historyInfos.isEmpty else { return [] }

        var result: [MeetingCalls] = []
        var last = 0
        let calendar = Calendar.current
        let sorted = historyInfos.sorted { (info1, info2) -> Bool in
            return info1.actionTime.compare(info2.actionTime) == .orderedDescending
        }
        for i in 1..<sorted.count {
            if !calendar.isDate(sorted[last].actionTime, inSameDayAs: sorted[i].actionTime) {
                result.append(MeetingCalls(title: formatDate(sorted[last].actionTime), calls: Array(sorted[last..<i])))
                last = i
            }
        }
        result.append(MeetingCalls(title: formatDate(sorted[last].actionTime), calls: Array(sorted[last...])))
        return result
    }

    private func formatDate(_ date: Date) -> String {
        DateUtil.formatDate(date.timeIntervalSince1970)
    }
}

extension MeetingDetailCallHistoryComponent: MeetingDetailCommonInfoObserver, MeetingDetailHistoryInfoObserver {
    func didReceive(data: TabHistoryCommonInfo) {
        updateViews()
    }

    func didReceive(data: [HistoryInfo]) {
        items = data
        updateViews()
    }
}

extension MeetingDetailCallHistoryComponent: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        if titles.count != groupedItems.count {
            Logger.ui.error("Mismatch between titles.count \(titles.count) and groupedItem.count: \(groupedItems.count)")
            return min(titles.count, groupedItems.count)
        }
        return groupedItems.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if titles[section].count != groupedItems[section].calls.count {
            Logger.ui.error("Mismatch between titles[\(section)].count \(titles.count) and groupedItem[\(section)].calls.count: \(groupedItems[section].calls.count)")
            return min(titles[section].count, groupedItems[section].calls.count)
        }
        return groupedItems[section].calls.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellID, for: indexPath) as? MeetingCallsCell,
              let commonInfo = viewModel?.commonInfo.value else {
            return UITableViewCell()
        }
        cell.config(with: groupedItems[indexPath.section].calls[indexPath.row],
                    meetingType: commonInfo.meetingType,
                    title: titles[indexPath.section][indexPath.row],
                    meetingInfo: commonInfo)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        let label = UILabel()
        label.attributedText = NSAttributedString(string: groupedItems[section].title, config: .boldBodyAssist, textColor: UIColor.ud.textPlaceholder)
        view.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(2)
            make.left.right.equalToSuperview()
            make.height.equalTo(20)
        }
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .ud.bgFloat
        return section == groupedItems.count - 1 ? v : UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == groupedItems.count - 1 ? 2 : 16
    }
}

struct MeetingCalls {
    let title: String
    let calls: [HistoryInfo]
}

struct CallDescription {
    let content: String
    let highlightRange: NSRange?
    let userID: String?
}

extension HistoryInfo {
    func stateDescription(for meetingType: MeetingType, meetingID: String, httpClient: HttpClient, completion: (((String, NSRange?)) -> Void)? = nil) {
        switch historyInfoType {
        case .videoConference, .ipPhone, .unknown:
            videoConferenceStateDescription(for: meetingType, meetingID: meetingID, httpClient: httpClient, completion: completion)
        case .enterprisePhone:
            completion?(enterprisePhoneStateDescription(for: meetingType, meetingID: meetingID))
        case .recruitment:
            completion?(recruitmentStateDescription(for: meetingType, meetingID: meetingID))
        }
    }

    private func enterprisePhoneStateDescription(for meetingType: MeetingType, meetingID: String) -> (String, NSRange?) {
        switch historyType {
        case .historyCall:
            if callStatus == .callCanceled {
                let description: String
                switch cancelReason {
                case .cancel:
                    description = I18n.View_G_OfficePhoneHasCanceled_HistoryRecord // 已取消
                case .timeout:
                    description = I18n.View_G_OfficePhoneUnanswered_HistoryRecord // 未接
                case .refuse:
                    description = I18n.View_G_DeclineOfficeCall
                }
                return (description, nil)
            } else {
                return (I18n.View_G_OfficePhoneCallOut_HistoryRecord, nil)
            }
        case .historyBeCalled:
            guard meetingType == .call else {
                return ("", nil)
            }
            if callStatus == .callCanceled {
                let description: String
                switch cancelReason {
                case .cancel:
                    description = I18n.View_G_OfficePhoneHasCanceled_HistoryRecord // 已取消
                case .timeout:
                    description = I18n.View_G_OfficePhoneUnanswered_HistoryRecord // 未接
                case .refuse:
                    description = I18n.View_G_DeclineOfficeCall
                }
                return (description, nil)
            } else {
                return (I18n.View_G_OfficePhoneCallIn_HistoryRecord, nil)
            }
        default:
            return ("", nil)
        }
    }

    private func recruitmentStateDescription(for meetingType: MeetingType, meetingID: String) -> (String, NSRange?) {
        switch historyType {
        case .historyCall:
            if callStatus == .callCanceled {
                let description: String
                switch cancelReason {
                case .cancel:
                    description = I18n.View_G_CancelRecruitCall // 已取消
                case .timeout:
                    description = I18n.View_G_MissRecruitCall // 未接
                case .refuse:
                    description = I18n.View_G_DeclineRecruitCall
                }
                return (description, nil)
            } else {
                return (I18n.View_G_OutRecruitCall, nil)
            }
        case .historyBeCalled:
            guard meetingType == .call else {
                return ("", nil)
            }
            if callStatus == .callCanceled {
                let description: String
                switch cancelReason {
                case .cancel:
                    description = I18n.View_G_CancelRecruitCall // 已取消
                case .timeout:
                    description = I18n.View_G_MissRecruitCall // 未接
                case .refuse:
                    description = I18n.View_G_DeclineRecruitCall
                }
                return (description, nil)
            } else {
                return (I18n.View_G_InRecruitCall, nil)
            }
        default:
            return ("", nil)
        }
    }

    private func videoConferenceStateDescription(for meetingType: MeetingType, meetingID: String, httpClient: HttpClient, completion: (((String, NSRange?)) -> Void)? = nil) {
        switch historyType {
        case .historyJoin:
            completion?((I18n.View_G_JoinedMeeting, nil))
        case .historyCall:
            if callStatus == .callCanceled {
                completion?(((I18n.View_G_CallCanceledBySelf, nil)))
            } else {
                completion?(((I18n.View_G_Outgoing, nil)))
            }
        case .historyBeCalled:
            let id = ParticipantId(id: interacterUserID, type: interacterUserType)
            httpClient.participantService.participantInfo(pid: id, meetingId: meetingID) { user in
                completion?(videoConferenceBeCalledDescription(user: user, type: meetingType))
            }
        case .historyLeave:
            completion?((I18n.View_G_LeftMeeting, nil))
        default:
            completion?(("", nil))
        }
    }

    private func videoConferenceBeCalledDescription(user: ParticipantUserInfo?, type: MeetingType) -> (String, NSRange?) {
        guard let user = user else { return ("", nil) }
        if callStatus == .callCanceled {
            if type == .call {
                return (I18n.View_G_Missed, nil)
            } else {
                let content = I18n.View_G_MissedCallFromName(user.name)
                let range = (content as NSString).range(of: user.name)
                return (content, range)
            }
        } else {
            if type == .call {
                return (I18n.View_G_Incoming, nil)
            } else {
                let content = I18n.View_G_IncomingCallFromNameHistory(user.name)
                let range = (content as NSString).range(of: user.name)
                return (content, range)
            }
        }
    }

    func shouldShowDurationLabel(for meetingType: MeetingType, meetingInfo: TabHistoryCommonInfo) -> Bool {
        return meetingType == .call &&
            [.historyCall, .historyBeCalled].contains(historyType) &&
            meetingInfo.meetingStatus == .meetingEnd &&
            callStatus == .callAccepted
    }

    var actionTime: Date {
        let timeMS: Int64
        switch historyType {
        case .historyJoin: timeMS = joinTime
        case .historyCall: timeMS = callStartTime
        case .historyBeCalled: timeMS = callStartTime
        case .historyLeave: timeMS = leaveTime
        default: timeMS = 0
        }
        return Date(timeIntervalSince1970: TimeInterval(timeMS))
    }
}
