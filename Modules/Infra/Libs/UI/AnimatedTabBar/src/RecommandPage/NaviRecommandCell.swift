//
//  NaviRecommandItemView.swift
//  AnimatedTabBar
//
//  Created by phoenix on 2023/11/3.
//

import UIKit
import LarkTab
import ByteWebImage
import RxCocoa
import RxSwift
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor
import LarkExtensions
import RustPB
import LarkLocalizations
import LKCommonsLogging
import LarkContainer
import LarkDocsIcon

/// 展示单条 "推荐应用” 的 Cell
final class NaviRecommandCell: UICollectionViewCell {

    static let logger = Logger.log(NaviRecommandCell.self, category: "Module.AnimatedTabBar")

    private var userResolver: UserResolver?

    private var isInNavigation: Bool = false

    private var addHandler: ((UIButton) -> Void)?
    
    private var item: RustPB.Basic_V1_NavigationAppInfo?

    private let disposeBag = DisposeBag()

    // 图标
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 6
        imageView.layer.masksToBounds = true
        return imageView
    }()

    // 标题
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body0
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    // 标题
    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body2
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    // 添加按钮
    private lazy var addButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.AnimatedTabBar.Lark_Core_More_AddApp_Button, for: .normal)
        button.titleLabel?.font = UIFont.ud.body1
        button.setTitleColor(UIColor.ud.primaryPri500, for: .normal)
        button.backgroundColor = UDColor.N900.withAlphaComponent(0.05)
        button.layer.cornerRadius = 6
        return button
    }()

    func config(userResolver: UserResolver, item: RustPB.Basic_V1_NavigationAppInfo, isInNavigation: Bool, addEvent: ((UIButton) -> Void)? = nil) {
        self.userResolver = userResolver
        self.item = item
        self.isInNavigation = isInNavigation
        self.addHandler = addEvent
        self.updateUI()
        self.loadImage(userResolver: userResolver, item: item) { [weak self] (image) in
            guard let self = self else { return }
            self.imageView.image = image
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleLabel)
        contentView.addSubview(addButton)
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.leading.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
        }
        addButton.snp.makeConstraints { make in
            make.width.equalTo(60)
            make.height.equalTo(28)
            make.trailing.equalToSuperview().offset(-24)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(12)
            make.trailing.equalTo(addButton.snp.leading).offset(-12)
            make.top.equalToSuperview().offset(7)
            make.height.equalTo(24)
        }
        subTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(12)
            make.trailing.equalTo(addButton.snp.leading).offset(-12)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.bottom.equalTo(-7)
        }
        addButton.hitTestEdgeInsets = .init(top: -10, left: -10, bottom: -10, right: -10)
        addButton.addTarget(self, action: #selector(didTapAddButton), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTapAddButton() {
        addHandler?(addButton)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        titleLabel.text = nil
    }
}

extension NaviRecommandCell {
    // 根据数据模型更新UI
    func updateUI() {
        // 如果改推荐应用已经在主导航了，那么添加按钮显示为打开
        if self.isInNavigation {
            addButton.setTitle(BundleI18n.AnimatedTabBar.Lark_Navbar_Open_Mobile_Button, for: .normal)
        } else {
            addButton.setTitle(BundleI18n.AnimatedTabBar.Lark_Core_More_AddApp_Button, for: .normal)
        }
        // 刷新标题
        let lang = LanguageManager.currentLanguage.rawValue.lowercased()
        let defaultName = self.item?.name["en_us"] ?? ""
        titleLabel.text = self.item?.name[lang] ?? defaultName
        subTitleLabel.text = self.item?.subtitle
        if self.item?.subtitle.isEmpty ?? true {
            subTitleLabel.isHidden = true
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(imageView.snp.trailing).offset(12)
                make.trailing.equalTo(addButton.snp.leading).offset(-12)
                make.centerY.equalToSuperview()
                make.height.equalTo(24)
            }
        } else {
            subTitleLabel.isHidden = false
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(imageView.snp.trailing).offset(12)
                make.trailing.equalTo(addButton.snp.leading).offset(-12)
                make.top.equalToSuperview().offset(7)
                make.height.equalTo(24)
            }
            subTitleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(imageView.snp.trailing).offset(12)
                make.trailing.equalTo(addButton.snp.leading).offset(-12)
                make.top.equalTo(titleLabel.snp.bottom).offset(2)
                make.bottom.equalTo(-7)
            }
        }
    }

    // 根据图标类型加载图片，注意基本都是异步获取，所以要考虑数据模型变化的时候如何通知业务刷新UI
    func loadImage(userResolver: UserResolver, item: RustPB.Basic_V1_NavigationAppInfo, success: @escaping (UIImage) -> Void) {
        let candidate = item.transferToTabContainable()
        let tabIcon: TabCandidate.TabIcon = candidate.icon
        let placeHolder = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.iconN3)
        switch tabIcon.type {
        case .iconInfo:
            // 如果是ccm iconInfo图标
            if let docsService = try? userResolver.resolve(assert: DocsIconManager.self) {
                docsService.getDocsIconImageAsync(iconInfo: tabIcon.content, url: candidate.url, shape: .SQUARE)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (image) in
                        success(image)
                    }, onError: { error in
                        Self.logger.error("<NAVIGATION_BAR> get docs icon image error", error: error)
                    }).disposed(by: self.disposeBag)
            } else {
                Self.logger.error("<NAVIGATION_BAR> can't resolver DocsIconManager")
            }
        case .udToken:
            // 如果是UD图片
            let image = UDIcon.getIconByString(tabIcon.content) ?? placeHolder
            success(image)
        case .byteKey, .webURL:
            // 如果是ByteImage或者网络图片
            var resource: LarkImageResource
            if tabIcon.type == .byteKey {
                let (key, entityId) = tabIcon.parseKeyAndEntityID()
                resource = .avatar(key: key ?? "", entityID: entityId ?? "")
            } else {
                resource = .default(key: tabIcon.content)
            }
            // 获取图片资源
            LarkImageService.shared.setImage(with: resource, completion:  { (imageResult) in
                var image = placeHolder
                switch imageResult {
                case .success(let r):
                    if let img = r.image {
                        image = img
                    } else {
                        Self.logger.error("<NAVIGATION_BAR> LarkImageService get image result is nil!!! tabIcon content = \(tabIcon.content)")
                    }
                case .failure(let error):
                    Self.logger.error("<NAVIGATION_BAR> LarkImageService get image failed!!! tabIcon content = \(tabIcon.content), error = \(error)")
                }
                success(image)
            })
        @unknown default:
            break
        }
    }
}

