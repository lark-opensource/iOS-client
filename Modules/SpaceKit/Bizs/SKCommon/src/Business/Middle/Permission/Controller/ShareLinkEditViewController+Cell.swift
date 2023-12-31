//
//  ShareLinkEditViewController+Cell.swift
//  SpaceKit
//
//  Created by liweiye on 2020/6/11.
//

import Foundation
import SKFoundation
import RxSwift
import UniverseDesignDialog
import SKResource

protocol PasswordTableViewCellModel {
    var cellType: PasswordTableViewCellType { get }
}

enum PasswordTableViewCellType {
    case passwordSwitch
    case passwordDisplay
}

extension ShareLinkEditViewController {
    
    func makeShareLinkSettingCell(indexPath: IndexPath) -> SKGroupTableViewCell {
        let rows = self.tableView(self.tableView, numberOfRowsInSection: indexPath.section)
        let row = indexPath.row
        guard row >= 0, row < editLinkInfoDataSource.count else {
            DocsLogger.error("row: \(row) out of bounds! editLinkInfoDataSource.count: \(editLinkInfoDataSource.count)")
            spaceAssertionFailure("row out of bounds!")
            return SKGroupTableViewCell()
        }
        let model = editLinkInfoDataSource[row]
        if let dataModel = model as? EditLinkInfo {
            let cell: LinkEditChoiceCell
            if let c = (tableView.dequeueReusableCell(withIdentifier: LinkEditChoiceCell.reuseIdentifier) as? LinkEditChoiceCell) {
                cell = c
            } else {
                cell = LinkEditChoiceCell(style: .subtitle, reuseIdentifier: LinkEditChoiceCell.reuseIdentifier)
            }
            cell.config(info: dataModel)
            cell.containerView.docs.addHover(with: UIColor.ud.fillHover, disposeBag: disposeBag)
            cell.update(SKGroupViewPosition.converToPisition(rows: rows, indexPath: indexPath))
            return cell
        } else if let model = model as? PasswordSettingCellViewModel {
            let cell = ShareLinkPasswordSettingCell()
            cell.config(rightLabelText: model.rightLabelContent)
            cell.containerView.docs.addHover(with: UIColor.ud.fillHover, disposeBag: disposeBag)
            cell.update(SKGroupViewPosition.converToPisition(rows: rows, indexPath: indexPath))
            return cell
        } else {
            DocsLogger.error("cell type wrong!")
            return SKGroupTableViewCell()
        }
    }
    
    func makeSearchSettingCell(indexPath: IndexPath) -> SKGroupTableViewCell {
        let rows = self.tableView(self.tableView, numberOfRowsInSection: indexPath.section)
        let row = indexPath.row
        guard row >= 0, row < searchSettingDataSource.count else {
            DocsLogger.error("row: \(row) out of bounds! searchSettingDataSource.count: \(searchSettingDataSource.count)")
            spaceAssertionFailure("row out of bounds!")
            return SKGroupTableViewCell()
        }
        let model = searchSettingDataSource[row]
        let cell: SearchSettingCell
        if let c = (tableView.dequeueReusableCell(withIdentifier: SearchSettingCell.reuseIdentifier) as? SearchSettingCell) {
            cell = c
        } else {
            cell = SearchSettingCell(style: .subtitle, reuseIdentifier: SearchSettingCell.reuseIdentifier)
        }
        cell.config(info: model)
        cell.tipsCallBack = { [weak self] in
            let dialog = UDDialog()
            dialog.setContent(text: model.tips)
            dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Onboarding_GotIt_Button)
            self?.present(dialog, animated: true)
        }
        cell.containerView.docs.addHover(with: UIColor.ud.fillHover, disposeBag: disposeBag)
        cell.update(SKGroupViewPosition.converToPisition(rows: rows, indexPath: indexPath))
        return cell
    }

    func makePasswordSwitchCell(indexPath: IndexPath) -> SKGroupTableViewCell {
        let rows = self.tableView(self.tableView, numberOfRowsInSection: indexPath.section)
        let row = indexPath.row
        guard row >= 0, row < passwordSettingDataSource.count else {
            DocsLogger.error("row: \(row) out of bounds! passwordSettingDataSource.count: \(passwordSettingDataSource.count)")
            spaceAssertionFailure("row out of bounds!")
            return SKGroupTableViewCell()
        }
        let data = passwordSettingDataSource[row]
        switch data.cellType {
        case .passwordSwitch:
            if let cell = tableView.dequeueReusableCell(withIdentifier: passwordSwitchCellIdentifier, for: indexPath) as? PasswordSwitchTableViewCell {
                cell.switchButton.isOn = hasLinkPassword
                cell.switchButton.rx.controlEvent(.valueChanged).withLatestFrom(cell.switchButton.rx.value).subscribe(onNext: { [weak self] (isOn) in
                    guard let self = self else { return }
                    self.permStatistics?.reportPermissionShareEncryptedLinkClick(shareType: self.shareEntity.type,
                                                                                 click: .openPassword,
                                                                                 target: .noneTargetView,
                                                                                 openPassword: isOn)
                    if isOn {
                        self.setupPassword()
                        self.passwordSettingTracker.report(action: .addPassword)
                    } else {
                        self.deletePassword()
                    }
                }).disposed(by: cell.disposeBag)
                cell.config(enableSwitchPassword: enableAnonymousAccess)
                cell.containerView.docs.addHover(with: UIColor.ud.fillHover, disposeBag: disposeBag)
                cell.update(SKGroupViewPosition.converToPisition(rows: rows, indexPath: indexPath))
                return cell
            }
        case .passwordDisplay:
            if let cell = tableView.dequeueReusableCell(withIdentifier: passwordDisplayCellIdentifier, for: indexPath) as? PasswordDisplayTableViewCell {
                guard !linkPassword.isEmpty else {
                    DocsLogger.info("passowrd is empty!")
                    return SKGroupTableViewCell()
                }
                cell.config(isToC: isToC, password: linkPassword)
                cell.containerView.docs.addHover(with: UIColor.ud.fillHover, disposeBag: disposeBag)
                cell.update(SKGroupViewPosition.converToPisition(rows: rows, indexPath: indexPath))
                return cell
            }
        }
        return SKGroupTableViewCell()
    }

    func makePasswordChangeAndCopyCell(indexPath: IndexPath) -> SKGroupTableViewCell {
        let rows = self.tableView(self.tableView, numberOfRowsInSection: indexPath.section)
        let row = indexPath.row
        guard let cellType = PasswordSettingPlainTextCellType(rawValue: row) else { return SKGroupTableViewCell() }
        if let cell = tableView.dequeueReusableCell(withIdentifier: passwordSettingPlainTextCellIdentifier, for: indexPath) as? PasswordSettingPlainTextCell {
            cell.config(with: cellType)
            cell.containerView.docs.addHover(with: UIColor.ud.fillHover, disposeBag: disposeBag)
            cell.update(SKGroupViewPosition.converToPisition(rows: rows, indexPath: indexPath))
            return cell
        }
        return SKGroupTableViewCell()
    }
}
