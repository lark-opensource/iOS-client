//
//  BaseMemberInviteContainer.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/11.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import LarkMessengerInterface
import LarkFeatureGating

class BaseInviteMemberContainer: UIControl {
    let viewModel: MemberInviteViewModel
    var fieldListType: FieldListType {
        fatalError("fieldListType must be override")
    }

    init(viewModel: MemberInviteViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        layoutPageSubviews()
        bindViewModel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var tableView: UITableView = {
        let tableView: FieldListView = FieldListView(fieldListType: self.fieldListType)
        tableView.dataSource = viewModel
        tableView.delegate = viewModel
        if fieldListType == .email {
            tableView.register(EmailEditFieldCell.self, forCellReuseIdentifier: NSStringFromClass(EmailEditFieldCell.self))
            tableView.register(EmailFailedFieldCell.self, forCellReuseIdentifier: NSStringFromClass(EmailFailedFieldCell.self))
        } else {
            tableView.register(PhoneEditFieldCell.self, forCellReuseIdentifier: NSStringFromClass(PhoneEditFieldCell.self))
            tableView.register(PhoneFailedFieldCell.self, forCellReuseIdentifier: NSStringFromClass(PhoneFailedFieldCell.self))
        }
        tableView.tableFooterView = footerView

        let addResignTapHandler: ((UIView) -> Void) = { [unowned self] (view: UIView) in
            view.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer()
            tap.rx.event.subscribe(onNext: { [unowned self] (_) in
                self.viewModel.resignCurrentResponder()
            })
            .disposed(by: self.viewModel.disposeBag)
            view.addGestureRecognizer(tap)
        }
        addResignTapHandler(tableView)
        addResignTapHandler(footerView)

        return tableView
    }()

    private lazy var footerView: InviteOperationView = {
        let footerView = InviteOperationView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 148))
        footerView.importFromContactsTapHandler = { [unowned self] in
            Tracer.trackAddMemberContactBatchInviteClick(scenes: self.fieldListType == .phone ? .addByPhone : .addByEmail)
            self.viewModel.pushToContactImportSubject.onNext(())
        }
        footerView.inviteButtonTapHandler = { [unowned self] () in
            self.setUserEnabled(false)
            self.viewModel.startInviteSubject.onNext(())
            Tracer.trackAddMemberSendClick(source: self.viewModel.sourceScenes)
        }
        return footerView
    }()
}

private extension BaseInviteMemberContainer {
    func bindViewModel() {
        viewModel.inviteRequestOnCompletedSubject.asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] (_) in
                self?.setUserEnabled(true)
                (self?.tableView.tableFooterView as? InviteOperationView)?.inviteButton.setLoading(false)
            })
            .disposed(by: self.viewModel.disposeBag)

        viewModel.reloadFieldSubject.asDriver(onErrorJustReturn: (.email, true, nil))
            .drive(onNext: { [weak self] (reloadContext) in
                guard let `self` = self else { return }
                guard reloadContext.allReload || reloadContext.reloadPath != nil else { return }
                if self.fieldListType == reloadContext.type {
                    if reloadContext.allReload {
                        self.tableView.reloadData()
                    } else {
                        self.tableView.beginUpdates()
                        reloadContext.reloadPath.flatMap { self.tableView.reloadRows(at: [$0], with: .fade) }
                        self.tableView.endUpdates()
                    }
                }
            }).disposed(by: self.viewModel.disposeBag)

        viewModel.activeSpecifiedRowSubject.asDriver(onErrorJustReturn: (.email, IndexPath(row: 0, section: 0)))
            .drive(onNext: { [weak self] (activeContext) in
                guard let `self` = self else { return }
                if self.fieldListType == activeContext.type {
                    if let cell: FieldCellAbstractable = self.tableView.cellForRow(at: activeContext.activePath) as? FieldCellAbstractable {
                        cell.beActive()
                    }
                }
            })
            .disposed(by: self.viewModel.disposeBag)

        let footerView: InviteOperationView? = tableView.tableFooterView as? InviteOperationView
        if let footer = footerView {
            viewModel.inviteButtonEnableSubject.asDriver(onErrorJustReturn: (.email, false))
                .filter { [weak self] in $0.type == self?.fieldListType }
                .map { $0.buttonEnable }
                .drive(footer.buttonEnableBinder)
                .disposed(by: viewModel.disposeBag)
        }
    }

    func setUserEnabled(_ enabled: Bool) {
        isEnabled = enabled
        alpha = enabled ? 1.0 : 0.5
    }

    func layoutPageSubviews() {
        addSubview(tableView)

        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

protocol FieldListTypeable {
    var fieldListType: FieldListType { get }
}

private final class FieldListView: UITableView, FieldListTypeable {
    let fieldListType: FieldListType
    init(fieldListType: FieldListType) {
        self.fieldListType = fieldListType
        super.init(frame: CGRect.zero, style: .plain)
        bounces = true
        contentInset.top = 22
        contentInset.bottom = 5
        separatorStyle = .none
        estimatedRowHeight = 0
        estimatedSectionHeaderHeight = 0
        estimatedSectionFooterHeight = 0
        backgroundColor = UIColor.ud.bgBase
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
