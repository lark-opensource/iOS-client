//
//  FontSettingViewController.swift
//  LarkMine
//
//  Created by Hayden on 2020/11/12.
//

import Foundation
import UIKit
import LarkUIKit
import LarkZoomable
import UniverseDesignToast
import Homeric
import LKCommonsTracker
import LarkContainer
import LarkAccountInterface

final class FontSettingViewController: BaseUIViewController {

    private let userResolver: UserResolver
    private var passportUserService: PassportUserService?
    private var rightItem: LKBarButtonItem?

    private var selectedZoom: Zoom = Zoom.currentZoom

    private lazy var chatList = Chat.getExamples()
    private lazy var messageList = Message.getExamples()
    private lazy var docPreview = DocPreview.getExample()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var container: FontSettingView {
        if let view = self.view as? FontSettingView {
            return view
        } else {
            let view = FontSettingView()
            self.view = view
            return view
        }
    }

    override func loadView() {
        view = FontSettingView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.passportUserService = try? self.userResolver.resolve(assert: PassportUserService.self)
        setupViews()
        title = BundleI18n.LarkMine.Lark_NewSettings_TextSizeTitle
        Tracker.post(TeaEvent(Homeric.SETTING_TEXTSIZE_SHOW))
    }

    private func setupViews() {
        setNavigationBarRightItem()
        addCancelItem()
        container.messageView.dataSource = self
        container.chatView.dataSource = self
        container.docView.dataSource = self
        container.messageView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        container.chatView.register(ChatCell.self, forCellReuseIdentifier: "ChatCell")
        container.docView.register(DocPreviewCell.self, forCellReuseIdentifier: "DockPreviewCell")
        container.zoomSlider.onZoomChanged = { [weak self] zoom in
            self?.selectedZoom = zoom
            self?.updateTabels(for: zoom)
            self?.setRightNavigationButtonEnable()
            Tracker.post(TeaEvent(Homeric.SETTING_TEXTSIZE_SLIDEBAR_USING))
        }
        container.zoomSlider.zoom = Zoom.currentZoom
    }

    private func updateTabels(for zoom: Zoom) {
        container.chatView.reloadData()
        container.messageView.reloadData()
        container.docView.reloadData()
    }

    private func setNavigationBarRightItem() {
        let rightItem = LKBarButtonItem(title: BundleI18n.LarkMine.Lark_NewSettings_ConfirmButton, fontStyle: .medium)
        rightItem.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        rightItem.button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        rightItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        rightItem.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        self.rightItem = rightItem
        self.navigationItem.rightBarButtonItem = rightItem
        setRightNavigationButtonEnable()
    }

    private func setRightNavigationButtonEnable() {
        rightItem?.isEnabled = Zoom.currentZoom != selectedZoom
    }

    @objc
    private func navigationBarRightItemTapped() {
        guard let window = self.view.window else {
            assertionFailure()
            return
        }
        Tracker.post(TeaEvent(Homeric.SETTING_TEXTSIZE_DONE_CLICK))
        Zoom.setZoom(selectedZoom)
        let hud = UDToast.showTips(
            with: BundleI18n.LarkMine.Lark_NewSettings_SetSuccessfully,
            on: window
        )
        if !Display.pad {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                hud.remove()
                self.close()
            }
        }
    }

    override func backItemTapped() {
        super.backItemTapped()
        Tracker.post(TeaEvent(Homeric.SETTING_TEXTSIZE_RETURN_CLICK))
    }

    func close() {
        if hasBackPage {
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === container.messageView {
            return messageList.count
        } else if tableView === container.chatView {
            return chatList.count
        } else if tableView === container.docView {
            return 1
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === container.messageView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") as? MessageCell ?? MessageCell()
            let continuous = indexPath.row != 0 && messageList[indexPath.row - 1].id == messageList[indexPath.row].id
            cell.configure(with: messageList[indexPath.row], avatarURL: self.passportUserService?.user.avatarURL, continuous: continuous, zoom: selectedZoom)
            return cell
        } else if tableView === container.chatView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell") as? ChatCell ?? ChatCell()
            cell.selectionStyle = .none
            cell.configure(with: chatList[indexPath.row], zoom: selectedZoom)
            return cell
        } else if tableView === container.docView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DocPreviewCell") as? DocPreviewCell ?? DocPreviewCell()
            cell.selectionStyle = .none
            cell.configure(with: docPreview, zoom: selectedZoom)
            return cell
        } else {
            return UITableViewCell()
        }
    }
}

extension FontSettingViewController: UITableViewDataSource {}
