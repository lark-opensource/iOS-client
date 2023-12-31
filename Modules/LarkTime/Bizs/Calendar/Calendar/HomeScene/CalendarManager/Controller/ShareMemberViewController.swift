//
//  ShareMemberViewController.swift
//  Calendar
//
//  Created by heng zhu on 2019/3/23.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import SnapKit

protocol ShareMemberViewModel: Avatar {
    var isGroup: Bool { get }
    var avatarKey: String { get }
    var userName: String { get }
    var localizedName: String { get }
    var accessRole: CalendarModel.AccessRole { get }
    var isUserCountVisible: Bool { get }
    var groupMemberCount: Int { get }
}

extension ShareMemberViewController: CalendarAccessViewDelegate {
    func didSelect(index: Int) {
        let map = roleMap.filter { (arg0) -> Bool in
            let (_, value) = arg0
            return value == index
        }
        accessView.select(atIndex: index)
        self.selectAccess(map.keys.first ?? .owner)
        self.navigationController?.popViewController(animated: true)
    }
}

final class ShareMemberViewController: CalendarController {

    private let accessView: CalendarAccessView
    private var headerView: ShareMemberHeaderView
    private let deleteView = OperationButton(model: OperationButton.getData(with: .deleteMember))

    private var roleMap: [AccessRole: Int] = [.owner: 0, .writer: 1, .reader: 2, .freeBusyReader: 3]

    private let deleteMember: () -> Void
    private let selectAccess: (_ accessRole: AccessRole) -> Void
    init(member: ShareMemberViewModel, deleteMember: @escaping () -> Void, selectAccess: @escaping (_ access: AccessRole) -> Void) {
        self.headerView = ShareMemberHeaderView(name: member.userName,
                                                group: member.localizedName,
                                                isUserCountVisible: member.isUserCountVisible,
                                                memberCount: member.groupMemberCount,
                                                avatar: member)
        self.selectAccess = selectAccess
        self.deleteMember = deleteMember
        let ownerData = CalendarMemberAccessData(title: BundleI18n.Calendar.Calendar_Setting_Owner,
                                                 subTitle: BundleI18n.Calendar.Calendar_Setting_OwnersRight,
                                                 accessRole: .owner)
        let writerData = CalendarMemberAccessData(title: BundleI18n.Calendar.Calendar_Setting_Writer,
                                                  subTitle: BundleI18n.Calendar.Calendar_Setting_WritersRight,
                                                  accessRole: .writer)
        let readerData = CalendarMemberAccessData(title: BundleI18n.Calendar.Calendar_Setting_Reader,
                                                  subTitle: BundleI18n.Calendar.Calendar_Setting_ReaderRight,
                                                  accessRole: .reader)
        let freeBusyData = CalendarMemberAccessData(title: BundleI18n.Calendar.Calendar_Setting_FreebusyReader,
                                                    subTitle: BundleI18n.Calendar.Calendar_Setting_FreebusyReaderRight,
                                                    accessRole: .freeBusyReader)
        let dataSource = member.isGroup ? [writerData, readerData, freeBusyData] : [ownerData, writerData, readerData, freeBusyData]
        if member.isGroup {
            roleMap = [.writer: 0, .reader: 1, .freeBusyReader: 2]
        }
        let selectIndex = roleMap[member.accessRole] ?? 0
        accessView = CalendarAccessView(dataSource: dataSource, selectIndex: selectIndex, withBottomBorder: true)
        super.init(nibName: nil, bundle: nil)
        accessView.delegate = self
        deleteView.addTarget(self, action: #selector(deleteTaped), for: .touchUpInside)
    }

    @objc
    private func deleteTaped() {
        self.deleteMember()
        self.navigationController?.popViewController(animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.Calendar.Calendar_Setting_SharingMembers
        self.view.backgroundColor = UIColor.ud.bgBase
        addBackItem()

        layout(header: headerView)
        layout(warpper: accessView, upItem: headerView.snp.bottom)
        layout(delete: deleteView, upItem: accessView.snp.bottom)
    }

    private func layout(header: UIView) {
        view.addSubview(header)
        header.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
        }
    }

    private func layout(warpper: UIView, upItem: ConstraintItem) {
        view.addSubview(warpper)
        warpper.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(upItem).offset(8)
        }
    }

    private func layout(delete: UIView, upItem: ConstraintItem) {
        view.addSubview(delete)
        delete.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(upItem).offset(8)
        }
    }
}
