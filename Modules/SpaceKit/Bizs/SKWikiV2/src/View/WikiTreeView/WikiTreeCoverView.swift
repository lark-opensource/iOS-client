//
//  WikiTreeCoverView.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/12/20.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKResource
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignTag
import UniverseDesignNotice
import SKFoundation
import SKSpace
import SnapKit
import UIKit
import SKInfra
import SKWorkspace
import LarkContainer
import SpaceInterface
import UniverseDesignTheme


class WikiTreeCoverView: UIView {
    private var space: WikiSpace
    lazy var imageBackgroundView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = space.displayBackgroundColor
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    let bag = DisposeBag()
    
    lazy var uploadView = DriveUploadContentView()
    var didClickUploadView: (() -> Void)?

    private lazy var maskBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05) & .clear
        return view
    }()

    private lazy var publicTag: UDTag = {
        let config = UDTagConfig.TextConfig(cornerRadius: 4,
                                            textColor: UDColor.udtokenTagNeutralTextInverse,
                                            backgroundColor: UDColor.functionSuccessFillHover)
        let tag = UDTag(text: "",
                        textConfig: config)
        tag.isHidden = true
        return tag
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .medium)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.numberOfLines = 2
        titleLabel.text = space.spaceName
        titleLabel.textColor = space.displayIsDarkStyle ? UDColor.primaryOnPrimaryFill : UDColor.staticBlack
        return titleLabel
    }()
    
    private(set) lazy var migrateNotice: UDNotice = {
        let title = NSAttributedString(string: BundleI18n.SKResource.CreationMobile_Wiki_Upgrade_UnableToProceedTree)
        var noticeConfig = UDNoticeUIConfig(type: .info, attributedText: title)
        noticeConfig.leadingButtonText = BundleI18n.SKResource.CreationMobile_Wiki_Upgrade_LearnMore
        let notice = UDNotice(config: noticeConfig)
        notice.delegate = self
        return notice
    }()
    
    private let clickMigrateTipRelay = PublishRelay<Void>()
    var clickMigrateTipEvent: Signal<Void> {
        clickMigrateTipRelay.asSignal()
    }

    private lazy var seperatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    private let actuallyView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    init(space: WikiSpace, frame: CGRect) {
        self.space = space
        super.init(frame: frame)
        setupUI()
        update(space: space)
    }

    func update(space: WikiSpace) {
        self.space = space
        updateImage()
        titleLabel.text = space.spaceName
        titleLabel.textColor = space.displayIsDarkStyle ? UDColor.primaryOnPrimaryFill : UDColor.staticBlack
        update(migrating: space.migrateStatus == .migrating)
        
        updateTag(space: space)
    }

    private func updateTag(space: WikiSpace) {
        let textConfig = UDTagConfig.TextConfig(cornerRadius: 4,
                                                textColor: UDColor.udtokenTagNeutralTextInverse,
                                                backgroundColor: UDColor.functionInfoFillHover)
        publicTag.updateUI(textConfig: textConfig)
        if let customTag = space.getDisplayTag(preferTagFromServer: true,
                                               currentTenantID: User.current.basicInfo?.tenantID) {
            publicTag.text = customTag
            publicTag.isHidden = false
        } else {
            publicTag.isHidden = true
        }
    }

    private func setupUI() {
        addSubview(imageBackgroundView)
        imageBackgroundView.frame = frame

        imageBackgroundView.addSubview(maskBackgroundView)
        maskBackgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        imageBackgroundView.addSubview(migrateNotice)
        migrateNotice.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
            make.bottom.equalToSuperview()
        }

        imageBackgroundView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(28)
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top).offset(WikiTreeCoverViewController.coverTreeNavHeight)
            make.bottom.equalTo(migrateNotice.snp.top).offset(-20 - 30 - 5)
        }

        imageBackgroundView.addSubview(publicTag)
        publicTag.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.left)
            make.bottom.equalTo(migrateNotice.snp.top).offset(-24)
        }

        self.addSubview(actuallyView)
        actuallyView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(68)
        }
        
        actuallyView.addSubview(uploadView)
        uploadView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview()
            make.height.equalTo(48)
        }

        imageBackgroundView.addSubview(seperatorLine)
        seperatorLine.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        updateImage()
        setupUploadView()
    }

    func updateImage() {
        let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)
        if let url = space.coverImageURL {
            let request = SpaceThumbnailManager.Request(token: "",
                                                        info: .unencryptOnly(unencryptURL: url),
                                                        source: .wikiSpace,
                                                        fileType: .wiki,
                                                        placeholderImage: nil,
                                                        failureImage: nil,
                                                        processer: SpaceDefaultProcesser())
            manager?.getThumbnail(request: request)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: {[weak self] image in
                    self?.imageBackgroundView.image = image
                }, onError: { error in
                    DocsLogger.error("get space thumbnail fail \(error)")
                })
                .disposed(by: bag)
        }
    }
    
    func update(migrating: Bool) {
        if migrating {
            migrateNotice.isHidden = false
        } else {
            migrateNotice.isHidden = true
        }
    }
    
    func estimatedContentHeight(for containerWidth: CGFloat) -> CGFloat {
        let fixContentHeight: CGFloat = 144
        if migrateNotice.isHidden {
            return fixContentHeight
        }
        let size = CGSize(width: containerWidth, height: .infinity)
        let noticeHeight = migrateNotice.sizeThatFits(size).height
        return fixContentHeight + ceil(noticeHeight)
    }
    
    func refreshNoticeLayout() {
        if migrateNotice.isHidden {
            migrateNotice.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        } else {
            let size = CGSize(width: frame.width, height: .infinity)
            let noticeHeight = migrateNotice.sizeThatFits(size).height
            migrateNotice.snp.updateConstraints { make in
                make.height.equalTo(noticeHeight)
            }
            migrateNotice.update()
        }
    }
    
    func showUploadView(_ show: Bool) {
        self.actuallyView.isHidden = !show
        self.uploadView.isHidden = !show
        let inset = show ? 68 : 0
        migrateNotice.snp.updateConstraints { make in
            make.bottom.equalToSuperview().inset(inset)
        }
    }
    
    func updateUploadView(item: DriveStatusItem) {
        self.uploadView.update(item)
    }
    
    private func setupUploadView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapUpload))
        uploadView.addGestureRecognizer(tap)
    }
    
    @objc
    private func didTapUpload() {
        didClickUploadView?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 封面顶部的「导航栏」
class WikiTreeCoverNavigationBar: UIView {
    private var isDarkStyle: Bool
    private var isStar: Bool
    let backBtn = UIButton()
    
    let myAIBtn = UIButton()
    let searchBtn = UIButton()
    
    let starBtn = UIButton()
    let detailBtn = UIButton()
    let closeBtn = UIButton()
    
    
    private var buttonPanelView: UIStackView = {
        let view = UIStackView()
        view.spacing = 16
        view.alignment = .center
        view.axis = .horizontal
        return view
    }()
    
    private var leadingButtonPanelView: UIStackView = {
        let view = UIStackView()
        view.spacing = 16
        view.alignment = .center
        view.axis = .horizontal
        return view
    }()
    
    private var iconColor: UIColor {
        return isDarkStyle ? UDColor.primaryOnPrimaryFill : UDColor.iconN1.nonDynamic
    }

    init(isDarkStyle: Bool, isStar: Bool) {
        self.isDarkStyle = isDarkStyle
        self.isStar = isStar
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(isDarkStyle: Bool, isStar: Bool) {
        self.isDarkStyle = isDarkStyle
        self.isStar = isStar
        
        let backImage = UDIcon.leftOutlined.ud.withTintColor(iconColor)
        let closeImage = UDIcon.closeOutlined.ud.withTintColor(iconColor)
        backBtn.setImage(backImage, for: .normal)
        closeBtn.setImage(closeImage, for: .normal)
        
        myAIBtn.setImage(myAIItemIconForCover, for: .normal)
        
        let searchImage = UDIcon.searchOutlineOutlined.ud.withTintColor(iconColor)
        searchBtn.setImage(searchImage, for: .normal)
        let starImage = isStar ? UDIcon.collectFilled.ud.withTintColor(UDColor.colorfulYellow) :
                                 UDIcon.collectionOutlined.ud.withTintColor(iconColor)
        starBtn.setImage(starImage, for: .normal)
        let detailImage = UDIcon.infoOutlined.ud.withTintColor(iconColor)
        detailBtn.setImage(detailImage, for: .normal)
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(buttonPanelView)
        buttonPanelView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
        
        // leading button
        addSubview(leadingButtonPanelView)
        leadingButtonPanelView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        /// back按钮
        let backImage = UDIcon.leftOutlined.ud.withTintColor(iconColor)
        backBtn.setImage(backImage, for: .normal)
        backBtn.docs.addHighlight(with: .init(top: -6, left: -10, bottom: -6, right: -10), radius: 8)
        leadingButtonPanelView.addArrangedSubview(backBtn)
        backBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
        /// 适配主导航的close按钮
        let closeImage = UDIcon.closeOutlined.ud.withTintColor(iconColor)
        closeBtn.setImage(closeImage, for: .normal)
        closeBtn.docs.addHighlight(with: .init(top: -6, left: -10, bottom: -6, right: -10), radius: 8)
        leadingButtonPanelView.addArrangedSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerX.equalToSuperview()
        }
        closeBtn.isHidden = true    //  默认隐藏，仅主导航下会展示
        
        // tarling button
        myAIBtn.setImage(myAIItemIconForCover, for: .normal)
        myAIBtn.docs.addHighlight(with: .init(top: -6, left: -10, bottom: -6, right: -10), radius: 8)
        buttonPanelView.addArrangedSubview(myAIBtn)
        myAIBtn.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
        myAIBtn.isHidden = true

        let searchImage = UDIcon.searchOutlineOutlined.ud.withTintColor(iconColor)
        searchBtn.setImage(searchImage, for: .normal)
        searchBtn.docs.addHighlight(with: .init(top: -6, left: -10, bottom: -6, right: -10), radius: 8)
        buttonPanelView.addArrangedSubview(searchBtn)
        searchBtn.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
        
        let starImage = isStar ? UDIcon.collectFilled.ud.withTintColor(UDColor.colorfulYellow) :
                                 UDIcon.collectionOutlined.ud.withTintColor(iconColor)
        starBtn.setImage(starImage, for: .normal)
        starBtn.docs.addHighlight(with: .init(top: -6, left: -10, bottom: -6, right: -10), radius: 8)
        starBtn.isHidden = true
        buttonPanelView.addArrangedSubview(starBtn)
        starBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }

        let detailImage = UDIcon.infoOutlined.ud.withTintColor(iconColor)
        detailBtn.setImage(detailImage, for: .normal)
        detailBtn.docs.addHighlight(with: .init(top: -6, left: -10, bottom: -6, right: -10), radius: 8)
        detailBtn.isHidden = true
        buttonPanelView.addArrangedSubview(detailBtn)
        detailBtn.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
    }
    
    func showMoreItems() {
        detailBtn.isHidden = false
    }
    
    func showMyAIItem() {
        myAIBtn.isHidden = false
    }
    
    func hiddenBarRightItems() {
        starBtn.isHidden = true
        searchBtn.isHidden = true
        detailBtn.isHidden = true
    }
    
    var myAIItemIconForCover: UIImage {
        return isDarkStyle ? UDIcon.chatAiOutlined.ud.withTintColor(UDColor.primaryOnPrimaryFill) : UDIcon.chatAiColorful
    }

}

extension WikiTreeCoverView: UDNoticeDelegate {
    /// 右侧文字按钮点击事件回调
    func handleLeadingButtonEvent(_ button: UIButton) {
        clickMigrateTipRelay.accept(())
    }

    /// 右侧图标按钮点击事件回调
    func handleTrailingButtonEvent(_ button: UIButton) {}

    /// 文字按钮/文字链按钮点击事件回调
    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {}
}
