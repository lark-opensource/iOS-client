//
//  FontSettingViewController.swift
//  LarkMine
//
//  Created by Hayden on 2020/11/12.
//

import Foundation
import UIKit
import LarkZoomable

class FontSettingViewController: UIViewController {

    private var rightItem: UIBarButtonItem?

    private var selectedZoom: Zoom = Zoom.currentZoom

    let chatList = Chat.getExamples()
    let messageList = Message.getExamples()
    var fontList: [Font] { return Font.getExamples(zoom: selectedZoom) }

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
        setupViews()
        title = "字体大小"
    }

    private func setupViews() {
        setNavigationBarRightItem()
        container.messageView.dataSource = self
        container.chatView.dataSource = self
        container.fontView.dataSource = self
        container.messageView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        container.chatView.register(ChatCell.self, forCellReuseIdentifier: "ChatCell")
        container.fontView.register(FontCell.self, forCellReuseIdentifier: "FontCell")
        container.zoomSlider.onZoomChanged = { [weak self] zoom in
            self?.selectedZoom = zoom
            self?.updateTabels(for: zoom)
            self?.setRightNavigationButtonEnable()
        }
        container.zoomSlider.zoom = Zoom.currentZoom
    }

    private func updateTabels(for zoom: Zoom) {
        container.chatView.reloadData()
        container.messageView.reloadData()
        container.fontView.reloadData()
    }

    private func setNavigationBarRightItem() {
        let rightItem = UIBarButtonItem(
            title: "保存",
            style: .plain,
            target: self,
            action: #selector(navigationBarRightItemTapped)
        )
        self.rightItem = rightItem
        self.navigationItem.rightBarButtonItem = rightItem
        setRightNavigationButtonEnable()
    }

    private func setRightNavigationButtonEnable() {
        rightItem?.isEnabled = Zoom.currentZoom != selectedZoom
    }

    @objc
    private func navigationBarRightItemTapped() {
        Zoom.setZoom(selectedZoom)
        setRightNavigationButtonEnable()
    }

    func close() {
        self.navigationController?.popToRootViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === container.chatView {
            return chatList.count
        } else if tableView === container.messageView {
            return messageList.count
        } else {
            return fontList.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === container.chatView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell") as? ChatCell ?? ChatCell()
            cell.selectionStyle = .none
            cell.configure(with: chatList[indexPath.row], zoom: selectedZoom)
            return cell
        } else if tableView === container.messageView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") as? MessageCell ?? MessageCell()
            let continuous = indexPath.row != 0 && messageList[indexPath.row - 1].id == messageList[indexPath.row].id
            cell.configure(with: messageList[indexPath.row], continuous: continuous, zoom: selectedZoom)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FontCell") as? FontCell ?? FontCell()
            cell.configure(with: fontList[indexPath.row], zoom: selectedZoom)
            return cell
        }
    }
}

extension FontSettingViewController: UITableViewDataSource {}
