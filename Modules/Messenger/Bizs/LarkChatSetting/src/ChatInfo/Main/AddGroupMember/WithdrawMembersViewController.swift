//
//  WithdrawMembersViewController.swift
//  LarkChat
//
//  Created by zc09v on 2019/6/26.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import LarkCore
import RxSwift
import UniverseDesignToast
import LarkActionSheet
import LarkAlertController
import EENavigator
import LarkSDKInterface
import LarkBizAvatar

protocol WithdrawItemCellPropsProtocol {
    var id: String { get }
    var avatarKey: String { get }
    var name: String { get }
    var type: WithdrawItemType { get }
    var backupImage: UIImage? { get }
}

struct WithdrawItemCellProps: WithdrawItemCellPropsProtocol {
    let id: String
    let avatarKey: String
    let name: String
    let type: WithdrawItemType
    let backupImage: UIImage?
}

enum WithdrawItemType {
    case chatter
    case chat
    case department
}

final class WithdrawMembersViewController: BaseSettingController, UITableViewDataSource, UITableViewDelegate {
    private let chatAPI: ChatAPI
    private let chatId: String
    private let isThread: Bool
    private let disposeBag: DisposeBag = DisposeBag()
    private var dataSource: [WithdrawItemCellPropsProtocol] = []
    private let navi: Navigatable

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.rowHeight = 68
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.lu.register(cellSelf: WithdrawMemberCell.self)
        return tableView
    }()

    init(chatId: String, isThread: Bool, dataSource: [WithdrawItemCellPropsProtocol], chatAPI: ChatAPI, navi: Navigatable) {
        self.chatAPI = chatAPI
        self.chatId = chatId
        self.isThread = isThread
        self.dataSource = dataSource
        self.navi = navi
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.isThread ? BundleI18n.LarkChatSetting.Lark_Groups_RevokeCircleInviteTitle : BundleI18n.LarkChatSetting.Lark_Group_RevokeSelectMemberTitle
        super.addCloseItem()
        self.view.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: WithdrawMemberCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? WithdrawMemberCell else { return UITableViewCell() }
        cell.set(props: self.dataSource[indexPath.row], isLastCell: indexPath.row == self.dataSource.count - 1)
        cell.delegate = self
        return cell
    }
}

extension WithdrawMembersViewController: WithdrawMemberCellDelegate {
    func withDraw(id: String, WithdrawItemType: WithdrawItemType) {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkChatSetting.Lark_Group_RevokeConfirmationTitle)
        alertController.setContent(text: BundleI18n.LarkChatSetting.Lark_Groups_CancelInvite)
        alertController.addSecondaryButton(text: BundleI18n.LarkChatSetting.Lark_Group_RevokeConfirmationCancel)
        alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Groups_Revoke, dismissCompletion: {
            let hud = UDToast.showLoading(on: self.view)

            var chatterIds: [String] = []
            var chatIds: [String] = []
            var departmentIds: [String] = []
            if let item = self.dataSource.first(where: { $0.id == id }) {
                switch item.type {
                case .chatter:
                    chatterIds = [id]
                case .chat:
                    chatIds = [id]
                case .department:
                    departmentIds = [id]
                }
            }
            self.chatAPI.withdrawAddChatters(chatId: self.chatId, chatterIds: chatterIds, chatIds: chatIds, departmentIds: departmentIds)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    if let view = self?.view {
                        hud.showSuccess(with: BundleI18n.LarkChatSetting.Lark_Group_RevokeSuccess, on: view)
                    }
                    self?.dataSource.removeAll(where: { (item) -> Bool in
                        return item.id == id
                    })
                    if self?.dataSource.isEmpty ?? false {
                        self?.dismiss(animated: true, completion: nil)
                    } else {
                        self?.tableView.reloadData()
                    }
                }, onError: { [weak self] (error) in
                    if let apiError = error.underlyingError as? APIError {
                        hud.remove()
                        self?.showTipConfirm(text: apiError.displayMessage)
                    } else if let view = self?.view {
                        hud.showFailure(with: BundleI18n.LarkChatSetting.Lark_Group_RevokeGeneralError, on: view, error: error)
                    } else {
                        assertionFailure()
                        hud.remove()
                    }
                }).disposed(by: self.disposeBag)
        })
        self.navi.present(alertController, from: self)
    }

    private func showTipConfirm(text: String) {
        let alertController = LarkAlertController()
        alertController.setContent(text: text)
        alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Group_RevokeIKnow)
        self.navi.present(alertController, from: self)
    }
}

private protocol WithdrawMemberCellDelegate: AnyObject {
    func withDraw(id: String, WithdrawItemType: WithdrawItemType)
}

private final class WithdrawMemberCell: UITableViewCell {
    private let avatarView = BizAvatar()
    private let nameLabel = UILabel()
    private let withdrawButton = UIButton(type: .custom)
    private var bottomBoarder = UIView(frame: CGRect.zero)
    private let avatarSize: CGFloat = 48
    weak var delegate: WithdrawMemberCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        self.contentView.addSubview(avatarView)
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(withdrawButton)
        self.contentView.addSubview(bottomBoarder)

        avatarView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.font = UIFont.systemFont(ofSize: 17)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(withdrawButton.snp.left).offset(-20)
        }

        withdrawButton.setTitle(BundleI18n.LarkChatSetting.Lark_Group_Revoke, for: .normal)
        withdrawButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        withdrawButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        withdrawButton.layer.borderColor = UIColor.ud.colorfulBlue.cgColor
        withdrawButton.layer.borderWidth = 0.5
        withdrawButton.layer.cornerRadius = 4
        withdrawButton.addTarget(self, action: #selector(withdrawClick), for: .touchUpInside)
        withdrawButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(28)
        }

        bottomBoarder.backgroundColor = UIColor.ud.N300
        bottomBoarder.snp.makeConstraints { (make) in
            make.bottom.equalTo(0)
            make.left.equalTo(avatarView.snp.right)
            make.right.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate var props: WithdrawItemCellPropsProtocol? {
        didSet {
            guard let props = self.props else { return }
            nameLabel.text = props.name
            if !props.avatarKey.isEmpty {
                avatarView.setAvatarByIdentifier(props.id, avatarKey: props.avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
            } else {
                avatarView.image = props.backupImage
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.props = nil
        self.delegate = nil
        avatarView.image = nil
        nameLabel.text = ""
    }

    func set(props: WithdrawItemCellPropsProtocol, isLastCell: Bool) {
        self.props = props
        if isLastCell {
            bottomBoarder.snp.updateConstraints { (make) in
                make.left.equalTo(avatarView.snp.right).offset(-avatarSize)
            }
        } else {
            bottomBoarder.snp.updateConstraints { (make) in
                make.left.equalTo(avatarView.snp.right)
            }
        }
    }

    @objc
    func withdrawClick() {
        if let props = self.props, !props.id.isEmpty {
            self.delegate?.withDraw(id: props.id, WithdrawItemType: props.type)
        }
    }
}
