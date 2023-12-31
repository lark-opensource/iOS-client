//
//  PSTNAreaCodeViewController.swift
//  ByteView
//
//  Created by yangyao on 2020/4/10.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxDataSources
import LarkLocalizations
import ByteViewUI
import ByteViewSetting
import ByteViewNetwork
import UniverseDesignIcon

class PSTNAreaCodeViewController: VMViewController<PSTNAreaCodeViewModel>, UITableViewDelegate {
    private let disposeBag = DisposeBag()
    var selectedMobileCode: MobileCode?

    var mobileCodeLocale: Lang {
        return LanguageManager.currentLanguage
    }

    private lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.delegate = self
        tableView.sectionIndexColor = UIColor.ud.textPlaceholder
        tableView.separatorColor = .clear
        tableView.tableFooterView = UIView()
        tableView.tableFooterView?.backgroundColor = .clear
        tableView.rowHeight = 48
        tableView.register(PSTNAreaCodeCell.self, forCellReuseIdentifier: PSTNAreaCodeCell.description())
        tableView.register(PSTNAreaCodeHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: PSTNAreaCodeHeaderFooterView.description())
        return tableView
    }()

    private lazy var dataSource: RxTableViewSectionedReloadDataSource<AreaCodeSectionModel> = {
        return RxTableViewSectionedReloadDataSource<AreaCodeSectionModel<String, MobileCode>>(
             configureCell: { [weak self] (dataSource, tableView, indexPath, mobileCode) in
                guard let cell = tableView
                    .dequeueReusableCell(withIdentifier:
                        PSTNAreaCodeCell.description()) as? PSTNAreaCodeCell else {
                    return UITableViewCell()
                }
                cell.titleLabel.text = "\(mobileCode.name) \(mobileCode.code)"
                cell.separator.isHidden =
                    (indexPath.section != dataSource.sectionModels.count - 1) &&
                    (indexPath.row == dataSource.sectionModels[indexPath.section].items.count - 1)

                if self?.viewModel.showIndexList == false {
                    cell.selectedImageView.isHidden = self?.selectedMobileCode?.code != mobileCode.code
                } else {
                    cell.selectedImageView.isHidden = true
                }
                cell.titleLabel.textColor = UIColor.ud.textTitle
                return cell
        }, sectionIndexTitles: { [weak self] dataSource -> [String]? in
            if self?.mobileCodeLocale != .ja_JP && self?.viewModel.showIndexList == true {
                return dataSource.sectionModels.map { $0.index }
            } else {
                return nil
            }
        })
    }()

    private lazy var barBackButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconN3, size: CGSize(width: 24, height: 24)), for: .highlighted)
        button.addTarget(self, action: #selector(popViewController), for: .touchUpInside)
        return button
    }()

    @objc func popViewController() {
        navigationController?.popViewController(animated: true)
    }

    override func setupViews() {
        view.backgroundColor = UIColor.ud.bgBody
        title = I18n.View_G_InternationalCallingCodes
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: barBackButton)

        view.addSubview(tableView)

        layoutViews()
    }

    override func bindViewModel() {
        viewModel.dataSource
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        tableView.rx
            .modelSelected(MobileCode.self)
            .bind(to: viewModel.selectedRelay)
            .disposed(by: disposeBag)

        viewModel.selectedRelay.asObservable()
            .subscribe(onNext: { [weak self] (mobileCode) in
                self?.selectedMobileCode = mobileCode
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)

        tableView.rx.itemSelected.do(onNext: { [weak self] indexPath in
            self?.tableView.deselectRow(at: indexPath, animated: true)
        }).subscribe(onNext: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
            }

    func layoutViews() {
        self.tableView.snp.remakeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if newContext.layoutChangeReason.isOrientationChanged {
            self.layoutViews()
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override var shouldAutorotate: Bool {
        return true
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if
            let headerView = tableView
                .dequeueReusableHeaderFooterView(withIdentifier:
                                                    PSTNAreaCodeHeaderFooterView.description()) as? PSTNAreaCodeHeaderFooterView {
            headerView.titleLabel.text = dataSource.sectionModels[section].index
            return headerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0.0 : 32.0
    }
}
