//
//  RejectParticpantsViewController.swift
//  ByteView
//
//  Created by wulv on 2022/5/23.
//

import Foundation
import SnapKit
import UIKit
import ByteViewUI

extension RejectParticpantsViewController {
    enum Layout {
        static let compactTopH: CGFloat = 12
        static let regularTopH: CGFloat = 8
        static let regularBottomH: CGFloat = 8
        static let titleH: CGFloat = 48
        static let rowH: CGFloat = 64
        static let regularMaxH: CGFloat = 607
        static let regularW: CGFloat = 375
        static let compactLineH: CGFloat = 1.0
    }
}

final class RejectParticpantsViewController: VMViewController<RejectParticipantsViewModel>, UITableViewDataSource {

    private var isPopover: Bool = false

    /// Pad上展示的邀请action sheet
    private weak var showingInviteController: UIViewController?

    lazy var popoverTopView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.backgroundColor = .clear
        l.attributedText = NSMutableAttributedString(string: I18n.View_MV_WhoDeclinedList, config: .h3, textColor: UIColor.ud.textTitle)
        return l
    }()

    private lazy var line: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        return line
    }()

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: CGRect.zero, style: .plain)
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = Layout.rowH
        tableView.register(cellType: RejectParticipantCell.self)
        tableView.dataSource = self
        tableView.bounces = false
        return tableView
    }()

    lazy var popoverBottomView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    override func setupViews() {

        view.addSubview(popoverTopView)
        popoverTopView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(Layout.regularTopH)
        }

        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(popoverTopView.snp.bottom)
            $0.left.right.equalToSuperview().inset(16)
            $0.height.equalTo(Layout.titleH)
        }

        view.addSubview(line)
        line.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom)
            $0.height.equalTo(Layout.compactLineH / view.vc.displayScale)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom)
            $0.left.right.equalToSuperview()
        }

        view.addSubview(popoverBottomView)
        popoverBottomView.snp.makeConstraints {
            $0.top.equalTo(tableView.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(Layout.regularBottomH)
        }

        updateStyle()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override func bindViewModel() {
        viewModel.didChangeRejectDataSource = { [weak self] _ in
            guard let self = self else { return }
            Util.runInMainThread {
                self.tableView.reloadData()
                // 更新高度
                if self.isPopover {
                    self.updatePopoverHeight(self.contentHeight())
                } else {
                    self.panViewController?.updateBelowLayout()
                }
            }
        }
    }

    private func updateStyle() {
        view.backgroundColor = isPopover ? UIColor.ud.bgFloat : UIColor.ud.bgBody
        titleLabel.textAlignment = isPopover ? .left : .center
        line.isHidden = isPopover
        popoverTopView.isHidden = !isPopover
        popoverTopView.snp.updateConstraints {
            $0.height.equalTo(isPopover ? Layout.regularTopH : 0)
        }
        popoverBottomView.isHidden = !isPopover
        popoverBottomView.snp.updateConstraints {
            $0.height.equalTo(isPopover ? Layout.regularBottomH : 0)
        }
        updatePopoverHeight(contentHeight())
    }

    private func contentHeight() -> CGFloat {
        if isPopover {
            let contentHeight = Layout.regularTopH
            + Layout.titleH
            + Layout.rowH * CGFloat(viewModel.listCount)
            + Layout.regularBottomH
            return contentHeight > Layout.regularMaxH ? Layout.regularMaxH : contentHeight
        }
        let contentHeight = Layout.compactTopH
        + Layout.titleH
        + Layout.rowH * CGFloat(viewModel.listCount)
        return contentHeight
    }

    private func updatePopoverHeight(_ h: CGFloat) {
        if isPopover, preferredContentSize.height != h {
            updateDynamicModalSize(CGSize(width: Layout.regularW, height: h))
        }
    }

    // MARK: 更新 Pad 上展示的邀请 action sheet 位置
    private func updateShowingInviteController() {
        guard let vc = showingInviteController, VCScene.rootTraitCollection?.horizontalSizeClass == .regular else { return }

        if let pid = viewModel.lastPIDForShowingInvite,
           let index = viewModel.rejectDataSource.firstIndex(where: { $0.participant.user.id == pid }),
            let cell = tableView.cellForRow(at: IndexPath(item: index, section: 0)) as? RejectParticipantCell,
           let model = viewModel.rejectDataSource[safeAccess: index] {
            vc.dismiss(animated: false)
            viewModel.showInviteActionSheet(model, sender: cell.callButton, needTrack: false,
                                            useCache: true, animated: false) { [weak self] (vc, _) in
                self?.showingInviteController = vc
            }
        } else {
            vc.dismiss(animated: true)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rejectDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellModel = viewModel.rejectDataSource[safeAccess: indexPath.row] else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withType: RejectParticipantCell.self, for: indexPath)
        cell.configure(with: cellModel)
        cell.tapCallButton = { [weak self, weak cell] in
            guard let self = self, let cell = cell else { return }
            if cellModel.enableInvitePSTN {
                self.viewModel.rejectParticipantMoreCall(with: cellModel, sender: cell.callButton) { [weak self] (vc, _) in
                    self?.showingInviteController = vc
                }
            } else {
                self.viewModel.rejectParticipantCall(with: cellModel.participant)
            }
        }
        cell.tapAvatarAction = { [weak self] in
            self?.viewModel.jumpToUserProfile(participantId: cellModel.participant.participantId, isLarkGuest: cellModel.participant.isLarkGuest)
        }
        return cell
    }
}

extension RejectParticpantsViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        isPopover = isRegular
        updateStyle()
    }
}

extension RejectParticpantsViewController: PanChildViewControllerProtocol {

    var backgroudColor: UIColor {
        return isPopover ? UIColor.ud.bgFloat : UIColor.ud.bgBody
    }

    var defaultLayout: RoadLayout {
        return .shrink
    }

    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        return .contentHeight(contentHeight(), minTopInset: 44)
    }

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        if Display.phone {
            switch axis {
            case .landscape:
                return .maxWidth(width: 420)
            default: return .fullWidth
            }
        }
        return isPopover ? .maxWidth(width: Layout.regularW) : .fullWidth
    }
}
