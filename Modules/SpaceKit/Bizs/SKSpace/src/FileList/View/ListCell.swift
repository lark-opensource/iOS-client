//
//  DocsFileCell.swift
//  Alamofire
//
//  Created by weidong fu on 22/11/2017.

import UIKit
import SnapKit
import CryptoSwift
import Kingfisher
import RxSwift
import RxCocoa
import SKCommon
import SKUIKit
import UniverseDesignColor
import SKResource
import SKInfra

protocol ListCellDelegate: AnyObject {
    func didClickPermTip(at index: Int?, of cell: ListCell)
}


public class ListCell: SlideableCell {
    var iconImageViewWidth: CGFloat {
        40
    }
    
    var mainTitleOffsetY: CGFloat {
        12
    }

    public var enableAlpha: Bool = false
    public var showStarEnable: Bool = false
    weak var listCellDelegate: ListCellDelegate?
    var model: ListCellViewModel?
    var index: Int?
    private var reuseBag = DisposeBag()
    
    // 当前主title的布局信息
    var mainTitleLabelCenterY: Bool?

    /// shortcut
    lazy var shortCutImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.contentMode = .center
        imageView.image = BundleResources.SKResource.Space.DocsType.icon_shortcut_left_bottom_tip
        return imageView
    }()
    /// cell 左边的类型icon
    lazy var displayImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.contentMode = .center
        imageView.layer.cornerRadius = 6
        imageView.clipsToBounds = true
        return imageView
    }()
    /// cell 自定义icon
    lazy var iconImageView: AvatarImageView = {
        let imageView = AvatarImageView(frame: CGRect.zero)
        imageView.contentMode = .top
        return imageView
    }()
    lazy public var mainTitleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.docs.pfsc(17)
        label.textColor = UDColor.textTitle
        label.backgroundColor = .clear
        label.numberOfLines = 1
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return label
    }()
    lazy var subTitle: ListCellSyncStatusSubTitle = {
        let view = ListCellSyncStatusSubTitle(frame: CGRect.zero)
        return view
    }()

    lazy var permTipButton: UIButton = {
        let permTipButton = UIButton()
        permTipButton.addTarget(self, action: #selector(handlePanPermTip(_:)), for: .touchUpInside)
        return permTipButton
    }()

    // 包括外部标签、alpha标签、权限按钮、收藏
    var strechContainer: ListCellStrechContainer = {
        let view = ListCellStrechContainer()
        view.backgroundColor = UIColor.clear
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        container.addSubview(strechContainer)
        container.addSubview(displayImageView)
        container.addSubview(shortCutImageView)
        container.addSubview(iconImageView)
        container.addSubview(mainTitleLabel)
        container.addSubview(subTitle)
        container.addSubview(permTipButton)

        displayImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: iconImageViewWidth, height: iconImageViewWidth))
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
        }
        iconImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: iconImageViewWidth, height: iconImageViewWidth))
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
        }
        iconImageView.layer.cornerRadius = iconImageViewWidth / 2.0
        iconImageView.layer.masksToBounds = true

        shortCutImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 12, height: 12))
            make.leading.equalTo(displayImageView.snp.leading)
            make.bottom.equalTo(displayImageView.snp.bottom)
        }


        strechContainer.snp.makeConstraints { (make) in
            make.centerY.equalTo(mainTitleLabel.snp.centerY)
            make.right.lessThanOrEqualTo(permTipButton.snp.left).offset(-16)
            make.height.equalTo(16)
        }
        
        permTipButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-22)
            make.width.height.equalTo(20)
        }
        permTipButton.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        
        setupSubTitleVerticalConstraints()
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSubTitleVerticalConstraints() {
        mainTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(mainTitleOffsetY)
            make.left.equalTo(displayImageView.snp.right).offset(12)
            make.right.equalTo(strechContainer.snp.left).offset(-6)
        }

        subTitle.snp.makeConstraints { (make) in
            make.left.equalTo(mainTitleLabel.snp.left)
            make.top.equalTo(mainTitleLabel.snp.bottom).offset(6)
            make.right.equalTo(container).offset(-16)
        }
    }

    @objc
    func handlePanPermTip(_ gesture: UIPanGestureRecognizer) {
        listCellDelegate?.didClickPermTip(at: index, of: self)
    }
    
    public func apply(model: ListCellViewModel) {
        self.model = model
        container.alpha = enable ? 1.0 : 0.3
        if enable, let file = model.file {
            setSlideAction(actions: delegate?.getSlideAction(for: file, source: model.source))
        }
        configTitle(model: model)
        strechContainer.showTemplateTag = model.showTemplateTag
        strechContainer.showExternal = model.showExternalLabel
        shortCutImageView.isHidden = !model.isShortCut
        strechContainer.showStar = model.showStarButton
        swipeEnbale = model.enableSwipe
        if model.showPermTipButton {
            permTipButton.setImage(model.permTipButtonImage, for: .normal)
        }
        configIcon(iconType: model.iconType)
        
        resetmainTitleLabelConstriants(centerY: !model.showSubTitle)
        updatePermTipButtonConstraints(showPermTips: model.showPermTipButton)
        
        // subtitle
        configSyncStatusAndSubTitle(model: model)
    }
}

extension ListCell {
    private func configIcon(iconType: SpaceList.IconType) {
        displayImageView.isHidden = true
        iconImageView.isHidden = true
        switch iconType {
        case let .icon(image, _):
            displayImageView.isHidden = false
            displayImageView.contentMode = .scaleAspectFill
            displayImageView.image = image
        case let .newIcon(data):
            iconImageView.set(avatarKey: data.iconKey,
                              fsUnit: data.fsUnit,
                              placeholder: data.placeHolder,
                              image: nil) { _ in }
            iconImageView.isHidden = false
        case let .thumbIcon(thumbInfo):
            displayImageView.isHidden = false
            let processer: SpaceThumbnailProcesser = SpaceListIconProcesser()
            let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)!
            let request = SpaceThumbnailManager.Request(token: thumbInfo.token,
                                                        info: thumbInfo.thumbInfo,
                                                        source: thumbInfo.source,
                                                        fileType: thumbInfo.fileType,
                                                        placeholderImage: thumbInfo.placeholder,
                                                        failureImage: thumbInfo.failedImage,
                                                        processer: processer)
            manager.getThumbnail(request: request)
                .asDriver(onErrorJustReturn: thumbInfo.placeholder ?? UIImage())
                .drive(onNext: { [weak self] (image) in
                    self?.displayImageView.contentMode = .scaleAspectFill
                    self?.displayImageView.image = image
                })
                .disposed(by: reuseBag)
        }
    }
    
    private func configSyncStatusAndSubTitle(model: ListCellViewModel) {
        /// 下面是设置 同步状态图片和subTitle的
        subTitle.configSyncStatusAndSubTitle(syncConfig: model.synConfig,
                                             showSubTitle: model.showSubTitle,
                                             subTitleString: model.subTitle)
    }
    
    private func configTitle(model: ListCellViewModel) {
        if let title = model.attributeTitle, title.length > 0 {
            mainTitleLabel.attributedText = title
        } else {
            mainTitleLabel.text = model.mainTitle
        }
    }
    
    private func updatePermTipButtonConstraints(showPermTips: Bool) {
        if permTipButton.isHidden == true, showPermTips == false { return }
        if permTipButton.isHidden == false, showPermTips == true { return }
        permTipButton.isHidden = !showPermTips
        permTipButton.snp.updateConstraints { (make) in
            make.width.equalTo(showPermTips ? 20 : 0)
            make.right.equalToSuperview().offset(showPermTips ? -22 : 0)
        }
    }
    
    func resetmainTitleLabelConstriants(centerY: Bool = false) {
        guard  mainTitleLabelCenterY != centerY else { return }
        mainTitleLabelCenterY = centerY
        
        mainTitleLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(displayImageView.snp.right).offset(12)
            make.right.equalTo(strechContainer.snp.left).offset(-6)
            if centerY {
                make.centerY.equalToSuperview()
            } else {
                make.top.equalTo(mainTitleOffsetY)
            }
        }
        /// 布局改变会导致 line break 失效，因此需要刷新一下 break line
        mainTitleLabel.lineBreakMode = .byTruncatingTail
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        cancelCell(animated: false)
        enable = true
        setSlideAction(actions: nil)
        reuseBag = DisposeBag()
    }

}

extension ListCell: CellReuseIdentifier {}
