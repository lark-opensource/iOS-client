//
//  MinutesSpeakerDetailModule.swift
//  Minutes
//
//  Created by ByteDance on 2023/9/6.
//

import UIKit
import Foundation
import RoundedHUD
import LarkUIKit
import EENavigator
import MinutesFoundation
import MinutesNetwork
import UniverseDesignToast
import UniverseDesignColor
import LarkContainer
import LarkAccountInterface
import LarkSetting
import UniverseDesignIcon

struct SpeakerFragment {
    let name: String
    let time: String
    let timeline: (startTime: Int, stopTime: Int)
    var isSelected: Bool
}

class MinutesSpeakerDetailModule: UIView {

    var items: [SpeakerFragment] = []
    var curPlayIndex: Int = 0
    let player: MinutesVideoPlayer
    let tracker: MinutesTracker

    func configure(with timeline: MinutesSpeakerTimelineInfo?, index: Int?) {
        guard let timeline = timeline else { return }
        items = timeline.speakerTimeline.enumerated().map { (idx, s) in
            let start = (TimeInterval(s.startTime) / 1000).autoFormat() ?? ""
            let stop = (TimeInterval(s.stopTime) / 1000).autoFormat() ?? ""
            return SpeakerFragment(name: "\(BundleI18n.Minutes.MMWeb_M_MeetingClipsShort_Tab) \(idx+1)", time: "\(start)-\(stop)", timeline: s, isSelected: index == idx)
        }
        configureHeader(with: timeline.participant)
        reload()
    }

    var header: MinutesSpeakerDetailHeaderView?
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(MinutesSpeakerDetailCell.self, forCellReuseIdentifier: MinutesSpeakerDetailCell.description())
        return tableView
    }()

    private lazy var navi: MinutesSpeakerNavigationView = {
        let navi = MinutesSpeakerNavigationView()
        navi.closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        return navi
    }()

    var closeAction: (() -> Void)?

    @objc func close() {
        closeAction?()
    }

    var openProfileBlock: ((String?) -> Void)?
    var select: ((Int) -> Void)?

    let userResolver: UserResolver

    init(player: MinutesVideoPlayer, resolver: UserResolver, minutes: Minutes) {
        self.player = player
        self.userResolver = resolver
        self.tracker = MinutesTracker(minutes: minutes)
        super.init(frame: .zero)

        player.listeners.addListener(self)
        
        addSubview(navi)
        addSubview(tableView)

        navi.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navi.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }


    func configureHeader(with participant: Participant) {
        guard let header = header else { return }
        header.iconView.setAvatarImage(with: participant.avatarURL)
        header.textLabel.text = participant.userName
        header.openProfileBlock = { [weak self] in
            if participant.userType == .lark {
                self?.openProfileBlock?(participant.userID)
            }
        }

        var height: CGFloat = header.textLabel.text?.boundingRect(with: CGSize(width: headerWidth - 24, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium)], context: nil).size.height ?? 0.0
        height = max(height, 32)
        var frame = header.frame
        frame.size.height = height + 20
        header.frame = frame
        tableView.tableHeaderView = header
    }

    var headerWidth: CGFloat = 0
    func configureHeader(with width: CGFloat) {
        headerWidth = width
        header = MinutesSpeakerDetailHeaderView(frame: CGRect(x: 0, y: 0, width: width, height: 0))
        tableView.tableHeaderView = header
    }

    func reload() {
        tableView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MinutesSpeakerDetailModule: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesSpeakerDetailCell.description(), for: indexPath)
                as? MinutesSpeakerDetailCell else { return UITableViewCell() }
        cell.fragmentInfo = items[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        select?(indexPath.row)

        items = items.enumerated().map { (idx, s) in
            return SpeakerFragment(name: s.name, time: s.time, timeline: s.timeline, isSelected: idx == indexPath.row)
        }
        let playTime: CGFloat = CGFloat(items[indexPath.row].timeline.startTime)
        handleSpeakerPlay(CGFloat(playTime / 1000))
        tracker.tracker(name: .playbarClipClick, params: ["click": "episode"])

        reload()
    }

    func handleSpeakerPlay(_ playTime: CGFloat) {
        player.seekVideoPlaybackTime(TimeInterval(playTime))
    }
}


extension MinutesSpeakerDetailModule: MinutesVideoPlayerListener {
    func videoEngineDidLoad() {

    }
    func videoEngineDidChangedStatus(status: PlayerStatusWrapper) {

    }
    func videoEngineDidChangedPlaybackTime(time: PlaybackTime) {
        let playTime = Int(time.time) * 1000

        var matchedIndex: Int?
        if let index = items.firstIndex(where: { playTime > $0.timeline.startTime && playTime < $0.timeline.stopTime } ) {
            matchedIndex = index
        } else if let index = items.firstIndex(where: { playTime <= $0.timeline.startTime } ) {
            matchedIndex = index
        }

        if let i = matchedIndex {
            if i != curPlayIndex {
                items = items.enumerated().map { (idx, s) in
                    return SpeakerFragment(name: s.name, time: s.time, timeline: s.timeline, isSelected: i == idx)
                }
                reload()
            }
            curPlayIndex = i
        }
    }
}
