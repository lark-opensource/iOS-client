//
//  TodoPinConfirmView.swift
//  LarkChat
//
//  Created by 白言韬 on 2020/12/14.
//

import Foundation
import UIKit
import LarkModel

final class TodoPinConfirmView: PinConfirmContainerView {
    var icon: UIImageView
    var title: UILabel
    var assigneeNames: UILabel

    private var hasAssigneeNames: Bool = false {
        didSet {
            guard oldValue != hasAssigneeNames else { return }
            layout(hasAssigneeNames: hasAssigneeNames)
        }
    }

    override init(frame: CGRect) {
        self.icon = UIImageView(image: Resources.todo_pin)
        self.title = UILabel(frame: .zero)
        title.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        title.textColor = UIColor.ud.N900
        title.numberOfLines = 1
        self.assigneeNames = UILabel(frame: .zero)
        assigneeNames.font = UIFont.systemFont(ofSize: 12)
        assigneeNames.textColor = UIColor.ud.N500
        assigneeNames.numberOfLines = 1
        super.init(frame: frame)
        self.addSubview(icon)
        self.addSubview(title)
        self.addSubview(assigneeNames)
        layout(hasAssigneeNames: hasAssigneeNames)
    }

    private func layout(hasAssigneeNames: Bool) {
        icon.snp.remakeConstraints { (make) in
            make.left.top.equalTo(BubbleLayout.commonInset.left)
            make.width.height.equalTo(48)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
        }
        if hasAssigneeNames {
            assigneeNames.isHidden = false
            title.snp.remakeConstraints {
                $0.top.equalTo(icon)
                $0.left.equalTo(icon.snp.right).offset(8)
                $0.right.lessThanOrEqualToSuperview().offset(-BubbleLayout.commonInset.right)
            }
            assigneeNames.snp.remakeConstraints {
                $0.top.equalTo(title.snp.bottom).offset(8)
                $0.left.equalTo(title)
                $0.right.lessThanOrEqualToSuperview().offset(-BubbleLayout.commonInset.right)
            }
        } else {
            assigneeNames.isHidden = true
            title.snp.remakeConstraints {
                $0.centerY.equalTo(icon)
                $0.left.equalTo(icon.snp.right).offset(8)
                $0.right.lessThanOrEqualToSuperview().offset(-BubbleLayout.commonInset.right)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)

        guard let vm = contentVM as? TodoPinConfirmViewModel else {
            return
        }
        title.text = vm.title
        assigneeNames.text = vm.assigneeNamesText
        hasAssigneeNames = !vm.assigneeNamesText.isEmpty
    }
}

final class TodoPinConfirmViewModel: PinAlertViewModel {
    var title: String = ""
    var assigneeNamesText: String = ""
    init?(todoMessage: Message,
          getSenderName: @escaping (Chatter) -> String) {
        super.init(message: todoMessage, getSenderName: getSenderName)

        guard let content = todoMessage.content as? TodoContent else {
            return nil
        }

        self.title = content.pbModel.todoDetail.summary

        let assigneeNames = content.pbModel.todoDetail.assignees.compactMap { a -> String? in
            switch a.assignee {
            case .user(let u): return u.user.name
            @unknown default: return nil
            }
        }
        guard !assigneeNames.isEmpty else { return }
        var text = BundleI18n.Todo.Todo_Task_AssigneesAre2
        text += assigneeNames.joined(separator: BundleI18n.Todo.Todo_Task_Comma)
        self.assigneeNamesText = text
    }
}
