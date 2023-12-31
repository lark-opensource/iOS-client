//
//  WikiHomePageSpaceViewCell.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/10/14.
//  

import UIKit
import SnapKit
import Kingfisher
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import RxSwift
import SKInfra
import SKWorkspace
/// 1x3 含封面布局
struct WikiSpaceCoverLayoutConfig: WikiHorizontalPagingLayoutConfig {

    let columnPerPage: CGFloat = 3

    let itemHorizontalInset: CGFloat = 6
    let itemVerticalInset: CGFloat = 4

    let sectionLeftInset: CGFloat = 12

    var itemWidthRatio: CGFloat? { nil }
    let itemWidth: CGFloat = 120
    var itemAspectRatio: CGFloat? { nil }
    let itemHeight: CGFloat = 160

    let shouldSnapToItem = true
    let shouldSnapToPage = false

    func rowCount(itemCount: Int) -> Int {
        if itemCount == 0 {
            return 0
        } else {
            return 1
        }
    }
}

/// 展示封面的知识库 cell
class WikiHomePageSpaceViewCell: UICollectionViewCell, WikiSpaceCellRepresentable {

    var reuseBag = DisposeBag()

    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
    }

    private lazy var backgroundImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .clear
        view.contentMode = .scaleAspectFill
        return view
    }()

    private lazy var iconLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UDColor.primaryOnPrimaryFill
        label.font = UIFont.ct.systemRegular(ofSize: 10)
        label.text = BundleI18n.SKResource.CreationMobile_Wiki_NewSpace_Public_tag
        label.sizeToFit()
        return label
    }()

    private lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 4
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()

    private lazy var starImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .clear
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        docs.addStandardLift()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        docs.addStandardLift()
    }

    private func setupUI() {
        contentView.layer.ud.setBorderColor(UDColor.lineDividerDefault)
        contentView.layer.borderWidth = 1
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        layer.shadowOffset = CGSize(width: 0, height: 12)
        layer.shadowRadius = 24
        layer.ud.setShadowColor(UDColor.shadowDefaultLg)
        layer.shadowOpacity = 1

        contentView.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }


        let iconLabelSize = (iconLabel.text ?? "").estimatedMultilineUILabelSize(in: iconLabel.font,
                                                                                 maxWidth: contentView.frame.size.width,
                                                                         expectLastLineFillPercentageAtLeast: nil)
        backgroundImageView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-1)
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        iconImageView.addSubview(iconLabel)
        iconLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.top.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-2)
            make.width.equalTo(iconLabelSize.width)
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(32)
            make.left.right.equalToSuperview().inset(8)
            make.bottom.lessThanOrEqualToSuperview().offset(-20)
        }
    }

    // nolint: duplicated_code
    func updateUI(item: WikiHomePageSpaceCollectionProtocol) {
        titleLabel.text = item.displayTitle
        let textColor = item.displayIsDarkStyle ? UDColor.primaryOnPrimaryFill : UDColor.textTitle.nonDynamic
        titleLabel.textColor = textColor
        contentView.backgroundColor = item.displayBackgroundColor
        backgroundImageView.image = nil
        if let url = item.displayBackgroundImageURL {
            let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)
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
                    self?.backgroundImageView.image = image
                }, onError: { error in
                    DocsLogger.error("get space thumbnail fail \(error)")
                })
                .disposed(by: reuseBag)
        }
        starImageView.isHidden = !item.displayIsStar
        if item.displayIsStar {
            starImageView.image = UDIcon.collectFilled.ud.withTintColor(UDColor.colorfulYellow)
        }

        if let displayTag = item.getDisplayTag(preferTagFromServer: true,
                                               currentTenantID: User.current.basicInfo?.tenantID) {
            iconLabel.text = displayTag
            iconImageView.isHidden = false
            iconLabel.isHidden = false
        } else {
            iconImageView.isHidden = true
            iconLabel.isHidden = true
        }
        let iconImage = BundleResources.SKResource.Common.Tool.icon_wiki_scope_tag_nor
        iconImageView.image = iconImage.ud.withTintColor(UDColor.functionInfoFillHover)
        let iconLabelSize = (iconLabel.text ?? "").estimatedMultilineUILabelSize(in: iconLabel.font,
                                                                         maxWidth: contentView.frame.size.width,
                                                                         expectLastLineFillPercentageAtLeast: nil)
        iconLabel.snp.updateConstraints { make in
            make.width.equalTo(iconLabelSize.width)
        }
    }

    func set(enable: Bool) {
        if enable {
            contentView.alpha = 1
        } else {
            contentView.alpha = 0.3
        }
    }
}
