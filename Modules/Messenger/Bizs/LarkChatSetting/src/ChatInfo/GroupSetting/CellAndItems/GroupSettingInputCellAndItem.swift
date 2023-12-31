//
//  GroupSettingInputCellAndItem.swift
//  LarkChatSetting
//
//  Created by bytedance on 2021/10/18.
//

import UIKit
import Foundation
import UniverseDesignInput

// MARK: - 多行输入框 - item
struct GroupSettingInputItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var placeholder: String
    var height: CGFloat = 124
    var inputCallBack: (String) -> Void
}
// MARK: - 多行输入框 - cell
final class GroupSettingInputCell: GroupSettingCell, UITextViewDelegate {
    var inputCallBack: ((String) -> Void)?
    lazy var textView: UDBaseTextView = {
        let textView = UDBaseTextView()
        textView.font = .systemFont(ofSize: 16, weight: .regular)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.delegate = self
        return textView
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(124)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? GroupSettingInputItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        textView.placeholder = item.placeholder
        textView.snp.updateConstraints { make in
            make.height.equalTo(item.height)
        }
        self.inputCallBack = item.inputCallBack
    }

    func textViewDidChange(_ textView: UITextView) {
        self.inputCallBack?(textView.text)
    }
}
