//
//  MinutesKeyWordsView.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/12.
//  Copyright © 2021年 wangcong. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import MinutesNetwork
import UniverseDesignIcon

protocol MinutesKeyWordsViewDelegate: AnyObject {
    func keyWordsViewChangeStatus(_ view: MinutesKeyWordsView, shouldReload: Bool)
    func keyWordsView(_ view: MinutesKeyWordsView, didTap keyWord: String)
    func keyWordsViewBeginSearchKeywords()
}

class MinutesKeyWordsView: UICollectionView {

    private let tracker: MinutesTracker

    public var viewHeight: CGFloat {
        if viewModel.isClip {
            return 0
        }
        else if viewModel.isSupportASR {
            switch self.viewModel.viewStatus {
            case .shrink:
                return viewModel.shrinkHeight
            case .expand:
                return viewModel.expandHeight
            case .plain:
                return viewModel.shrinkHeight
            case .hiden:
                return 0
            }
        } else {
            return 0
        }
    }

    private var viewWidth: CGFloat {
        if viewModel.isClip {
            return 0
        } else {
            return viewModel.keywordsViewWidth
        }
    }
    
    var viewModel: MinutesKeyWordsViewModel

    weak var viewDelegate: MinutesKeyWordsViewDelegate?

    init(frame: CGRect, minutes: Minutes) {
        viewModel = MinutesKeyWordsViewModel(minutes: minutes)
        tracker = MinutesTracker(minutes: minutes)
        
        let layout = UICollectionViewLeftAlignedLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 8
        
        super.init(frame: .zero, collectionViewLayout: layout)
        
        self.backgroundColor = UIColor.ud.bgBody
        self.showsVerticalScrollIndicator = false
        self.dataSource = self
        self.delegate = self
        self.allowsSelection = true
        self.isScrollEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    public func unselectKeywords() {
        viewModel.clearKeyWordSelected()
        self.reloadData()
    }
    
    func configureDataAndUpdate(_ data: MinutesData) {
        viewModel.configureDataAndUpdate(data) { [weak self] in
            guard let self = self else {
                return
            }
            self.reloadData()
            self.viewDelegate?.keyWordsViewChangeStatus(self, shouldReload: true)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension MinutesKeyWordsView: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        switch viewModel.viewStatus {
        case .plain:
            return self.viewModel.data.count
        case .shrink:
            return self.viewModel.data.count
        case .expand:
            return self.viewModel.data.count
        case .hiden:
            return 0
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let keywordStatus = self.viewModel.data[indexPath.row]
            switch keywordStatus {
            case .data(let text, let isSelected):
                if !isSelected {
                    return collectionView.mins.dequeueReusableCell(with: MinutesKeyWordsFlowCollectionCell.self, for: indexPath) { cell in
                        cell.update(text: text)
                    }
                } else {
                    return collectionView.mins.dequeueReusableCell(with: MinutesKeyWordsFlowSelectedCollectionCell.self, for: indexPath) { cell in
                        cell.update(text: text)
                    }
                }
            }
    }
}

// MARK: - UICollectionViewDelegate / UICollectionViewDelegateFlowLayout
extension MinutesKeyWordsView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
        let status = viewModel.data[indexPath.item]
        switch status {
        case .data(let text, let isSelected):
            if text.isEmpty == false {
                viewModel.selectedItem(selectedIndex: indexPath.row, status: .plain)
                tapKeyWords(text: text)
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        let status = viewModel.data[indexPath.item]
        switch status {
        case .data(let text, let isSelected):
            var itemSize = text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)])
            if itemSize.width >= viewWidth - 8 {
                itemSize.width = viewWidth - 8
            }
            itemSize.width += 8
            itemSize.height = 20
            return itemSize
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    private func tapKeyWords(text: String) {
        tracker.tracker(name: .clickButton, params: ["action_name": "key_words"])
        tracker.tracker(name: .detailClick, params: ["click": "key_words", "target": "none"])

        self.reloadData()
        self.viewDelegate?.keyWordsView(self, didTap: text)
    }

    func tapExpandButton() {
        // 展开
        tracker.tracker(name: .detailClick, params: ["click": "unfold_keywords", "status": "unfold"])

        tracker.tracker(name: .clickButton, params: ["action_name": "key_words_more"])
        tracker.tracker(name: .detailClick, params: ["click": "key_words_more", "target": "none"])
        self.viewModel.viewStatus = .expand
        self.reloadData()
        self.viewDelegate?.keyWordsViewChangeStatus(self, shouldReload: true)
    }

    func tapShrinkButton() {
        // 收起
        tracker.tracker(name: .detailClick, params: ["click": "unfold_keywords", "status": "fold"])

        tracker.tracker(name: .clickButton, params: ["action_name": "key_words_less"])

        self.viewModel.viewStatus = .shrink
        self.reloadData()
        self.viewDelegate?.keyWordsViewChangeStatus(self, shouldReload: true)
    }
}

private class MinutesKeyWordsFlowCollectionCell: UICollectionViewCell {

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    private lazy var content: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBodyOverlay
        view.layer.cornerRadius = 6
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(content)
        content.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        content.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(text: String) {
        contentLabel.text = text
    }
}

private class MinutesKeyWordsFlowSelectedCollectionCell: UICollectionViewCell {

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.Y600
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.ud.setBackgroundColor(UIColor.ud.Y50)
        self.layer.cornerRadius = 6
        self.layer.borderWidth = 0.5
        self.layer.ud.setBorderColor(UIColor.ud.Y600)
        self.layer.masksToBounds = true

        self.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(text: String) {
        contentLabel.text = text
    }
}

private class MinutesKeyWordsMoreCollectionCell: UICollectionViewCell {

    private lazy var content: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBodyOverlay
        view.layer.cornerRadius = 6
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.image = UDIcon.getIconByKey(.avSetDownOutlined, iconColor: UIColor.ud.N800)
        iconImageView.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
        return iconImageView
    }()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                content.backgroundColor = UIColor.ud.Y400
                iconImageView.image = UDIcon.getIconByKey(.avSetDownOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill)
            } else {
                content.backgroundColor = UIColor.ud.bgBodyOverlay
                iconImageView.image = UDIcon.getIconByKey(.avSetDownOutlined, iconColor: UIColor.ud.textCaption)
            }
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class MinutesKeyWordsShrinkCollectionCell: UICollectionViewCell {

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.image = UDIcon.getIconByKey(.avSetUpOutlined, iconColor: UIColor.ud.N800)
        iconImageView.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
        return iconImageView
    }()

    private lazy var content: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBodyOverlay
        view.layer.cornerRadius = 6
        return view
    }()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                content.backgroundColor = UIColor.ud.Y400
                iconImageView.image = UDIcon.getIconByKey(.avSetUpOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill)
            } else {
                content.backgroundColor = UIColor.ud.bgBodyOverlay
                iconImageView.image = UDIcon.getIconByKey(.avSetUpOutlined, iconColor: UIColor.ud.N800)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class MinutesKeywordsSearchCell: UICollectionViewCell {

    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.image = UDIcon.getIconByKey(.searchOutlineOutlined, iconColor: UIColor.ud.primaryContentDefault)
        iconImageView.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
        return iconImageView
    }()

    lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor.ud.primaryContentDefault
        l.text = BundleI18n.Minutes.MMWeb_G_SearchKeywords
        return l
    }()

    private lazy var content: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBodyOverlay
        view.layer.cornerRadius = 6
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(content)
        content.addSubview(iconImageView)
        content.addSubview(titleLabel)
        createConstraints()
    }
    
    func createConstraints() {
        content.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        iconImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
            make.left.equalTo(9)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconImageView.snp.right).offset(4)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
