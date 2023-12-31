//
//  MoreActionView.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2020/8/11.
//

import Foundation
import RxSwift
import UniverseDesignButton
import UniverseDesignIcon
import UniverseDesignFont
import FigmaKit
import LarkBlur

protocol MoreActionViewDelegate: AnyObject {
    func didClick(item: MailActionItemProtocol)
    func didClickMask()
}

final class MoreActionView: UIButton {
    private let headerHeight: CGFloat = 44
    private let strangerHeaderHeight: CGFloat = 48
    private let headerOffset: CGFloat = 12
    private let dismissOffset: CGFloat = 30
    private let contentHeaderOffset: CGFloat = 16

    private let closeButtonLength: CGFloat = 22

    private let dragView = UIView()
    private let headerView = UIView()
    private let contentTableView = InsetTableView()

    private var dragIndicator: UIView?

    private let draggable: Bool

    private let backgroundView = UIView()

    private var closeButton = UIButton()

    private var maxContentHeight: CGFloat = 0
    private let maxStartHeight: CGFloat = Display.height * 0.75

    private var startY: CGFloat = -1

    private var lastDragY: CGFloat = 0
    private var lastStayY: CGFloat = 0

    private let sectionData: [MoreActionSection]
    private var headerConfig: MoreActionHeaderConfig?
    private var sectionHeight = [IndexPath: CGFloat]()

    weak var delegate: MoreActionViewDelegate?
    private let bag = DisposeBag()

    override func layoutSubviews() {
        super.layoutSubviews()
        resetHeight()
        backgroundView.layoutIfNeeded()
        let maskPath = UIBezierPath.squircle(forRect: backgroundView.bounds,
                                             cornerRadii: [12.0, 12.0, 0, 0],
                                             cornerSmoothness: .natural)
        backgroundView.layer.ux.setMask(by: maskPath)
    }

    init(frame: CGRect, draggable: Bool, headerConfig: MoreActionHeaderConfig?, sectionData: [MoreActionSection]) {
        self.draggable = draggable
        self.sectionData = sectionData
        self.headerConfig = headerConfig
        super.init(frame: frame)
        setupViews(headerConfig: self.headerConfig)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews(headerConfig: MoreActionHeaderConfig?) {
        backgroundColor = .clear
        addTarget(self, action: #selector(didClickMask), for: .touchUpInside)

        backgroundView.backgroundColor = UIColor.ud.bgFloatBase
        addSubview(backgroundView)

        headerView.backgroundColor = UIColor.ud.bgFloatBase
        backgroundView.addSubview(headerView)

        contentTableView.showsVerticalScrollIndicator = false
        contentTableView.separatorStyle = .none
        contentTableView.registerClass(MoreActionVerticalItemCell.self)
        contentTableView.registerClass(MoreActionVerticalStatusItemCell.self)
        contentTableView.registerClass(MoreActionVerticalSwitchItemCell.self)
        contentTableView.delaysContentTouches = false
        contentTableView.delegate = self
        contentTableView.dataSource = self
        contentTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.01))
        contentTableView.estimatedSectionFooterHeight = 100
        contentTableView.sectionFooterHeight = UITableView.automaticDimension
        backgroundView.addSubview(contentTableView)

        closeButton.isHidden = (headerConfig == nil)

        if let headerConfig = headerConfig {
            if headerConfig.stranger {
                closeButton.setImage(UDIcon.getIconByKey(.closeSmallOutlined, size: CGSize(width: 40, height: 40)).withRenderingMode(.alwaysTemplate), for: .normal)
                closeButton.imageView?.contentMode = .scaleAspectFill
                closeButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            } else {
                closeButton.setImage(UDIcon.getIconByKey(.closeBoldOutlined, size: CGSize(width: 28, height: 28)).withRenderingMode(.alwaysTemplate), for: .normal)
                closeButton.backgroundColor = UIColor.ud.N300
                closeButton.layer.cornerRadius = closeButtonLength / 2
                closeButton.layer.masksToBounds = true
                closeButton.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
            }
            closeButton.tintColor = UIColor.ud.iconN1
            closeButton.addTarget(self, action: #selector(didClickMask), for: .touchUpInside)
            headerView.addSubview(closeButton)
            
            let iconView: UIView
            switch headerConfig.iconType {
            case .image(let image):
                iconView = UIImageView(image: image)
                iconView.contentMode = .scaleAspectFit
                iconView.layer.cornerRadius = headerHeight / 2
                iconView.layer.masksToBounds = true
                //iconView.tintColor = UIColor.ud.colorfulIndigo
            case .avatar(let userId, let name):
                let tempImageView = MailAvatarImageView()
                tempImageView.backgroundColor = UIColor.ud.N300
                tempImageView.loadAvatar(name: name, entityId: userId, setBackground: true)
                iconView = tempImageView
                iconView.layer.cornerRadius = headerHeight / 2
                iconView.layer.masksToBounds = true
            case .text(let text, backgroundColor: let backgroundColor):
                let label = UILabel()
                label.text = text
                label.textColor = UIColor.ud.primaryOnPrimaryFill
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 17)
                label.backgroundColor = backgroundColor
                iconView = label
                iconView.layer.cornerRadius = headerHeight / 2
                iconView.layer.masksToBounds = true
            case .imageWithoutCorner(let image):
                iconView = UIImageView(image: image)
                iconView.contentMode = .scaleAspectFit
            }

            let labelContainerView = UIView()
            labelContainerView.backgroundColor = .clear
            headerView.addSubview(labelContainerView)

            headerView.addSubview(iconView)
            iconView.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.top.equalTo(labelContainerView)
                make.size.equalTo(CGSize(width: headerHeight, height: headerHeight))
            }
            

            labelContainerView.snp.makeConstraints { (make) in
                make.top.equalToSuperview()
                make.right.equalToSuperview().offset(-16)
                make.left.equalTo(iconView.snp.right).offset(8)
                make.height.equalTo(headerHeight)
            }

            let titleLabel = UILabel()
            labelContainerView.addSubview(titleLabel)
            titleLabel.textColor = UIColor.ud.textTitle
            titleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
            titleLabel.text = headerConfig.title

            if headerConfig.stranger {
                labelContainerView.snp.remakeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                iconView.isHidden = true
                titleLabel.textAlignment = .center
                closeButton.snp.makeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.leading.equalTo(6)
                    make.width.height.equalTo(40)
                }
            } else {
                closeButton.snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(1)
                    make.trailing.equalTo(-17)
                    make.width.height.equalTo(closeButtonLength)
                }
            }
            if !closeButton.isHidden && !headerConfig.stranger {
                let subtitleLabel = UILabel()
                labelContainerView.addSubview(subtitleLabel)
                subtitleLabel.textColor = UIColor.ud.textCaption
                subtitleLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                subtitleLabel.text = headerConfig.subtitle
                subtitleLabel.lineBreakMode = .byTruncatingTail

                subtitleLabel.snp.makeConstraints { (make) in
                    make.left.bottom.equalToSuperview()
                    make.right.equalTo(closeButton.snp.left).offset(-9)
                    make.height.equalTo(18)
                }
                titleLabel.snp.makeConstraints { (make) in
                    make.top.left.equalToSuperview()
                    make.right.equalTo(subtitleLabel.snp.right)
                    make.height.equalTo(24)
                    make.bottom.equalTo(subtitleLabel.snp.top).offset(2)
                }
            } else if headerConfig.stranger {
                titleLabel.snp.makeConstraints { (make) in
                    make.center.equalToSuperview()
                    make.height.equalTo(24)
                }
            } else {
                titleLabel.snp.makeConstraints { (make) in
                    make.right.top.left.bottom.equalToSuperview()
                }
            }

            let sepLine = UIView()
            sepLine.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
            headerView.addSubview(sepLine)
            sepLine.snp.makeConstraints { make in
                make.width.equalToSuperview()
                make.height.equalTo(0.53)
                make.bottom.equalToSuperview().offset(-0.53)
            }

            let contentOffsetView = UIView()
            contentOffsetView.backgroundColor = UIColor.ud.bgFloatBase
            backgroundView.addSubview(contentOffsetView)
            contentOffsetView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(headerView.snp.bottom)
                make.height.equalTo(contentHeaderOffset)
            }

            contentTableView.snp.makeConstraints { (make) in
                make.top.equalTo(contentOffsetView.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
            headerView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                if headerConfig.stranger {
                    make.top.equalToSuperview()
                    make.height.equalTo(strangerHeaderHeight)
                } else {
                    make.top.equalToSuperview().offset(headerOffset)
                    make.height.equalTo(headerHeight + headerOffset)
                }
            }
        } else {
            headerView.snp.remakeConstraints { (make) in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(contentHeaderOffset)
            }
            contentTableView.snp.makeConstraints { (make) in
                make.top.equalTo(headerView.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        }
        headerView.bringSubviewToFront(closeButton)
    }

    private func resetHeight() {
        let safeBottom = Display.oldSeries() ? 16 : Display.bottomSafeAreaHeight
        var contentHeight = contentTableView.contentSize.height + contentTableView.frame.minY + safeBottom
        if Display.pad {
            contentHeight -= safeBottom
        }
        maxContentHeight = min(contentHeight, bounds.height)

        if maxContentHeight > maxStartHeight {
            // can scroll
            dragIndicator?.isHidden = false
            dragView.isUserInteractionEnabled = true
            if headerConfig == nil {
                headerView.snp.updateConstraints { (make) in
                    make.height.equalTo(contentHeaderOffset)
                }
            } else {
                headerView.snp.updateConstraints { (make) in
                    make.top.equalToSuperview().offset(headerOffset)
                }
            }
        } else {
            // cant scroll
            dragIndicator?.isHidden = true
            dragView.isUserInteractionEnabled = false
        }

        let startHeight = min(maxContentHeight, maxStartHeight)
        let newStartY = draggable ? frame.height - startHeight : 0
        if newStartY != startY {
            self.startY = newStartY
            backgroundView.snp.remakeConstraints { (make) in
                make.top.equalTo(self.startY)
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }
    }

    @objc
    private func didClickMask() {
        self.delegate?.didClickMask()
    }
}

extension MoreActionView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let view = view as? UITableViewHeaderFooterView else { return }
        view.textLabel?.textColor = UIColor.ud.textCaption
    }
  
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section != 0 {
            return 12
        } else {
            return 0.01
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section != 0 else { return nil }
        let header = UIView()
        header.backgroundColor = UIColor.ud.bgFloatBase

//        let line = UIView.init(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0.5))
//        line.backgroundColor = UIColor.ud.lineDividerDefault
//        header.addSubview(line)

        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionData.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sectionData[section]
        switch section.layout {
        case .vertical:
            return section.items.count
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = sectionHeight[indexPath] {
            return height
        } else {
            let section = sectionData[indexPath.section]
            let cellHeight: CGFloat
            switch section.layout {
            case .vertical:
                if let item = section.items[indexPath.item] as? MailActionItem {
                    let cellWidth = (tableView as? InsetTableView)?.insetLayoutGuide.layoutFrame.width ?? tableView.bounds.width
                    cellHeight = MoreActionVerticalItemCell.cellHeightFor(title: item.title, cellWidth: cellWidth)
                } else if let item = section.items[indexPath.item] as? MailActionStatusItem {
                    let cellWidth = (tableView as? InsetTableView)?.insetLayoutGuide.layoutFrame.width ?? tableView.bounds.width
                    cellHeight = MoreActionVerticalStatusItemCell.cellHeightFor(title: item.title, status: item.status, cellWidth: cellWidth)
                } else if let item = section.items[indexPath.item] as? MailActionSwitchItem {
                    let cellWidth = (tableView as? InsetTableView)?.insetLayoutGuide.layoutFrame.width ?? tableView.bounds.width
                    cellHeight = MoreActionVerticalSwitchItemCell.cellHeightFor(title: item.title, cellWidth: cellWidth)
                } else {
                    cellHeight = 0
                }
            }
            sectionHeight[indexPath] = cellHeight
            return cellHeight
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < sectionData.count else { return UITableViewCell() }
        
        let section = sectionData[indexPath.section]
        let item = section.items[indexPath.row]
        switch section.layout {
        case .vertical:
            switch item.displayType {
            case .iconWithText:
                if let cell = tableView.dequeueReusableCell(withIdentifier: MoreActionVerticalItemCell.reuseIdentifier, for: indexPath) as? MoreActionVerticalItemCell,
                   let item = item as? MailActionItem {
                    cell.setup(title: item.title, icon: item.icon, disable: item.disable, tintColor: item.tintColor)
                    cell.updateBottomLine(isHidden: indexPath.row == section.items.count - 1)
                    return cell
                }
                return UITableViewCell()
            case .textWithStatus:
                if let cell = tableView.dequeueReusableCell(withIdentifier: MoreActionVerticalStatusItemCell.reuseIdentifier, for: indexPath) as? MoreActionVerticalStatusItemCell,
                   let item = item as? MailActionStatusItem {
                    cell.setup(title: item.title, status: item.status)
                    cell.updateBottomLine(isHidden: indexPath.row == section.items.count - 1)
                    return cell
                }
                return UITableViewCell()
            case .textWithSwitch:
                if let cell = tableView.dequeueReusableCell(withIdentifier: MoreActionVerticalSwitchItemCell.reuseIdentifier, for: indexPath) as? MoreActionVerticalSwitchItemCell,
                   let item = item as? MailActionSwitchItem {
                    cell.setup(title: item.title, status: item.status, switchHandler: item.actionCallBack)
                    cell.updateBottomLine(isHidden: indexPath.row == section.items.count - 1)
                    return cell
                }
                return UITableViewCell()
            }
        }
    }
}

extension MoreActionView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        let items = sectionData[indexPath.section]
        let item = items.items[indexPath.row]
        if !item.disable {
            delegate?.didClick(item: item)
        }
    }
}

extension MoreActionView {
    func calculateHeightForPopover(hasHeader: Bool) -> CGFloat {
        var totalHeight: CGFloat = 0
        let insetMargin: CGFloat = 8
        for section in sectionData {
            switch section.layout {
            case .vertical:
                var cellWidth = contentTableView.insetLayoutGuide.layoutFrame.width
                if cellWidth == 0 {
                    cellWidth = 320 - 16 - 16
                }
                for sectionItem in section.items {
                    if let item = sectionItem as? MailActionItem {
                        let cellHeight = MoreActionVerticalItemCell.cellHeightFor(title: item.title, cellWidth: cellWidth) + insetMargin
                        totalHeight += cellHeight
                    } else if let item = sectionItem as? MailActionStatusItem {
                        let cellHeight = MoreActionVerticalStatusItemCell.cellHeightFor(title: item.title, status: item.status, cellWidth: cellWidth)
                        totalHeight += cellHeight
                    }
                }
            }
        }
        if hasHeader {
            totalHeight = totalHeight + headerHeight + contentHeaderOffset
        } else {
            totalHeight += contentHeaderOffset
        }
        return totalHeight
    }
}
