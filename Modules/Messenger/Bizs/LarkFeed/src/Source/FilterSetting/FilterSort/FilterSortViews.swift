//
//  FilterSortViews.swift
//  LarkFeed
//
//  Created by kangsiwan on 2020/12/23.
//

import Foundation
import LarkUIKit
import UniverseDesignIcon
import UIKit
import RustPB
import SnapKit

/// switch点击事件
typealias FeedFilterSortSwitchHandler = (_ status: Bool) -> Void
typealias FeedCommonlyFilterTapHandler = (_ type: Feed_V1_FeedFilter.TypeEnum) -> Void
typealias FeedCommonlyFilterAddHandler = () -> Void

final class FilterSortView: UIView {
    weak var delegate: FeedFilterSortViewController?
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if delegate != nil && view != nil {
            delegate?.removeHighlight()
            delegate = nil
        }
        return view
    }
}

/// 所有赋值给cell的model必须满足这个协议
protocol FeedFilterSortItemProtocol {
    /// 重用标识符
    var cellIdentifier: String { get }

    var isLastRow: Bool { get set }
}

class FeedFilterSortBaseCell: UITableViewCell {
    // 直接赋值给cell.backgroundColor或backgroundView的话, 拖拽阴影会偏深
    private let backgroundColorView = UIView()
    func updateBackgroundColor(_ color: UIColor) {
        backgroundColorView.backgroundColor = color
    }

    var item: FeedFilterSortItemProtocol? {
        didSet {
            setCellInfo()
        }
    }

    var bottomSeperator: UIView?

    func setCellInfo() {
        assert(false, "No Override Method")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColorView.backgroundColor = UIColor.ud.bgFloat
        addSubview(backgroundColorView)
        sendSubviewToBack(backgroundColorView)
        backgroundColorView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct FeedFilterEditModel: FeedFilterSortItemProtocol {
    var cellIdentifier: String
    let cellHeight: CGFloat = 48
    var title: String
    var status: Bool
    var switchEnable: Bool
    var switchHandler: FeedFilterSortSwitchHandler?
    var isLastRow: Bool = false
}

final class FilterEditCell: FeedFilterSortBaseCell {
    var isOpen: Bool = true {
        didSet {
            filterSwitch.isOn = isOpen
        }
    }

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.text = BundleI18n.LarkFeed.Lark_Feed_MessageFilter // 消息筛选器
        return label
    }()

    var filterSwitch: UISwitch = {
        let newSwitch = UISwitch()
        newSwitch.isOn = true
        return newSwitch
    }()

    override func setCellInfo() {
        guard let currItem = self.item as? FeedFilterEditModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        filterSwitch.isOn = currItem.status
    }

    @objc
    func switchClick() {
        isOpen = filterSwitch.isOn
        guard let currItem = self.item as? FeedFilterEditModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        currItem.switchHandler?(filterSwitch.isOn)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .none
        filterSwitch.addTarget(self, action: #selector(switchClick), for: .valueChanged)
        contentView.addSubview(titleLabel)
        contentView.addSubview(filterSwitch)

        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }

        filterSwitch.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
    }
}

struct FeedCommonlyFilterModel: FeedFilterSortItemProtocol {
    var cellIdentifier: String
    var maxLimitWidth: CGFloat
    var filterItems: [FeedCommonlyFilterItem]
    let cellHeight: CGFloat = 80
    var tapHandler: FeedCommonlyFilterTapHandler?
    var addHandler: FeedCommonlyFilterAddHandler?
    var isLastRow: Bool = false
}

struct FeedCommonlyFilterItem {
    var filterItem: FilterItemModel
    var editEnable: Bool
}

final class FilterCommonlyCell: FeedFilterSortBaseCell {
    private let buttonsContainerView = UIView()
    private var buttonMap: [Feed_V1_FeedFilter.TypeEnum: UIButton] = [:]
    private var titleWidthMap: [Feed_V1_FeedFilter.TypeEnum: CGFloat] = [:]
    var filterItems: [FeedCommonlyFilterItem]?
    var maxLimitWidth: CGFloat = 0.0
    private let padding = 20.0
    private let crossPadding = 36.0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = UIColor.clear
        updateBackgroundColor(UIColor.clear)
        contentView.addSubview(buttonsContainerView)
        buttonsContainerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    override func setCellInfo() {
        guard var currItem = self.item as? FeedCommonlyFilterModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        var filterItems = currItem.filterItems
        maxLimitWidth = currItem.maxLimitWidth
        setupItemsView(filterItems)
    }

    private func setupItemsView(_ items: [FeedCommonlyFilterItem]) {
        self.filterItems = items

        // 清理容器内的子视图
        for subview in buttonsContainerView.subviews {
            subview.removeFromSuperview()
        }

        // 补充加号按钮
        var allItems = items
        if allItems.count < FeedThreeColumnConfig.fixedItemsMaxNum,
           !allItems.contains(where: { $0.filterItem.type == .unknown }) {
            allItems.append(FeedCommonlyFilterItem(filterItem: FilterItemModel(type: .unknown, name: ""), editEnable: true))
        }
        // 添加新子视图
        var i = 0
        var x = 0.0
        var y = 0.0
        let height = 32.0
        for item in allItems {
            let itemBtn = getItemButton(item.filterItem)
            buttonsContainerView.addSubview(itemBtn)
            let textWidth = (titleWidthMap[item.filterItem.type] ?? 0.0) +
                            (item.editEnable ? padding + crossPadding : 2 * padding)
            if x + textWidth > maxLimitWidth {
                y += Cons.verticalPadding + height
                x = 0.0
            }
            itemBtn.frame = CGRect(x: x, y: y, width: textWidth, height: height)
            itemBtn.tag = 1000 + i
            x += 8.0 + textWidth
            i += 1
        }

        buttonsContainerView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(y + height).priority(.required)
        }
    }

    private func getItemButton(_ filter: FilterItemModel) -> UIButton {
        if let button = buttonMap[filter.type] {
            return button
        }

        let button = UIButton(type: .custom)
        if filter.type == .unknown {
            button.setImage(Resources.icon_addOutlined, for: .normal)
            button.addTarget(self, action: #selector(addAction), for: .touchUpInside)
        } else {
            button.setTitle(filter.title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            button.setTitleColor(UIColor.ud.textTitle, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: padding, bottom: 0, right: 0)
            button.contentHorizontalAlignment = .left
            button.addTarget(self, action: #selector(clickAction(sender:)), for: .touchUpInside)

            if filter.type != .inbox, filter.type != .message {
                let closeBtn = UIButton(type: .custom)
                closeBtn.isUserInteractionEnabled = false
                closeBtn.setImage(Resources.filter_close, for: .normal)
                button.addSubview(closeBtn)
                closeBtn.snp.makeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.right.equalToSuperview().inset(10)
                    make.width.height.equalTo(12)
                }
            }
            titleWidthMap[filter.type] = filter.title.lu.width(font: UIFont.systemFont(ofSize: 16))
        }
        button.backgroundColor = UIColor.ud.bgFloat
        button.layer.cornerRadius = Cons.buttonCornerRadius
        button.layer.masksToBounds = true
        buttonMap[filter.type] = button
        return button
    }

    @objc
    func clickAction(sender: UIButton) {
        let index = sender.tag - 1000
        guard let currItem = self.item as? FeedCommonlyFilterModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        guard var filterItems = self.filterItems,
              index < filterItems.count else { return }
        let item = filterItems[index]
        if item.editEnable {
            filterItems.remove(at: index)
            setupItemsView(filterItems)
            currItem.tapHandler?(item.filterItem.type)
        }
    }

    @objc
    func addAction() {
        guard let currItem = self.item as? FeedCommonlyFilterModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        currItem.addHandler?()
    }

    enum Cons {
        static let verticalPadding: CGFloat = 12.0
        static let buttonCornerRadius: CGFloat = 16.0
    }
}

struct FeedFilterModel: FeedFilterSortItemProtocol {
    var cellIdentifier: String
    var filterItem: FilterItemModel
    let cellHeight: CGFloat = 48
    var title: String
    var subTitle: String?
    var style: UITableViewCell.EditingStyle
    var editEnable: Bool
    let moveEnable: Bool
    var jumpEnable: Bool = false
    var isLastRow: Bool = false
    var showEditBtn: Bool = false
    var tapHandler: (() -> Void)?
}

class FilterCell: FeedFilterSortBaseCell {
    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .left
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .left
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var editBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(Resources.icon_setting_outlined, for: .normal)
        button.isHidden = true
        button.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    var topOffSet: Float = 5

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(12)
            make.left.equalToSuperview().offset(9.38)
            make.right.equalToSuperview().inset(50)
        }

        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(topOffSet)
            make.left.equalTo(self.titleLabel.snp.left)
            make.right.equalToSuperview().inset(52)
            make.bottom.equalToSuperview().inset(12)
        }

        contentView.addSubview(editBtn)
        editBtn.addTarget(self, action: #selector(tapAction), for: .touchUpInside)
        editBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(20)
            make.width.height.equalTo(20)
        }

        bottomSeperator = lu.addBottomBorder(leading: Cons.leading)
    }

    override func setCellInfo() {
        guard let currItem = self.item as? FeedFilterModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = currItem.title
        editBtn.isHidden = !currItem.showEditBtn
        let image = currItem.jumpEnable ? Resources.icon_setting_outlined : Resources.icon_setting_outlined_disable
        editBtn.setImage(image, for: .normal)
        bottomSeperator?.isHidden = currItem.isLastRow
        let subTitle = currItem.subTitle ?? ""
        subtitleLabel.text = subTitle
        topOffSet = subTitle.isEmpty ? 0 : 5
        subtitleLabel.snp.updateConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(topOffSet)
            if currItem.showEditBtn {
                make.right.equalToSuperview().inset(52)
            } else {
                make.right.equalToSuperview().inset(12)
            }
        }
    }

    @objc
    func tapAction() {
        guard let currItem = self.item as? FeedFilterModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        currItem.tapHandler?()
    }

    enum Cons {
        static let leading: CGFloat = 48.0
    }
}

final class FilterRemoveDisableCell: FilterCell {
   lazy var disableView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = UDIcon.getIconByKey(.deleteDisableColorful, size: CGSize(width: 22, height: 22))
        return imageView
    }()

    // TODO: 稍微hack，后续待优化
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        for subviewOfCell in subviews {
            guard subviewOfCell.classForCoder.description() == "UITableViewCellEditControl",
                  let control = subviewOfCell as? UIControl,
                  let imageView = control.subviews.last as? UIImageView else { continue }
            control.isUserInteractionEnabled = false
            if !imageView.subviews.contains(disableView) {
                imageView.addSubview(disableView)
                disableView.snp.makeConstraints { (make) in
                    if #available(iOS 13.0, *) {
                        make.width.equalTo(imageView)
                        make.height.equalTo(imageView)
                    } else {
                        make.width.equalTo(imageView).offset(3)
                        make.height.equalTo(imageView).offset(3)
                    }
                    make.center.equalTo(imageView)
                }
            }
            break
        }
    }
}

struct FeedFilterMoreSetsModel: FeedFilterSortItemProtocol {
    var cellIdentifier: String
    let cellHeight: CGFloat = 48
    var isLastRow: Bool = false
    var title: String
    var tapHandler: () -> Void
}

final class FeedFilterMoreSetsCell: FeedFilterSortBaseCell {
    var tapHandler: (() -> Void)?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.bgFloat
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-45)
            make.top.bottom.equalToSuperview().inset(13)
        }

        let arrowImageView = UIImageView()
        arrowImageView.image = Resources.feed_right_arrow
        self.contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }

        self.lu.addTapGestureRecognizer(action: #selector(tapAction), target: self, touchNumber: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func tapAction() {
        guard let currItem = self.item as? FeedFilterMoreSetsModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        currItem.tapHandler()
    }

    override func setCellInfo() {
        guard let currItem = self.item as? FeedFilterMoreSetsModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = currItem.title
    }
}
