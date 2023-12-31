//
//  LarkShareActionSheet.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/10/16.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import SnapKit
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import FigmaKit

protocol LarkShareActionSheetDelegate: AnyObject {
    func shareItemDidClick(actionSheet: LarkShareActionSheet, itemType: LarkShareItemType)
    func didClickCancel(actionSheet: LarkShareActionSheet)
}

/// 可供交互的自定义分享渠道面板
public final class LarkShareActionSheet: UIViewController {
    private weak var delegate: LarkShareActionSheetDelegate?
    private let shareTypes: [LarkShareItemType]
    private let transition = LarkShareActionSheetTransition()
    private let disposeBag = DisposeBag()

    private let shareInfoMapping: [LarkShareItemType: (UIImage, String)] = [
        .wechat: (Resources.share_icon_wechat, BundleI18n.LarkSnsShare.Lark_UserGrowth_TitleWechat),
        .weibo: (Resources.share_icon_weibo, BundleI18n.LarkSnsShare.Lark_UserGrowth_TitleWeibo),
        .qq: (Resources.share_icon_qq, BundleI18n.LarkSnsShare.Lark_UserGrowth_TitleQQ),
        .copy: (Resources.share_icon_copy, BundleI18n.LarkSnsShare.Lark_UserGrowth_InvitePeopleContactsShareToCopy),
        .more(.default): (Resources.share_icon_more, BundleI18n.LarkSnsShare.Lark_UserGrowth_InvitePeopleContactsShareToMore),
        .timeline: (Resources.share_icon_timeline, BundleI18n.LarkSnsShare.Lark_Invitation_SharePYQ),
        .save: (Resources.share_icon_save, BundleI18n.LarkSnsShare.Lark_Legacy_QrCodeSave)
    ]

    init(shareTypes: [LarkShareItemType], delegate: LarkShareActionSheetDelegate) {
        self.shareTypes = shareTypes
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = transition
        self.modalPresentationStyle = .custom
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        layoutPageSubviews()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.container.superview?.layoutIfNeeded()
        }) { (_) in
            self.maskContainerCoradius(self.container)
        }
    }

    @objc
    func cancel() {
        delegate?.didClickCancel(actionSheet: self)
        dismiss(animated: true, completion: nil)
    }

    private func layoutPageSubviews() {
        view.addSubview(topWrapper)
        view.addSubview(container)
        container.addSubview(scrollZone)
        container.addSubview(cancelButton)

        var safeAreaInsets: UIEdgeInsets?
        if #available(iOS 13.0, *) {
            if let window = self.view.window ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
               let scene = window.windowScene {
                let fullSize = scene.coordinateSpace.bounds.size
                safeAreaInsets = scene.windows.first(where: { $0.bounds.size == fullSize })?.safeAreaInsets
            }
        } else {
            safeAreaInsets = UIApplication.shared.delegate?.window??.safeAreaInsets
        }

        topWrapper.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(container.snp.top)
        }
        container.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            if let safeAreaInsets = safeAreaInsets {
                make.height.equalTo(178 + safeAreaInsets.bottom)
            } else {
                make.height.equalTo(178)
            }
            make.bottom.equalToSuperview().offset(0).priority(.high)
        }
        scrollZone.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(32)
            make.height.equalTo(130)
        }

        cancelButton.lu.addTopBorder(color: UIColor.ud.lineDividerDefault)
        cancelButton.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            if let safeAreaInsets = safeAreaInsets {
                make.bottom.equalToSuperview().offset(-safeAreaInsets.bottom)
            } else {
                make.bottom.equalToSuperview()
            }
            make.height.equalTo(48)
        }
        if let safeAreaInsets = safeAreaInsets {
            let whiteCoverButton = UIButton(frame: CGRect(x: 0,
                                            y: view.frame.height - safeAreaInsets.bottom,
                                            width: view.frame.width,
                                            height: safeAreaInsets.bottom))
            whiteCoverButton.backgroundColor = UIColor.ud.bgFloatBase
            whiteCoverButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
            view.addSubview(whiteCoverButton)
        }

        fillShareItems()
    }

    private func maskContainerCoradius(_ view: UIView) {
        let rect = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 192)
        let maskPath = UIBezierPath(roundedRect: rect,
                                    byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: 12, height: 12))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = rect
        maskLayer.path = maskPath.cgPath
        view.layer.mask = maskLayer
    }

    private func fillShareItems() {
        let margin = 18
        let size = 52
        for (i, item) in shareTypes.enumerated() {
            var icon: UIImage?
            var title: String?
            switch item {
            case .custom(let shareContext):
                icon = shareContext.itemContext.icon
                title = shareContext.itemContext.title
            default:
                icon = shareInfoMapping[item]?.0
                title = shareInfoMapping[item]?.1
            }
            let shareItem: ShareItem = ShareItem(icon: icon, title: title)
            shareItem.rx.controlEvent(.touchUpInside)
                .throttle(.milliseconds(200), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    guard let `self` = self else { return }
                    self.delegate?.shareItemDidClick(actionSheet: self, itemType: item)
                })
                .disposed(by: self.disposeBag)
            let originX = (i + 1) * margin + size * i
            shareItem.frame = CGRect(x: originX, y: 0, width: size, height: size)
            scrollZone.addSubview(shareItem)
        }

        scrollZone.contentSize = CGSize(width: shareTypes.count * size + (shareTypes.count + 1) * margin, height: 0)
        scrollZone.isScrollEnabled = scrollZone.contentSize.width > (self.view.bounds.size.width + 10)
    }

    private lazy var scrollZone: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.isScrollEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.bounces = false
        return view
    }()

    private lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloatBase
        maskContainerCoradius(view)
        return view
    }()

    private lazy var topWrapper: UIView = {
        let topWrapper = UIView(frame: .zero)
        let tap = UITapGestureRecognizer(target: self, action: #selector(cancel))
        topWrapper.addGestureRecognizer(tap)
        return topWrapper
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.ud.bgFloatBase
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        button.setTitle(BundleI18n.LarkSnsShare.Lark_Legacy_CancelOpen, for: .normal)
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        button.isHidden = Display.pad
        return button
    }()
}

private final class ShareItem: UIControl {
    init(icon: UIImage?, title: String?) {
        super.init(frame: .zero)
        layoutPageSubviews()
        iconView.image = icon
        titleLabel.text = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var squareView: SquircleView = {
        let view = SquircleView(frame: CGRect(x: 0, y: 0, width: 52, height: 52))
        view.backgroundColor = UIColor.ud.bgFloat
        view.cornerRadius = 12
        view.isUserInteractionEnabled = false
        return view
    }()

    lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .clear
        return view
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    func layoutPageSubviews() {
        addSubview(squareView)
        squareView.addSubview(iconView)
        addSubview(titleLabel)
        squareView.snp.makeConstraints { make in
            make.width.height.equalTo(52)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        iconView.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.centerX.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(squareView.snp.bottom).offset(8)
        }
    }
}
