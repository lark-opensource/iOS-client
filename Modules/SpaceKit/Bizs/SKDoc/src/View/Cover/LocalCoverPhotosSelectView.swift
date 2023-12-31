//
//  LocalCoverPhotosSelectView.swift
//  SKDoc
//
//  Created by lizechuang on 2021/2/1.
//

import Foundation
import SKResource
import UniverseDesignColor
import SKBrowser
import RichLabel
import SKFoundation
import LKRichView
import SKCommon

protocol LocalCoverPhotosSelectViewDelegate: AnyObject {
    func didSelectLocalCoverPhotoActionWith(_ action: LocalCoverPhotoAction)
    func didTapLinkActionWith(url: URL?)
}

class LocalCoverPhotosSelectView: UIView {

    weak var delegate: LocalCoverPhotosSelectViewDelegate?

    let actionList: [LocalCoverPhotoAction] = [.album, .takePhoto]
    
    static let tipMargin = 16

    lazy var tableView: UITableView = {
        return setupTableView()
    }()

    lazy var tipLabel: LKLabel = {
        return LKLabel()
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews()
    }
    
    override var frame: CGRect {
        didSet {
            // LKLabel有bug，转屏frame有变化时，link的位置没有更新，所以每次重新创建一个新的
            if oldValue.size.width != frame.size.width, frame != .zero {
                self.tipLabel.removeFromSuperview()
                self.tipLabel = constructTipLabel()
                self.addSubview(tipLabel)
                self.tipLabel.snp.makeConstraints { (make) in
                    make.top.equalTo(self.tableView.snp.bottom).offset(12)
                    make.left.right.equalToSuperview().inset(LocalCoverPhotosSelectView.tipMargin)
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubViews() {
        self.backgroundColor = UDColor.bgBase
        self.addSubview(tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.left.right.equalToSuperview()
            make.height.equalTo(48 * actionList.count)
        }
    }

    private func setupTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 48
        tableView.backgroundColor = UDColor.bgBody
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.tableFooterView = UIView()
        tableView.isScrollEnabled = false
        tableView.register(LocalCoverPhotosSelectViewCell.self, forCellReuseIdentifier: NSStringFromClass(LocalCoverPhotosSelectViewCell.self))
        return tableView
    }
    
    private func constructTipLabel() -> LKLabel {
        let label = LKLabel()
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = self.bounds.size.width - CGFloat(LocalCoverPhotosSelectView.tipMargin * 2)
        label.textAlignment = .center
        label.backgroundColor = .clear
        let fontSize = 12.0
        let text = BundleI18n.SKResource.CreationMobile_Docs_DocCover_MaxSize_Desc
        let linkText = BundleI18n.SKResource.LarkCCM_Docs_ForMoreInformation_LearnMore
        // 计算link是否需要在下一行展示，link不能拆行展示，分别计算有link和没有link时的高度，决定是否插入换行符
        let height = "\(text) ".getHeight(withConstrainedWidth: label.preferredMaxLayoutWidth, font: UIFont.systemFont(ofSize: fontSize))
        let heightWithLink = "\(text) \(linkText)".getHeight(withConstrainedWidth: label.preferredMaxLayoutWidth, font: UIFont.systemFont(ofSize: fontSize))
        var showText = ""
        var location = text.utf16.count + 1 // 后面有个空格
        if heightWithLink > height {
            showText = "\(text) \n\(linkText)"
            location += 1 // 增加了换行符
        } else {
            showText = "\(text) \(linkText)"
        }
        let linkRange = NSRange(location: location, length: linkText.utf16.count)
        let contentAttributeString = NSMutableAttributedString(
            string: showText,
            attributes: [
                .font: UIFont.systemFont(ofSize: fontSize),
                .foregroundColor: UDColor.textCaption])
        contentAttributeString.setAttributes(
            [NSAttributedString.Key.foregroundColor: UDColor.textLinkNormal],
            range: linkRange)
        label.attributedText = contentAttributeString
        var textlink = LKTextLink(range: linkRange,
                                   type: .link,
                             attributes: nil,
                       activeAttributes: [.backgroundColor: UIColor.clear])
        textlink.linkTapBlock = { [weak self] (_, _) in
            do {
                let url = try HelpCenterURLGenerator.generateURL(article: .coverHelpCenter)
                self?.delegate?.didTapLinkActionWith(url: url)
            } catch {
                DocsLogger.error("failed to generate helper center URL when constructTipLabel from coverHelpCenter", error: error)
            }
        }
        label.addLKTextLink(link: textlink)
        
        return label
    }
}

extension LocalCoverPhotosSelectView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actionList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(LocalCoverPhotosSelectViewCell.self)) as? LocalCoverPhotosSelectViewCell else {
            return UITableViewCell()
        }

        // cell统一设置separatorInset
        cell.separatorInset.left = (indexPath.row + 1 == actionList.count) ? 0.0 : 16.0
        if actionList[indexPath.row] == .album {
            cell.set(title: BundleI18n.SKResource.CreationMobile_Docs_DocCover_SelectFromAlbum_Button)
        } else {
            cell.set(title: BundleI18n.SKResource.CreationMobile_Docs_DocCover_TakePictures_Button)
        }
        return cell
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.didSelectLocalCoverPhotoActionWith(actionList[indexPath.row])
    }
}

class LocalCoverPhotosSelectViewCell: UITableViewCell {
    private lazy var titleLabel: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UDColor.bgBody

        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UDColor.textTitle
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String) {
        self.titleLabel.text = title
    }
}
