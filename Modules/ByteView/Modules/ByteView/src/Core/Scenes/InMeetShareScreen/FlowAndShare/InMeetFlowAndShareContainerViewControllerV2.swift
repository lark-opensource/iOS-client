//
//  InMeetFlowAndShareContainerViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2022/6/17.
//

import Foundation
import RxSwift
import UIKit
import UniverseDesignColor
import SnapKit

protocol InMeetFlowAndShareProtocol: UIViewController {
    var shareVideoView: UIView? { get }
    var shareBottomView: UIView? { get }
    var shareBottomBackgroundView: UIView? { get }

    var singleTapGestureRecognizer: UITapGestureRecognizer? { get set }

    var parentContainerGuide: UILayoutGuide { get }
    var contentLayoutGuide: UILayoutGuide { get }
    var bottomBarLayoutGuide: UILayoutGuide { get }
}

class InMeetFlowAndShareContainerViewControllerV2: InMeetFlowViewControllerV2 {

    let shareScreenContentLayoutGuide = UILayoutGuide()
    let shareScreenBottomBarLayoutGuide = UILayoutGuide()
    private let shareBarGuide = UILayoutGuide()

    private weak var layoutContainer: InMeetLayoutContainer?
    private var isAttachedToFloatContainer: Bool = false {
        didSet {
            guard self.isAttachedToFloatContainer != oldValue else {
                return
            }
            updateShareVCAttached()
        }
    }
    private var isShareVCVisible: Bool = false {
        didSet {
            guard self.isShareVCVisible != oldValue else {
                return
            }
            updateShareVCAttached()
        }
    }

    private var _shareScreenVC: InMeetFlowAndShareProtocol?
    var shareScreenVC: InMeetFlowAndShareProtocol {
        assert(_shareScreenVC != nil, "InMeetFlowAndShareContainerViewController init without InMeetShareScreenVC!")
        return _shareScreenVC!
    }
    var shareScreenView: UIView { shareScreenVC.view }

    private let hasShrinkView: Bool
    lazy var shareScreenShrinkView: InMeetFlowShrinkView = {
        let view = InMeetFlowShrinkView(service: viewModel.meeting.service)
        view.backgroundView.backgroundColor = UIColor.ud.vcTokenMeetingBgVideoOff
        view.backgroundView.alpha = 0.92
        return view
    }()

    let shareScreenPageControl: FlexiblePageControl = {
        let config = FlexiblePageControl.Config(dotSize: 4, dotSpace: 3, smallDotSize: 2.5, enableMove: false)
        let pageControl = FlexiblePageControl(config: config)
        pageControl.numberOfPages = 2
        pageControl.currentPageIndicatorTintColor = UIColor.ud.primaryContentDefault
        pageControl.pageIndicatorTintColor = UIColor.ud.iconDisabled
        pageControl.backgroundColor = UIColor.ud.bgFloat.withAlphaComponent(0.8)
        pageControl.layer.cornerRadius = 4
        pageControl.clipsToBounds = true
        return pageControl
    }()

    var shareScreenPageControlOriginalFrame: CGRect?
    var pageControlOriginalFrame: CGRect?

    var shareScreenShrinkViewConstrait: Constraint?


    weak var guideView: GuideView?

    init(gridViewModel: InMeetGridViewModel, shareVC: InMeetFlowAndShareProtocol, hasShrinkView: Bool) {
        self.hasShrinkView = hasShrinkView
        _shareScreenVC = shareVC
        super.init(nibName: nil, bundle: nil)
        self.viewModel = gridViewModel
        addChild(shareVC)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    deinit {
        if let viewController = _shareScreenVC, viewController.parent === self {
            (viewController as UIViewController).vc.removeFromParent()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addLayoutGuide(shareScreenContentLayoutGuide)
        view.addLayoutGuide(shareScreenBottomBarLayoutGuide)
        view.addLayoutGuide(shareBarGuide)
        view.addSubview(shareScreenPageControl)

        updateBackgroundColor()

//        pageControl.hidesForSinglePage = false
        pageControl.alpha = 0

        bindSharePageControl()
        bindShareShrinkView()

        setupOnBoarding()
    }

    func setupOnBoarding() {
        guard viewModel.service.shouldShowGuide(.landscapeSharescreen) else {
            return
        }
        let guideView = self.guideView ?? GuideView(frame: view.bounds)
        self.guideView = guideView
        let refView = UIView()
        if guideView.superview == nil {
            view.addSubview(guideView)
            guideView.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
            view.addSubview(refView)
            refView.snp.makeConstraints {
                $0.top.right.bottom.equalToSuperview()
                $0.width.equalToSuperview().dividedBy(3).offset(-80)
            }
        }
        // disable-lint: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1500)) {
            UIView.animate(withDuration: 0.3) {
                self.collectionView.contentOffset.x = self.collectionView.bounds.size.width / 3
                self.shareScreenPageControl.isHidden = true
            } completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    guideView.setStyle(.plain(content: I18n.View_MV_SwipeToViewVideo),
                                       on: .left,
                                       of: refView)
                    guideView.sureAction = { [weak self] _ in
                        self?.viewModel.service.didShowGuide(.landscapeSharescreen)
                        self?.guideView?.removeFromSuperview()
                        self?.guideView = nil
                        refView.removeFromSuperview()
                    }
                }
            }
        }
        // enable-lint: magic number
    }

    func updateBackgroundColor() {
        shareScreenVC.view.backgroundColor = UIColor.ud.bgBase
        shareScreenVC.shareVideoView?.backgroundColor = UIColor.ud.bgBase
    }

    func bindSharePageControl() {
        self.pageObservable
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { [weak self] (pages) in
                guard let self = self else {
                    return
                }
                self.shareScreenPageControl.numberOfPages = pages
                if self.shareScreenPageControl.currentPage >= pages - 1 && pages > 0 {
                    self.shareScreenPageControl.setCurrentPage(at: pages - 1, animated: true)
                }
                self.shareScreenPageControlOriginalFrame = nil
            })
            .disposed(by: rx.disposeBag)
    }

    func bindShareShrinkView() {
        guard hasShrinkView else { return }
        viewModel.shrinkViewSpeakingUser
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] speakingUserName, showFocusPrefix in
                guard let name = speakingUserName else {
                    self?.shareScreenShrinkView.setSpeakerUserName(nil)
                    return
                }
                if showFocusPrefix {
                    self?.shareScreenShrinkView.setFocusingUserName(name)
                } else {
                    self?.shareScreenShrinkView.setSpeakerUserName(name)
                }
            })
            .disposed(by: rx.disposeBag)
    }

    override func updatePageControlLayout() {
        pageControl.snp.remakeConstraints {
            $0.centerX.equalToSuperview()
            if Display.iPhoneXSeries {
                $0.bottom.equalToSuperview().inset(14.5)
            } else {
                $0.bottom.equalToSuperview().inset(1.5)
            }
        }
    }

    override func updateMeetingLayoutStyle() {
        super.updateMeetingLayoutStyle()
        updateShareScreenPageControl()
        updateShareLayoutGuide()
        adaptBottomShadow()
        shareScreenPageControlOriginalFrame = nil
        pageControlOriginalFrame = nil
    }

    func updateShareLayoutGuide() {
        guard collectionView.bounds.size.width > 0,
              shareScreenView.superview != nil,
              shareScreenVC.bottomBarLayoutGuide.canUse(on: self.view) else {
            return
        }

        let isOverlayFullScreen = viewModel.context.meetingLayoutStyle != .tiled
        let shrinkOffset: CGFloat = hasShrinkView ? 15.0 : 0.0

        shareScreenView.snp.remakeConstraints {
            $0.left.right.bottom.equalToSuperview()
            if isOverlayFullScreen {
                $0.top.equalToSuperview().offset(shrinkOffset)
            } else {
                $0.top.equalToSuperview().offset(44 + shrinkOffset)
            }
        }

        if hasShrinkView {
            shareScreenShrinkView.snp.remakeConstraints {
                $0.left.right.equalToSuperview()
                $0.height.equalTo(15)
                if self.viewModel.context.meetingLayoutStyle == .fullscreen {
                    $0.top.equalTo(0).priority(.low)
                } else {
                    $0.top.equalTo(44).priority(.low)
                }
                if isOverlayFullScreen && self.shrinkViewConstraitIsValid {
                    shareScreenShrinkViewConstrait = $0.top.equalTo(shareScreenContentLayoutGuide).constraint
                }
            }
        }

        shareScreenVC.bottomBarLayoutGuide.snp.remakeConstraints {
            $0.edges.equalTo(shareScreenBottomBarLayoutGuide)
        }

        shareScreenVC.parentContainerGuide.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }
        if let view = shareScreenVC.contentLayoutGuide.owningView?.superview {
            shareScreenVC.contentLayoutGuide.snp.remakeConstraints {
                $0.left.top.right.equalToSuperview()
                $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            }
        }
    }

    func updateShareScreenPageControl() {
        guard collectionView.bounds.size.width > 0 else { return }
        self.loadViewIfNeeded()

        let point = collectionView.contentOffset
        let pageWidth = collectionView.bounds.size.width
        let offsetX = point.x
        pageControl.setProgress(contentOffsetX: offsetX, pageWidth: pageWidth)
        shareScreenPageControl.setProgress(contentOffsetX: offsetX, pageWidth: pageWidth)

        if shrinkViewConstraitIsValid {
            // 由于shareView能横向滑动，需要在滑动时禁用纵向Constraint，防止抖动
            if offsetX == 0 {
                shareScreenShrinkViewConstrait?.activate()
            } else {
                shareScreenShrinkViewConstrait?.deactivate()
            }
        }

        shareScreenPageControl.snp.remakeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(8)
            if self.meetingLayoutStyle != .fullscreen && self.shareScreenVC.shareBottomView != nil {
                $0.bottom.equalTo(shareBarGuide.snp.top).offset(-2.0)
            } else {
                $0.centerY.equalTo(pageControl)
            }
        }

        // 滑动过 2/3 屏时开启渐变过渡
        let switchPageWidth = pageWidth / 3
        var ratio = (offsetX - switchPageWidth * 2) / switchPageWidth
        ratio = max(0, min(1, ratio))
        // 过渡曲线 y = x^10
        let alpha = pow(ratio, 10.0)
        pageControl.alpha = alpha
        shareScreenPageControl.alpha = 1 - alpha

        if viewModel.context.meetingLayoutStyle == .fullscreen {
            // nolint-next-line: magic number
            let shareOriginY = pageControl.frame.origin.y - 1.5
            if shareScreenPageControl.frame.origin.y != shareOriginY {
                shareScreenPageControl.frame.origin.y = shareOriginY
            }
            return
        }

        // 记录初始位置
        if shareScreenPageControlOriginalFrame == nil,
           let shareBottomView = shareScreenVC.shareBottomView,
           !shareBottomView.bounds.isEmpty {
            var frame = shareScreenPageControl.frame
            let bottomHeight = shareScreenVC.shareBottomBackgroundView?.bounds.height ?? shareBottomView.bounds.height
            frame.origin.y = view.bounds.height - bottomHeight - frame.size.height - 2.0
            shareScreenPageControlOriginalFrame = frame
        }

        guard let originalFrame = shareScreenPageControlOriginalFrame else { return }

        // 根据初始位置移动
        let length = pageControl.center.y - originalFrame.center.y + 2.0
        var offset = length * (offsetX / pageWidth)
        offset = max(0, min(length, offset))
        shareScreenPageControl.transform = CGAffineTransform(translationX: 0, y: offset)

        if pageControlOriginalFrame == nil {
            pageControlOriginalFrame = pageControl.frame
        }

        // 渐变大小过渡动画
        guard let pOriginalFrame = pageControlOriginalFrame else { return }
        let widthDelta = 2 * (1 - ratio)
        let heightDelta = 2 * (1 - ratio)
        pageControl.frame = CGRect(x: pOriginalFrame.origin.x + widthDelta / 2,
                                   y: pOriginalFrame.origin.y + heightDelta / 2,
                                   width: pOriginalFrame.size.width - widthDelta,
                                   height: pOriginalFrame.size.height - heightDelta)
    }

    private func adaptBottomShadow() {
        if self.meetingLayoutStyle == .overlay {
            shareScreenShrinkView.vc.addOverlayShadow(isTop: true)
        } else {
            shareScreenShrinkView.vc.removeOverlayShadow()
        }
    }

    // fix common ancestor crash
    // https://t.wtturl.cn/2cvN1Fp/
    // https://t.wtturl.cn/6UbFE9c/
    var shrinkViewConstraitIsValid: Bool {
        shareScreenShrinkView.window != nil && shareScreenShrinkView.window == shareScreenContentLayoutGuide.owningView?.window
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let shareIndex = cellVMs.firstIndex(where: { $0.type == .share }),
                indexPath.row == shareIndex else {
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellReuseIdentifier.shareScreen, for: indexPath)
        if let shareCell = cell as? InMeetShareScreenGridCell,
            _shareScreenVC?.parent === self {
            shareCell.contentView.addSubview(self.shareScreenView)
            if hasShrinkView {
                shareCell.contentView.addSubview(self.shareScreenShrinkView)
            }
            shareCell.delegate = self

            let isOverlayFullScreen = viewModel.context.meetingLayoutStyle != .tiled
            let shrinkOffset: CGFloat = hasShrinkView ? 15.0 : 0.0

            self.shareScreenView.snp.remakeConstraints {
                $0.left.right.bottom.equalToSuperview()
                if isOverlayFullScreen {
                    $0.top.equalToSuperview().offset(shrinkOffset)
                } else {
                    $0.top.equalToSuperview().offset(44 + shrinkOffset)
                }
            }

            self.shareScreenVC.singleTapGestureRecognizer = shareCell.singleTapGesture
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
        if self.shareScreenView.superview === cell.contentView {
            self.isShareVCVisible = true
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
        if self.shareScreenView.superview === cell.contentView {
            self.isShareVCVisible = false
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.updateShareScreenPageControl()
    }

    private var shareBarGuideToken: MeetingLayoutGuideToken?
    override func didAttachToLayoutContainer(_ layoutContainer: InMeetLayoutContainer) {
        super.didAttachToLayoutContainer(layoutContainer)
        self.layoutContainer = layoutContainer
        self.isAttachedToFloatContainer = true
        let token = layoutContainer.requestOrderedLayoutGuide(topAnchor: .top,
                                                              bottomAnchor: .bottomSketchBar,
                                                              ignoreAnchors: [.bottomSafeArea])
        self.shareBarGuide.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(token.layoutGuide.snp.bottom)
        }
        self.shareBarGuideToken = token
    }

    override func didDetachFromLayoutContainer(_ layoutContainer: InMeetLayoutContainer) {
        super.didDetachFromLayoutContainer(layoutContainer)
        self.isAttachedToFloatContainer = false
        self.layoutContainer = nil
        self.shareBarGuideToken?.invalidate()
        self.shareBarGuideToken = nil
    }

    private func updateShareVCAttached() {
        guard let shareVC = self.shareScreenVC as? InMeetLayoutContainerAware,
              let layoutContainer = self.layoutContainer else {
            return
        }
        if self.isShareVCVisible && self.isAttachedToFloatContainer {
            shareVC.didAttachToLayoutContainer(layoutContainer)
        } else {
            shareVC.didDetachFromLayoutContainer(layoutContainer)
        }
    }

}

extension InMeetFlowAndShareContainerViewControllerV2: InMeetShareScreenGridCellLayoutDelegate {
    func didLayoutSubviews() {
        updateShareLayoutGuide()
        updateShareScreenPageControl()
    }
}
