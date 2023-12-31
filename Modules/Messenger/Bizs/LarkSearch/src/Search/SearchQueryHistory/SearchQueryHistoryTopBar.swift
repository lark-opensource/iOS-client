//
//  SearchQueryHistoryTopBar.swift
//  LarkSearch
//
//  Created by SuPeng on 5/6/19.
//

import Foundation
import UIKit
import LarkMessengerInterface
import LarkFeatureSwitch

enum SearchDesignatedType: CaseIterable {
    case message, doc, wiki, topic, thread, chat, oncall, app, calendar, more

    var title: String {
        switch self {
        case .app:
            return BundleI18n.LarkSearch.Lark_Search_Apps
        case .message:
            return BundleI18n.LarkSearch.Lark_Search_TitleChatRecord
        case .doc:
            return BundleI18n.LarkSearch.Lark_Search_SpaceFragmentTitle
        case .oncall:
            return BundleI18n.LarkSearch.Lark_Search_HelpDesk
        case .wiki:
            return BundleI18n.LarkSearch.Lark_Search_Wiki
        case .chat:
            return BundleI18n.LarkSearch.Lark_Legacy_Group
        case .calendar:
            return BundleI18n.LarkSearch.Lark_Search_Calendar
        case .more:
            return BundleI18n.LarkSearch.Lark_Search_MoreContent
        case .topic:
            return BundleI18n.LarkSearch.Lark_Search_Posts
        case .thread:
            return BundleI18n.LarkSearch.Lark_Search_Channels
        }
    }

    var icon: UIImage {
        switch self {
        case .app:
            return Resources.app_history
        case .message:
            return Resources.message_history
        case .doc:
            return Resources.space_history
        case .oncall:
            return Resources.help_history
        case .wiki:
            return Resources.wiki_history
        case .chat:
            return Resources.chat_history
        case .calendar:
            return Resources.calendar_history
        case .more:
            return Resources.more_history
        case .topic:
            return Resources.topic_history
        case .thread:
            return Resources.thread_history
        }
    }

    // 埋点信息
    var trackInfo: String {
        switch self {
        case .app:
            return "apps"
        case .message:
            return "message"
        case .doc:
            return "space"
        case .oncall:
            return "helpdesk"
        case .wiki:
            return "wiki"
        case .chat:
            return "chat"
        case .calendar:
            return "calendar"
        case .more:
            return "more"
        case .topic:
            return "post"
        case .thread:
            return "channel"
        }
    }
}

protocol SearchQueryHistoryTopBarDelegate: AnyObject {
    func topBar(_ topBar: SearchQueryHistoryTopBar, didSelect type: SearchDesignatedType)
    func topBarDidSelectMore(_ topBar: SearchQueryHistoryTopBar)
}

final class SearchQueryHistoryTopBar: UIView {

    weak var delegate: SearchQueryHistoryTopBarDelegate?

    private let titleLabel = UILabel()
    private let buttons: [SearchQueryHistoryTopBarButton]

    init(showHelpDesk: Bool,
         showApp: Bool,
         showWiki: Bool,
         showChat: Bool,
         showCalendar: Bool,
         showThread: Bool,
         showTopic: Bool,
         showMoreButton: Bool) {
        self.buttons = SearchDesignatedType
            .allCases
            .filter({ (type) -> Bool in
                var result = true
                Feature.on(.searchFilter).apply(on: {}, off: {
                    switch type {
                    case .message, .doc, .wiki, .calendar, .app:
                        break
                    default:
                        result = false
                    }
                })
                return result
            })
            .compactMap { (type) -> SearchQueryHistoryTopBarButton? in
                if !showHelpDesk, type == .oncall {
                    return nil
                } else if !showWiki, type == .wiki {
                    return nil
                } else if !showChat, type == .chat {
                    return nil
                } else if !showCalendar, type == .calendar {
                    return nil
                } else if !showApp, type == .app {
                    return nil
                } else if !showMoreButton, type == .more {
                    return nil
                } else if !showTopic, type == .topic {
                    return nil
                } else if !showThread, type == .thread {
                    return nil
                }
                return SearchQueryHistoryTopBarButton(type: type)
            }
        super.init(frame: .zero)

        backgroundColor = UIColor.ud.bgBody

        titleLabel.text = BundleI18n.LarkSearch.Lark_Search_SearchByType
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(20)
        }

        buttons.forEach { (button) in
            button.topBarButtonDidClick = { [weak self] type in
                guard let self = self else { return }
                if type == .more {
                    self.delegate?.topBarDidSelectMore(self)
                } else {
                    self.delegate?.topBar(self, didSelect: type)
                }
            }
        }

        let countPerRow = 4
        buttons.enumerated().forEach { (index, button) in
            addSubview(button)
            let currentRow = ceil(Double((index + 1)) / Double(countPerRow)) // start by 1
            button.snp.makeConstraints { (make) in
                make.height.equalTo(68)
                make.width.equalToSuperview().multipliedBy(CGFloat(1) / CGFloat(countPerRow))
                make.top.equalTo(titleLabel.snp.bottom).offset(10 + (currentRow - 1) * 68)
                if index % countPerRow == 0 {
                    make.left.equalToSuperview()
                } else {
                    let preButton = buttons[index - 1]
                    make.left.equalTo(preButton.snp.right)
                }
                if index == buttons.count - 1 {
                    make.bottom.equalToSuperview()
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class SearchQueryHistoryTopBarButton: UIControl {
    var topBarButtonDidClick: ((SearchDesignatedType) -> Void)?

    private let type: SearchDesignatedType
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()

    init(type: SearchDesignatedType) {
        self.type = type

        super.init(frame: .zero)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = type.icon
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.top.equalTo(10)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }

        titleLabel.text = type.title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconImageView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(4)
            make.right.lessThanOrEqualToSuperview().offset(-4)
        }

        addTarget(self, action: #selector(didClick), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didClick() {
        topBarButtonDidClick?(type)
    }
}
