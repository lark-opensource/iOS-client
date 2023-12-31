//
//  WikiIPadSpaceCell.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2023/9/25.
//

import UniverseDesignColor
import UniverseDesignShadow
import UIKit
import RxSwift
import SKResource
import SKUIKit
import SKWorkspace
import SKInfra
import SKCommon
import SKFoundation

class WikiIPadSpaceCell: UICollectionViewCell, WikiSpaceCellRepresentable {
    private let disposeBag = DisposeBag()
    var reuseBag = DisposeBag()
    private var hoverGesture: UIGestureRecognizer?

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

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 3
        label.font = .systemFont(ofSize: 12, weight: .regular)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        if #available(iOS 13.0, *) {
            addCustomLift()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        if #available(iOS 13.0, *) {
            addCustomLift()
        }
    }

    private func setupUI() {
        layer.ud.setShadow(type: .s3Down)
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        contentView.addSubview(backgroundImageView)
        backgroundColor = .clear

        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let iconLabelSize = (iconLabel.text ?? "").estimatedMultilineUILabelSize(in: iconLabel.font,
                                                                                 maxWidth: contentView.frame.size.width,
                                                                                 expectLastLineFillPercentageAtLeast: nil)
        backgroundImageView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
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
            make.top.equalToSuperview().inset(28)
            make.left.right.equalToSuperview().inset(16)
        }

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
        }
    }

    // nolint: duplicated_code
    @available(iOS 13.0, *)
    private func addCustomLift() {
        let gesture = UIHoverGestureRecognizer()
        gesture.rx.event.subscribe(onNext: { [weak self] gesture in
            guard let self = self else { return }
            switch gesture.state {
            case .began, .changed:
                self.startHover()
            case .ended, .cancelled:
                self.endHover()
            default:
                break
            }
        }).disposed(by: disposeBag)
        hoverGesture = gesture
        contentView.addGestureRecognizer(gesture)
    }

    private func startHover() {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) { [weak self] in
            self?.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
            self?.layoutIfNeeded()
        }
    }

    private func endHover() {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) { [weak self] in
            self?.transform = .identity
            self?.layoutIfNeeded()
        }
    }

    func updateUI(item: WikiHomePageSpaceCollectionProtocol) {
        update(title: item.displayTitle)
        update(subtitle: item.displayDescription)
        let textColor = item.displayIsDarkStyle ? UDColor.primaryOnPrimaryFill : UDColor.textTitle.nonDynamic
        titleLabel.textColor = textColor
        descriptionLabel.textColor = textColor
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
                .subscribe(onNext: {[weak self] image in
                    self?.backgroundImageView.image = image
                }, onError: { error in
                    DocsLogger.error("get space thumbnail fail \(error)")
                })
                .disposed(by: reuseBag)
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

    private func update(title: String) {
        let attrbutedString = NSMutableAttributedString(string: title)
        let style = NSMutableParagraphStyle()
//        style.lineHeightMultiple = 1.07
        style.lineSpacing = 4
        attrbutedString.addAttribute(.paragraphStyle, value: style)
        titleLabel.attributedText = attrbutedString
    }

    private func update(subtitle: String) {
        let attrbutedString = NSMutableAttributedString(string: subtitle)
        let style = NSMutableParagraphStyle()
//        style.lineHeightMultiple = 1.07
        style.lineSpacing = 3
        attrbutedString.addAttribute(.paragraphStyle, value: style)
        descriptionLabel.attributedText = attrbutedString
    }

    func set(enable: Bool) {
        if enable {
            contentView.alpha = 1
        } else {
            contentView.alpha = 0.3
        }
    }
}
