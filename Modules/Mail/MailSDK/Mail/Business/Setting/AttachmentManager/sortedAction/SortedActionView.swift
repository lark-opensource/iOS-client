//
//  SortedActionView.swift
//  MailSDK
//
//  Created by ByteDance on 2023/5/9.
//

import Foundation
import RxSwift
import UniverseDesignButton
import UniverseDesignIcon
import UniverseDesignFont
import FigmaKit
import LarkBlur

protocol SortedActionViewDelegate: AnyObject {
    func didClick(section: SortedActionSection)
    func didClickMask()
}

final class SortedActionView: UIButton {
    private var headerHeight: CGFloat {
        return 48
    }
    private var footerHeight: CGFloat {
        return 28
    }
    private let headerView = UIView()
    private let footerView = UIView()
    private let backgroundView = UIView()
    private let contentTableView = UITableView()
    private var closeButton = UIButton()
    private var titleHeaderLabel = UILabel()
    private var sectionData: [SortedActionSection]
    private var sectionHeight = [IndexPath: CGFloat]()
    weak var delegate: SortedActionViewDelegate?
    private let bag = DisposeBag()
    private var headerTitle: String
    
    init(frame: CGRect, title: String, sectionData: [SortedActionSection]) {
        self.sectionData = sectionData
        self.headerTitle = title
        super.init(frame: frame)
        setupViews(headerTitle: self.headerTitle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews(headerTitle: String) {
        backgroundColor = .clear
        addTarget(self, action: #selector(didClickMask), for: .touchUpInside)
        backgroundView.backgroundColor = UIColor.ud.bgBody
        addSubview(backgroundView)
        headerView.backgroundColor = UIColor.ud.bgBody
        footerView.backgroundColor = UIColor.ud.bgBody
        contentTableView.backgroundColor = UIColor.ud.bgBody
        backgroundView.addSubview(headerView)
        
        contentTableView.showsVerticalScrollIndicator = false
        contentTableView.separatorStyle = .none
        contentTableView.registerClass(SortedActionSectionCell.self)
        contentTableView.delaysContentTouches = false
        contentTableView.delegate = self
        contentTableView.dataSource = self
        contentTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.01))
        contentTableView.isScrollEnabled = false
        backgroundView.addSubview(contentTableView)
        backgroundView.addSubview(footerView)
        closeButton.setImage(UDIcon.closeSmallOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = UIColor.ud.iconN1
        closeButton.backgroundColor = .clear
        closeButton.layer.cornerRadius = 12
        closeButton.layer.masksToBounds = true
        closeButton.addTarget(self, action: #selector(didClickMask), for: .touchUpInside)
        headerView.addSubview(closeButton)
        titleHeaderLabel.textColor = UIColor.ud.textTitle
        titleHeaderLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        titleHeaderLabel.text = headerTitle
        headerView.addSubview(titleHeaderLabel)
        
        let sepLine = UIView()
        sepLine.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        headerView.addSubview(sepLine)
        sepLine.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(0.53)
            make.bottom.equalToSuperview().offset(-0.53)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(14)
            make.leading.equalTo(16)
            make.width.height.equalTo(24)
        }
        titleHeaderLabel.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.centerX.equalToSuperview()
        }
        
        headerView.snp.remakeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(headerHeight)
        }
        contentTableView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom).offset(4)
            make.left.right.bottom.equalToSuperview()
        }
        footerView.snp.makeConstraints { make in
            make.top.equalTo(contentTableView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.snp.remakeConstraints { (make) in
            var contentHeight = contentTableView.contentSize.height + contentTableView.frame.minY + footerHeight
            let startY = frame.height - contentHeight
            make.top.equalTo(startY)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        backgroundView.layoutIfNeeded()
        let maskPath = UIBezierPath.squircle(forRect: backgroundView.bounds,
                                             cornerRadii: [12.0, 12.0, 0, 0],
                                             cornerSmoothness: .natural)
        backgroundView.layer.ux.setMask(by: maskPath)
    }
    
    @objc
    private func didClickMask() {
        self.delegate?.didClickMask()
    }
}

extension SortedActionView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < sectionData.count else { return UITableViewCell() }
        var section = sectionData[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: SortedActionSectionCell.lu.reuseIdentifier) as? SortedActionSectionCell {
            cell.config(title: section.title, isSeleted: section.isSeleted)
            cell.updateBottomLine(isHidden: indexPath.row == sectionData.count - 1)
            return cell
        }
        return UITableViewCell()
    }
}

extension SortedActionView: UITableViewDelegate {
    func tableView(_ tableview: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableview.cellForRow(at: indexPath) != nil else {
            return }
        
        if !sectionData[indexPath.row].isSeleted {
            delegate?.didClick(section:sectionData[indexPath.row])
        }
    }
}

extension SortedActionView {
    func calculateHeightForPopover() -> CGFloat {
        var totalHeight: CGFloat = 0
        for section in sectionData {
            let cellHeight = SortedActionSectionCell.cellHeightFor(title: section.title, cellWidth: 320)
            totalHeight += cellHeight
        }
        totalHeight += 34 // 底部固定高度
        return totalHeight
    }
}
