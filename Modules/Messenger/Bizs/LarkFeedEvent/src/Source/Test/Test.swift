//
//  Test.swift
//  LarkFeedEvent
//
//  Created by xiaruzhen on 2022/10/9.
//

import UIKit
import Foundation
import LarkOpenFeed
import LarkTag
import RxSwift
import RxCocoa

// Mock 数据
struct VCEventItem: EventItem, EventFeedHeaderViewItem, EventListCellItem {
    var tagItems: [LarkTag.Tag] = []
    let biz: EventBiz = .vc
    let id: String
    var position: Int
    func tap() {}

    // feed header 使用
    var icon: UIImage { Resources.event_close }
    var status: String { "ABC" }
    var title: String { "123" }
    var tags: [LarkTag.TagType] { [.public] }

    // cell 重用标识符。eventList使用
    var reuseId: String { "VCEventItemCell" }
}

final class VCEventItemCell: UITableViewCell, EventItemCell {
    var item: EventItem?
    let label = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.R50
        label.numberOfLines = 0
        self.contentView.addSubview(label)
        label.text = "test test test test test test test test test test test test test test test test test"
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class VCEventProvider: EventProvider {
    public var biz: EventBiz = .vc
    public var cellTypes: [String: UITableViewCell.Type] { ["VCEventItemCell": VCEventItemCell.self] }
    let data: PublishRelay<EventDataCommand>
    public init(data: PublishRelay<EventDataCommand>) {
        self.data = data
//        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
//            DispatchQueue.global().async {
//                let randomNumber = Int(arc4random()) % 1000
//                if arc4random() % 2 == 0 {
//                    let item = VCEventItem(id: "\(randomNumber)", position: Int(randomNumber))
//                    let item1 = VCEventItem(id: "\(randomNumber + 1)", position: Int(randomNumber + 1))
//                    data.accept(.insertOrUpdate([item.id: item, item1.id: item1]))
//                } else {
//                    data.accept(.remove(["\(randomNumber)"]))
//                }
//            }
//        }
        let randomNumber = Int.random(in: 0...999)
        let item = VCEventItem(id: "\(randomNumber)", position: Int(randomNumber))
//        let item1 = VCEventItem(id: "\(randomNumber + 1)", position: Int(randomNumber + 1))
        data.accept(.insertOrUpdate([item.id: item]))
        data.accept(.remove(["\(randomNumber)", "\(randomNumber)"]))
    }
    public func fillter(items: [EventItem]) {}
    public func fillterAllitems() {}
}
