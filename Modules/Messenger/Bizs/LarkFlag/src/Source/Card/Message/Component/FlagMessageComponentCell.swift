//
//  FlagMessageComponentCell.swift
//  LarkFlag
//
//  Created by ByteDance on 2022/10/19.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel

// 卡片类型消息
class FlagMessageComponentCell: FlagMessageCell {

    override class var identifier: String {
        return FlagMessageComponentCellViewModel.identifier
    }

    lazy var componentView: FlagComponentWrapperView = FlagComponentWrapperView(frame: .zero)

    var componentVM: FlagListMessageComponentViewModel? {
        return (self.viewModel as? FlagMessageComponentCellViewModel)?.componentViewModel
    }

    override func setupUI() {
        super.setupUI()
        self.contentWraper.addSubview(componentView)
        self.componentView.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.height.equalTo(0)
            make.width.bottom.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bottomMaskView.isHidden = true
    }

    override func updateCellContent() {
        super.updateCellContent()
        guard let vm = self.componentVM else {
            return
        }
        // 只有个人名片、群名片、公开话题群卡片(.mergeForward)可交互
        let type = vm.message.type
        let isFromPrivateTopic = (type == .mergeForward) && ((componentVM?.message.content as? MergeForwardContent)?.isFromPrivateTopic ?? false)
        componentView.isUserInteractionEnabled = (type == .shareUserCard || type == .shareGroupChat || isFromPrivateTopic)
        componentView.updateContent(vm: vm)
        componentView.snp.updateConstraints { make in
            make.height.equalTo(componentView.contentHeight)
        }
    }
}

class FlagComponentWrapperView: UIView, UITableViewDelegate, UITableViewDataSource {

    lazy var tableView: UITableView = UITableView()

    var componentVM: FlagListMessageComponentViewModel?

    var contentHeight: CGFloat {
        return componentVM?.renderer.size().height ?? 0.0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.register(MessageCommonCell.self, forCellReuseIdentifier: String(describing: MessageCommonCell.self))
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateContent(vm: FlagListMessageComponentViewModel) {
        componentVM = vm
        tableView.reloadData()
    }

    // MARK: - TableView Delegate/DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: MessageCommonCell.self), for: indexPath)
        let commonCell = cell as? MessageCommonCell ?? MessageCommonCell(style: .default, reuseIdentifier: String(describing: MessageCommonCell.self))
        componentVM?.renderCommonCell(cell: commonCell, cellId: componentVM?.message.id ?? "")
        return commonCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return contentHeight
    }
}
