//
//  FeedFloatMenuView.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/11/30.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import LarkOpenFeed

extension FeedFloatMenuView {
    enum Layout {
        static let cellHeight: CGFloat = 50.0
    }
}

protocol FloatMenuDelegate: AnyObject {
    func floatMenu(_ menuView: FeedFloatMenuView, select type: FloatMenuOptionType)
}

final class FeedFloatMenuView: UIView {
    weak var delegate: FloatMenuDelegate?

    weak var popoverVC: UIViewController?

    private let menuModule: BaseFeedFloatMenuModule

    /// 所有待展示MenuOption的集合：扫一扫、创建群组、创建文档、创建会议等
    private lazy var menuStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0.0
        return stackView
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    init(menuModule: BaseFeedFloatMenuModule) {
        self.menuModule = menuModule
        super.init(frame: .zero)

        self.setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        popoverVC?.preferredContentSize = self.bounds.size
    }

    private func setupViews() {
        backgroundColor = .clear
        self.addSubview(self.containerView)
        self.containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let model = FeedFloatMenuMetaModel()
        self.menuModule.handler(model: model)
        var lastCell: UIView?
        let items = self.menuModule.collectItems(model: model)
        let contentViews = items.map({ FeedFloatMenuOptionView(item: $0) })
        contentViews.forEach({ cell in
            addSubview(cell)
            cell.tapArea.addTarget(self, action: #selector(didClickCell(_:)), for: .touchUpInside)
            cell.snp.makeConstraints({ (make) in
                make.height.equalTo(Layout.cellHeight)
                make.leading.trailing.equalToSuperview()
                if let lastCell = lastCell {
                    make.top.equalTo(lastCell.snp.bottom)
                } else {
                    make.top.equalToSuperview()
                }
            })
            lastCell = cell
        })
        self.snp.makeConstraints { (make) in
            make.height.equalTo(CGFloat(contentViews.count) * Layout.cellHeight)
        }
    }

    public func didClick(_ type: FloatMenuOptionType) {
        self.menuModule.didClick(type)
        self.trackEvents(type)
    }

    private func trackEvents(_ type: FloatMenuOptionType) {
        switch type {
        case .scanQRCode:
            FeedTeaTrack.trackScan()
            FeedTracker.Plus.Click.Scan()
        case .newGroup:
            FeedTeaTrack.trackCreateNewGroup()
            FeedTracker.Plus.Click.CreateGroup()
        case .inviteMember:
            FeedTeaTrack.trackInviteMemberInFeedMenu()
        case .inviteExternal:
            FeedTracker.Plus.Click.InviteExternal()
        case .createDocs:
            FeedTracker.Plus.Click.CreateDocs()
        case .shareScreen:
            FeedTracker.Plus.Click.ShareScreen()
        case .newMeeting:
            FeedTracker.Plus.Click.NewMeeting()
        case .joinMeeting:
            FeedTracker.Plus.Click.JoinMeeting()
        default:
            break
        }
    }

    @objc
    private func didClickCell(_ sender: MenuHighlightControl) {
        if let view = sender.feedFloatMenuOptionView {
            delegate?.floatMenu(self, select: view.item.type)
        }
    }
}
