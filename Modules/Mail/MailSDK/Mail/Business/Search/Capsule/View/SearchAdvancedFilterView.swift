//
//  SearchAdvancedFilterView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/16.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignIcon
import RxSwift
import RxCocoa
import YYText
import LarkUIKit
import LarkFoundation

final class SearchAdvancedFilterView: UIView {

    private static let FilterHeaderHeight = 48.0
    private static let FilterItemHeight = 48.0
    private static let FilterTopMargin = 16.0
    private static let FilterBottomMargin = 27.0

    private var items = [MailSearchFilter]()

    let closeTapEvent = UITapGestureRecognizer()
    let resetFilterEvent = UITapGestureRecognizer()
    private let itemSelectSubject = PublishSubject<MailSearchFilter?>()

    private var containerWidth = UIDevice.btd_screenWidth()

    var itemSelect: Driver<MailSearchFilter?> {
        return itemSelectSubject.asDriver(onErrorJustReturn: nil)
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.showsVerticalScrollIndicator = true
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = SearchAdvancedFilterView.FilterItemHeight
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = nil
        tableView.tableFooterView = UIView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(FilterItemCell.self, forCellReuseIdentifier: "FilterItemCell")
        return tableView
    }()
    private let disposeBag = DisposeBag()

    init(frame: CGRect, dataSource: [MailSearchFilter]) {
        super.init(frame: frame)
        self.items += dataSource
        self.initSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has falset been implemented")
    }

    private func initSubViews() {
        clipsToBounds = true
        self.layer.cornerRadius = 12
        self.backgroundColor = UIColor.ud.bgFloatBase

        let headerView = UIView()
        let closeIcon = UIButton()
        closeIcon.setImage(UDIcon.closeSmallOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        closeIcon.tintColor = UIColor.ud.iconN1
        headerView.addSubview(closeIcon)
        closeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.height.width.equalTo(24)
            make.centerY.equalToSuperview()
        }
        closeIcon.addGestureRecognizer(self.closeTapEvent)

        let editLabel = UILabel()
        if self.hadSelectFilter() {
            editLabel.textColor = UIColor.ud.primaryPri500
            editLabel.isUserInteractionEnabled = true
            editLabel.addGestureRecognizer(self.resetFilterEvent)
        } else {
            editLabel.textColor = UIColor.ud.textDisabled
            editLabel.isUserInteractionEnabled = false
        }
        editLabel.text = BundleI18n.MailSDK.Mail_AdvancedSearch_ResetText
        editLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        headerView.addSubview(editLabel)
        editLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        let titleLable = UILabel()
        titleLable.text = BundleI18n.MailSDK.Mail_shared_FilterSearch_Filters_Mobile_Button
        titleLable.textColor = UIColor.ud.textTitle
        titleLable.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        headerView.addSubview(titleLable)
        titleLable.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let divider = UIView()
        divider.backgroundColor = UIColor.ud.lineDividerDefault
        headerView.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.leading.trailing.bottom.equalToSuperview()
        }

        self.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(SearchAdvancedFilterView.FilterHeaderHeight)
        }

        self.addSubview(self.tableView)
        let bottomSafeHeight = UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0.0
        self.tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(SearchAdvancedFilterView.FilterTopMargin)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-1 * bottomSafeHeight)
            make.height.equalTo(100)
        }
        self.tableView.rx.observe(CGSize.self, "contentSize")
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let maxHeight = self.tableViewMaxHeight()
                if maxHeight > 0 {
                    let height = min(self.tableView.contentSize.height, maxHeight)
                    self.tableView.snp.updateConstraints { make in
                        make.height.equalTo(height)
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    private func hadSelectFilter() -> Bool {
        return self.items.map({ $0.isEmpty }).contains(false)
    }

    private func safeBottomHeight() -> CGFloat {
        if #available(iOS 11.0, *) {
            return self.safeAreaInsets.bottom
        } else {
            return self.layoutMargins.bottom
        }
    }

    private func tableViewMaxHeight() -> CGFloat {
        guard let superview = superview else { return 0}
        let topSafeHeight = UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0.0
        let bottomSafeHeight = UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0.0
        let extraHeight = (SearchAdvancedFilterView.FilterHeaderHeight
                           + SearchAdvancedFilterView.FilterTopMargin
                           + bottomSafeHeight
                           + topSafeHeight)
        return superview.frame.size.height - extraHeight
    }
}

extension SearchAdvancedFilterView: ISearchPopupContentView {
    func updateContainerSize(size: CGSize) {
        if size.width > 0 && size.width != self.containerWidth {
            self.containerWidth = size.width
            self.tableView.reloadData()
        }
    }
}

extension SearchAdvancedFilterView: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else {
            return
        }
        self.itemSelectSubject.onNext(self.items[safe: indexPath.row])
    }
}

extension SearchAdvancedFilterView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilterItemCell", for: indexPath)
        if let itemCell = cell as? FilterItemCell {
            itemCell.containerWidth = self.containerWidth
            itemCell.item = self.items[safe: indexPath.row]
        }
        cell.contentView.layer.cornerRadius = 10
        if self.items.count == 1 {
            cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            cell.separatorInset = UIEdgeInsets(top: 0, left: self.bounds.size.width, bottom: 0, right: 0)
        } else if indexPath.row == 0 {
            cell.contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        } else if indexPath.row == self.items.count - 1 {
            cell.contentView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            cell.separatorInset = UIEdgeInsets(top: 0, left: self.bounds.size.width, bottom: 0, right: 0)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
            cell.contentView.layer.cornerRadius = 0
        }
        cell.contentView.clipsToBounds = true
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

private final class FilterItemCell: UITableViewCell {

    private static let FilterNameMaxWidth = 135.0
    private static let FilterIconWidth = 16
    private static let FilterTextMargin = 16
    private static let FilterIconMargin = 4
    private static let FilterTextDivider = 12

    var containerWidth = UIDevice.btd_screenWidth()

    private lazy var rightIcon: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.rightOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ud.iconN3
        return button
    }()

    private lazy var filterName: YYLabel = {
        let name = YYLabel()
        name.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        var color = UIColor.ud.textTitle
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                color = UIColor.ud.textTitle.alwaysDark
            } else {
                color = UIColor.ud.textTitle.alwaysLight
            }
        }
        name.textColor = color
        name.lineBreakMode = .byTruncatingTail
        name.preferredMaxLayoutWidth = FilterItemCell.FilterNameMaxWidth
        name.numberOfLines = 2
        return name
    }()

    private lazy var filterContent: YYLabel = {
        let name = YYLabel()
        name.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        var color = UIColor.ud.textCaption
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                color = UIColor.ud.textCaption.alwaysDark
            } else {
                color = UIColor.ud.textCaption.alwaysLight
            }
        }
        name.textColor = color
        name.lineBreakMode = .byTruncatingTail
        name.numberOfLines = 2
        return name
    }()

    var item: MailSearchFilter? {
        didSet {
            func getFilterContentMaxWidth() -> CGFloat {
                self.filterName.sizeToFit()
                let nameWidth = self.filterName.frame.size.width
                let leftWidth = min(nameWidth, self.filterName.preferredMaxLayoutWidth)
                // leftMargin * 2 - rightMargin * 2 - iconWidth - divider - iconMargin
                // leftMargin = rightMargin = iconWidth = 16
                // iconMargin = 4
                // divider = 12
                let extraMagin = FilterItemCell.FilterTextMargin * 5 + FilterItemCell.FilterTextDivider + FilterItemCell.FilterIconMargin
                let rightWidth = self.containerWidth - leftWidth - CGFloat(extraMagin)
                return rightWidth
            }

            func makeContentAttr(content: String) -> NSMutableAttributedString {
                let content = NSMutableAttributedString(string: content)
                content.yy_font = self.filterContent.font
                content.yy_color = self.filterContent.textColor
                return content
            }

            guard let newItem = self.item else {
                self.filterContent.text = nil
                return
            }
            let name = NSMutableAttributedString(string: newItem.name)
            name.yy_font = self.filterName.font
            name.yy_color = self.filterName.textColor
            self.filterName.attributedText = name

            let contentWidth = getFilterContentMaxWidth()
            self.filterContent.preferredMaxLayoutWidth = contentWidth
            self.filterContent.snp.updateConstraints { make in
                make.width.lessThanOrEqualTo(contentWidth)
            }

            if newItem.isEmpty {
                self.filterContent.text = nil
            } else {
                var complexCount: Int = newItem.avatarInfos.count
                if case let .general(.inputTextFilter(_, texts)) = newItem {
                    complexCount = texts.count
                }
                if complexCount > 1 {
                    let suffixStr = "+\(complexCount - 1)"
                    self.filterContent.text = newItem.content + suffixStr
                    self.filterContent.sizeToFit()
                    if self.filterContent.frame.width >= contentWidth * CGFloat(2) {
                        // 需要做省略
                        self.filterContent.attributedText = makeContentAttr(content: newItem.content + "…" + suffixStr)
                        self.filterContent.truncationToken = makeContentAttr(content: "…" + suffixStr)
                    } else {
                        self.filterContent.attributedText = makeContentAttr(content: newItem.content + suffixStr)
                        self.filterContent.truncationToken = nil
                    }
                } else {
                    self.filterContent.attributedText = makeContentAttr(content: newItem.content)
                    self.filterContent.truncationToken = makeContentAttr(content: "…")
                }
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.clear
        self.contentView.backgroundColor = UIColor.ud.bgFloat

        self.contentView.addSubview(self.filterName)
        self.contentView.addSubview(self.rightIcon)
        self.contentView.addSubview(self.filterContent)

        self.rightIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-1 * FilterItemCell.FilterTextMargin)
            make.width.height.equalTo(FilterItemCell.FilterIconWidth)
        }

        self.filterContent.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.lessThanOrEqualTo(200)
            make.trailing.equalTo(self.rightIcon.snp.leading).offset(-1 * FilterItemCell.FilterIconMargin)
            make.top.greaterThanOrEqualToSuperview().offset(14)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }

        self.filterName.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(FilterItemCell.FilterTextMargin)
            make.top.greaterThanOrEqualToSuperview().offset(14)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has falset been implemented")
    }

}
