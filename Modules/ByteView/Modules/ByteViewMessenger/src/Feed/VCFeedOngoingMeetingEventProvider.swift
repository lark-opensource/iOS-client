//
//  VCFeedOngoingMeetingEventProvider.swift
//  ByteViewMessenger
//
//  Created by lutingting on 2022/9/19.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewNetwork
import LarkOpenFeed
import LarkContainer

public final class VCFeedOngoingMeetingEventProvider: EventProvider {

    public var biz: EventBiz = .vc

    public var cellTypes: [String: UITableViewCell.Type] = [VCFeedOngoingMeetingCell.cellIdentifier: VCFeedOngoingMeetingCell.self]

    private var viewModel: VCFeedOngoingMeetingViewModel

    init(userResolver: UserResolver, dataCommand: PublishRelay<EventDataCommand>) {
        self.viewModel = VCFeedOngoingMeetingViewModel(userResolver: userResolver, dataCommand: dataCommand)
    }

    public func fillter(items: [EventItem]) {
        viewModel.remove(items: items)
    }

    // 当清空列表的时候，事件容器会调用
    public func fillterAllitems() {
        viewModel.removeAll()
    }

}
