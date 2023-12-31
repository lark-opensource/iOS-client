//
//  ChatInfoGroupAppCellAndItem.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/1/27.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore
import LarkFeatureGating
import LarkOpenChat
import LarkBadge

// MARK: - 应用 - item
struct ChatInfoGroupAppItem: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var listViewModel: ChatSettingItemListViewModel
}

// MARK: - 应用 - cell
final class ChatInfoGroupAppCell: ChatInfoCell {
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        return label
    }()
    private var listView: ChatSettingItemListView?
    private var lineNum: Int = 0
    private var maxWidth: CGFloat = UIScreen.main.bounds.width

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.top.left.equalTo(16)
        }
        self.selectionStyle = .none
        arrow.isHidden = true
    }

    override func updateAvailableMaxWidth(_ width: CGFloat) {
        maxWidth = width
    }

    func update(viewModel: ChatInfoGroupAppItem) {
        nameLabel.text = viewModel.title
        self.layout(viewModel: viewModel)
    }

    private func layout(viewModel: ChatInfoGroupAppItem) {
        self.listView?.removeFromSuperview()
        let listView = ChatSettingItemListView(viewModel: viewModel.listViewModel, maxWidth: maxWidth)
        self.listView = listView
        contentView.addSubview(listView)
        listView.snp.makeConstraints({ (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(16)
            make.left.equalTo(6)
            make.right.lessThanOrEqualTo(-6)
            make.bottom.equalToSuperview().offset(-16)
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let vm = item as? ChatInfoGroupAppItem else {
            assert(false, "\(self):vm.Type error")
            return
        }
        self.update(viewModel: vm)
        layoutSeparater(vm.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

struct ChatSettingItemListViewModel {
    var functions: [ChatSettingItemProtocol]
    weak var vc: UIViewController?
}

final class ChatSettingItemListView: UIStackView {

    init(viewModel: ChatSettingItemListViewModel, maxWidth: CGFloat) {
        super.init(frame: .zero)
        axis = .vertical
        alignment = .leading
        spacing = 8

        guard !viewModel.functions.isEmpty else {
            return
        }
        let defaultItemSizeWith: CGFloat = 100
        let itemCount = viewModel.functions.count
        let maxItemInLine: Int
        let padding: CGFloat = 16   // 外边距，列表距屏幕边缘的距离（不一定是 16，随机型而定）
        let offset: CGFloat = 6     // 内边距，App 组距列表边缘的距离
        let width = max(0, (maxWidth) - (padding + offset) * 2)

        // 摆放规则：
        // 1. 单个item 文本框以 84 的宽度，向右增加个数，item 间距为 4；
        // 2. 当触达右侧容器边界时，文本框宽度变为均分布局；
        // 3. 当文本框宽度小于63时，item 折行显示。
        // https://bytedance.feishu.cn/docx/IbKfdkdGeomuCuxdACBcHfmun2b
        let itemSpacing: CGFloat = 4
        let maxItemWidth: CGFloat = 84
        let minItemWidth: CGFloat = 63
        let expectedItemWidth = (width - itemSpacing * CGFloat(itemCount - 1)) / CGFloat(itemCount)
        let realItemWidth: CGFloat  // 实际计算出的 item 宽度
        var itemCountPerLine: Int = itemCount   // 每行 item 的数量
        if expectedItemWidth >= maxItemWidth {
            // 宽度足以放下宽度为 84 的所有 item
            realItemWidth = maxItemWidth
        } else if expectedItemWidth < minItemWidth {
            // 单行放置时，平均每个 item 宽度不足 63，需要折行，这种情况下，需要计算具体的行数和每个 item 的实际宽度。
            // 计算过程：
            // 设单行宽度为 w，单行 item 数量为 n，单个 item 宽度为 x，有 (x*n)+4(n-1)=w
            // 将 x=63 代入方程，得 n=(w+4)/(63+4)
            // 又 n 必需为整数，则向下取整得实际的 itemsPerLine
            let itemsPerLine = floor((width + itemSpacing) / (minItemWidth + itemSpacing))
            // 用 itemsPerLine 再次代入公式 x=(w-4(n-1))/n，反推 realItemWidth
            realItemWidth = (width - itemSpacing * (itemsPerLine - 1)) / itemsPerLine
            itemCountPerLine = Int(itemsPerLine)
        } else {
            // 单行可以放置所有 item，计算实际宽度
            realItemWidth = expectedItemWidth
        }

        if itemCountPerLine == 0 {
            // 避免 Division by zero 的问题（这种情况下，width < minItemWidth，属于中间态的布局问题）
            itemCountPerLine = 1
        }

        // 创建 ItemView
        // 这里本应使用 var currentStack: UIStackView!，后面逻辑可以保证一定会赋值，但是怕 lint 过不了，
        // 又不想使用 swiftlint disable，这里先赋一个实例吧，也许以后会想到更好的写法
        var currentStack: UIStackView = UIStackView()
        for (index, item) in viewModel.functions.enumerated() {
            if index % itemCountPerLine == 0 {
                currentStack = UIStackView()
                currentStack.spacing = itemSpacing
                currentStack.axis = .horizontal
                // 由于不同机型上 InsetTableView 的边距并不是固定的（16-20 不等），因此计算出来会有少许误差，
                // 所以这里使用 fillEqually，确保最后一个 item 不会被压缩。
                currentStack.distribution = .fillEqually
                addArrangedSubview(currentStack)
            }
            let itemView = ChatSettingAppItemView(name: item.title,
                                                  iconInfo: item.imageInfo,
                                                  tapHandler: { item.clickHandler(viewModel.vc) },
                                                  badgePath: item.badgePath)
            itemView.snp.makeConstraints { make in
                // 同上原因，这里宽度不设为强制，靠 fillEqually 来设定长度，误差不大
                make.width.equalTo(realItemWidth).priority(.medium)
            }
            currentStack.addArrangedSubview(itemView)
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
