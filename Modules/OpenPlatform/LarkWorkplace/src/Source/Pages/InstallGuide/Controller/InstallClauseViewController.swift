//
//  InstallClauseViewController.swift
//  LarkWorkplace
//
//  Created by tujinqiu on 2020/3/23.
//

import LarkUIKit
import RichLabel

// 每一个app都是一个cell，cell中展示name，icon，高级权限，普通权限等
final class InstallClauseCell: UITableViewCell {
    var viewModel: InstallGuideAppViewModel?
    private let icon: WPMaskImageView = {
        let icon = WPMaskImageView()
        icon.layer.masksToBounds = true
        icon.sqRadius = WPUIConst.AvatarRadius.middle
        icon.sqBorder = WPUIConst.BorderW.pt1
        return icon
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        // font 使用 ud token 初始化
        // swiftlint:disable init_font_with_token
        label.font = UIFont.boldSystemFont(ofSize: 18)
        // swiftlint:enable init_font_with_token
        label.numberOfLines = 0
        return label
    }()
    private let descLabel: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.lineSpacing = 4
        return label
    }()
    private let basicLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    private let basicScopeLabel: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.lineSpacing = 6
        return label
    }()
    private let advancedLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    private let advancedScopeLabel: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.lineSpacing = 6
        return label
    }()
    private let separatorLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        contentView.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.size.equalTo(WPUIConst.AvatarSize.middle)
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(19)
        }

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(icon.snp.right).offset(12)
            make.centerY.equalTo(icon)
            make.right.equalToSuperview().offset(-16)
        }

        contentView.addSubview(descLabel)
        descLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(icon.snp.bottom).offset(14)
        }
        descLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        descLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)

        contentView.addSubview(basicLabel)
        basicLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(descLabel.snp.bottom).offset(12)
        }

        contentView.addSubview(basicScopeLabel)
        basicScopeLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(basicLabel.snp.bottom).offset(10)
        }

        contentView.addSubview(advancedLabel)
        advancedLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalTo(basicScopeLabel.snp.bottom).offset(16)
        }

        contentView.addSubview(advancedScopeLabel)
        advancedScopeLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(advancedLabel.snp.bottom).offset(10)
        }

        contentView.addSubview(separatorLine)
        separatorLine.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(advancedScopeLabel.snp.bottom).offset(18)
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
    }

    func updateModel(viewModel: InstallGuideAppViewModel, viewWidth: CGFloat) {
        self.viewModel = viewModel
        icon.bt.setLarkImage(
            with: .avatar(
                key: viewModel.app.iconKey ?? "",
                entityID: "",
                params: .init(sizeType: .size(42))
            )
        )
        nameLabel.text = viewModel.app.name
        showDesc(viewWidth: viewWidth)
        if viewModel.basicScopes.isEmpty {
            basicLabel.text = nil
            basicLabel.snp.updateConstraints { (make) in
                make.top.equalTo(descLabel.snp.bottom).offset(0)
            }
            basicScopeLabel.snp.updateConstraints { (make) in
                make.top.equalTo(basicLabel.snp.bottom).offset(0)
            }
        } else {
            basicLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideBasicPermission
            basicLabel.snp.updateConstraints { (make) in
                make.top.equalTo(descLabel.snp.bottom).offset(12)
            }
            basicScopeLabel.snp.updateConstraints { (make) in
                make.top.equalTo(basicLabel.snp.bottom).offset(10)
            }
        }
        showScopeLabel(label: basicScopeLabel, scopes: viewModel.basicScopes, level: .normal)
        if viewModel.advancedScopes.isEmpty {
            advancedLabel.text = nil
            advancedLabel.snp.updateConstraints { (make) in
                make.top.equalTo(basicScopeLabel.snp.bottom).offset(0)
            }
            advancedScopeLabel.snp.updateConstraints { (make) in
                make.top.equalTo(advancedLabel.snp.bottom).offset(0)
            }
        } else {
            advancedLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideAdvancedPermission
            advancedLabel.snp.updateConstraints { (make) in
                make.top.equalTo(basicScopeLabel.snp.bottom).offset(16)
            }
            advancedScopeLabel.snp.updateConstraints { (make) in
                make.top.equalTo(advancedLabel.snp.bottom).offset(10)
            }
        }
        showScopeLabel(label: advancedScopeLabel, scopes: viewModel.advancedScopes, level: .high)
    }

    private func showDesc(viewWidth: CGFloat) {
        descLabel.preferredMaxLayoutWidth = viewWidth - 16 * 2
        descLabel.removeLKTextLink()
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4
        let attrs = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
            NSAttributedString.Key.paragraphStyle: style
        ]
        let clause1 = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideClauseTipsPlaceholder1
        let clause2 = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideClauseTipsPlaceholder2
        let allStr = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideClauseTipsAll(clause1, clause2)
        let attrsStr = NSAttributedString(string: allStr, attributes: attrs)
        let range1 = (attrsStr.string as NSString).range(of: clause1)
        if range1.location != NSNotFound {
            var link = LKTextLink(
                range: range1,
                type: .link,
                attributes: [.foregroundColor: UIColor.ud.textLinkNormal],
                activeAttributes: [.foregroundColor: UIColor.ud.textLinkPressed]
            )
            link.linkTapBlock = { [weak self] (_, _) in
                self?.viewModel?.gotoPrivacy()
            }
            descLabel.addLKTextLink(link: link)
        }
        let range2 = (attrsStr.string as NSString).range(of: clause2)
        if range2.location != NSNotFound {
            var link = LKTextLink(
                range: range2,
                type: .link,
                attributes: [.foregroundColor: UIColor.ud.textLinkNormal],
                activeAttributes: [.foregroundColor: UIColor.ud.textLinkPressed]
            )
            link.linkTapBlock = { [weak self] (_, _) in
                self?.viewModel?.gotoUserClause()
            }
            descLabel.addLKTextLink(link: link)
        }
        descLabel.attributedText = attrsStr
    }

    private func showScopeLabel(label: LKLabel, scopes: [InstallGuideAppScope], level: InstallGuideAppLevel) {
        let iconSize = CGSize(width: 4, height: 4)
        var image = Resources.blue_dot
        image = image.bd_imageByResize(to: iconSize) ?? image
        image = image.ud.withTintColor(UIColor.ud.textPlaceholder)
        let muteAttrsStr = NSMutableAttributedString()
        scopes.forEach { (scope) in
            let icon = UIImageView()
            icon.frame = CGRect(origin: .zero, size: iconSize)
            icon.image = image
            let attachment = LKAttachment(view: icon)
            attachment.fontDescent = label.font.descender
            attachment.fontAscent = label.font.ascender
            attachment.verticalAlignment = .middle
            attachment.margin = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
            let attachmentStr = NSAttributedString(
                string: LKLabelAttachmentPlaceHolderStr,
                attributes: [LKAttachmentAttributeName: attachment]
            )
            muteAttrsStr.append(attachmentStr)
            let descAttrsStr = NSAttributedString(
                string: scope.desc ?? "",
                attributes: [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                    NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle
                ]
            )
            muteAttrsStr.append(descAttrsStr)
            muteAttrsStr.append(NSAttributedString(string: "\n"))
        }
        if scopes.isEmpty == false {
            let range = NSRange(location: muteAttrsStr.length - 1, length: 1)
            muteAttrsStr.replaceCharacters(in: range, with: NSAttributedString(string: ""))
        }
        label.attributedText = muteAttrsStr
    }
}

final class InstallClauseViewController: BaseUIViewController, UITableViewDataSource {
    private static let identifier = "InstallClauseCell"

    private let viewModel: InstallGuideViewModel
    private let selectedApps: [InstallGuideAppViewModel]
    private let viewWidth: CGFloat
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.register(InstallClauseCell.self, forCellReuseIdentifier: InstallClauseViewController.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        return tableView
    }()

    init(viewModel: InstallGuideViewModel, viewWidth: CGFloat) {
        self.viewModel = viewModel
        self.viewWidth = viewWidth
        self.selectedApps = viewModel.onboardingApps.compactMap({ (model) -> InstallGuideAppViewModel? in
            return model.isSelected ? model : nil
        })
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideClauseTitle

        setupSubviews()
    }

    private func setupSubviews() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedApps.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: InstallClauseViewController.identifier, for: indexPath)
        if let clauseCell = cell as? InstallClauseCell {
            let model = selectedApps[indexPath.row]
            clauseCell.updateModel(viewModel: model, viewWidth: self.viewWidth)
        }
        return cell
    }
}
