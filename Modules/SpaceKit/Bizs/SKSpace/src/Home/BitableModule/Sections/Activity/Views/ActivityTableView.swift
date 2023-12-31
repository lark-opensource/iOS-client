//
//  ActivityTableView.swift
//  SKSpace
//
//  Created by yinyuan on 2023/4/18.
//

import UIKit
import EENavigator
import UniverseDesignToast
import SKResource
import SKCommon
import SKFoundation
import LarkContainer

class ActivityTableView: UITableView {
    private var homePageData: [HomePageData] = []
    private var selectedItem: HomePageData?
    weak var cellDelegate: ActivityCellDelegate?
    private let context: BaseHomeContext
    
    init(context: BaseHomeContext) {
        self.context = context
        super.init(frame: .zero, style: .plain)
        
        self.separatorStyle = .none
        self.backgroundColor = .clear
        self.register(ActivityTableViewCell.self, forCellReuseIdentifier: ActivityTableViewCell.reuseIdentifier)
        self.dataSource = self
        self.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(data: [HomePageData], delegate: ActivityCellDelegate? = nil, selectedItem: HomePageData? = nil) {
        self.homePageData = data
        self.cellDelegate = delegate
        self.selectedItem = selectedItem
        if self.selectedItem != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) { [weak self] in
                self?.selectedItem = nil
            }
        }
        reloadData()
    }
}

extension ActivityTableView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return homePageData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ActivityTableViewCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? ActivityTableViewCell {
            let data = homePageData[indexPath.row]
            func isSameItem(_ a: HomePageData?, _ b: HomePageData?) -> Bool {
                guard let a = a, let b = b else {
                    return false
                }
                switch a.messageType {
                case .card:
                    return a.cardInfo?.chatID == b.cardInfo?.chatID &&  a.cardInfo?.chatID.isEmpty == false
                    && a.cardInfo?.position == b.cardInfo?.position &&  a.cardInfo?.position != nil
                case .notice:
                    return a.noticeInfo?.noticeID == b.noticeInfo?.noticeID && a.noticeInfo?.noticeID.isEmpty == false
                case .teamMessage:
                    return a.messageType == b.messageType
                }
            }
            cell.update(data: data, delegate: cellDelegate, showHighlighted: isSameItem(data, selectedItem))
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < homePageData.count else {
            return
        }
        let data = homePageData[indexPath.row]
        if data.noticeInfo?.noticeStatus == .COMMENT_DELETE, let view = self.window {
            // 评论已被删除
            UDToast.showWarning(with: BundleI18n.SKResource.LarkCCM_Doc_Feed_Comment_Delete, on: view)
        } else if let url = data.noticeInfo?.linkURL, let view = self.window {
            context.userResolver.navigator.push(
                url,
                context: [
                    SKEntryBody.fromKey: data.noticeInfo?.noticeType == .BEAR_MENTION_AT_IN_CONTENT ? FileListStatistics.Module.baseHomeLarkTabMention : FileListStatistics.Module.baseHomeLarkTabComment
                ],
                from: view)
        } else if let url = data.cardInfo?.linkURL, let view = self.window {
            context.userResolver.navigator.push(url, from: view)
        }
        var params: [String: Any] = [
            "click": "notice_card_click",
            "current_sub_view": "activity_all"
        ]
        params["notice_id"] = data.noticeInfo?.noticeID
        params["file_id"] = data.noticeInfo?.sourceToken?.encryptToken
        params["notice_card_type"] = data.tarckTypeStr
        DocsTracker.reportBitableHomePageEvent(enumEvent: .baseHomepageActivityClick, parameters: params, context: context)
    }
}
