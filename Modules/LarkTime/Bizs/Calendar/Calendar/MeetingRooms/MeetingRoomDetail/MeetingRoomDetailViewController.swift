//
//  MeetingRoomDetailViewController.swift
//  Calendar
//
//  Created by LiangHongbin on 2021/1/15.
//

import UIKit
import Foundation
import LarkUIKit
import LarkAssetsBrowser
import RxSwift
import LarkContainer
import EENavigator
import UniverseDesignToast

final class MeetingRoomDetailViewController: BaseUIViewController, UserResolverWrapper {
    let viewModel: MeetingRoomDetailViewModel
    let disposeBag = DisposeBag()

    private(set) var titleView = MeetingRoomDetailTitleView()
    private(set) var statusContentView = MeetingRoomDetailBasicInfoView()
    private(set) var basicInfoView = MeetingRoomDetailBasicInfoView()
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    let userResolver: UserResolver
    var meetingRoomInfoTransform = CGAffineTransform.identity

    var containerView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()

    private lazy var titleBottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.textDisabled
        return view
    }()

    private lazy var statusBottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.textDisabled
        return view
    }()

    init(viewModel: MeetingRoomDetailViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = false
        bindViewState()
        viewModel.setupDetailContent { [weak self] in
            guard let self = self else { return }
            self.bindViewData()
            self.setupViews()
        }

    }

    private func setupViews() {
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        containerView.addSubview(titleView)
        titleView.snp.makeConstraints {
            $0.left.width.top.equalToSuperview()
        }

        containerView.addSubview(titleBottomLine)
        titleBottomLine.snp.makeConstraints {
            $0.left.right.equalTo(view)
            $0.bottom.equalTo(titleView.snp.bottom)
            $0.height.equalTo(EventEditUIStyle.Layout.horizontalSeperatorHeight)
        }

        var hasStatusView: Bool = false
        let jumpToChatController = calendarDependency?.jumpToChatController(from:chatterID:onError:)
        if case .detailWithStatus = viewModel.input,
           !viewModel.rxStatusContentViewData.value.cellsData.isEmpty,
           !viewModel.rxStatusContentViewData.value.cellsData[0].content.isEmpty {
            containerView.addSubview(statusContentView)
            statusContentView.snp.makeConstraints {
                $0.left.width.equalToSuperview()
                $0.top.equalTo(titleView.snp.bottom)
            }
            containerView.addSubview(statusBottomLine)
            statusBottomLine.snp.makeConstraints {
                $0.left.right.equalTo(view).inset(16)
                $0.bottom.equalTo(statusContentView.snp.bottom)
                $0.height.equalTo(EventEditUIStyle.Layout.horizontalSeperatorHeight)
            }
            hasStatusView = true
            if case .inUse = viewModel.rxMeetingRoomDetailEntity.value.state {
                statusContentView.bookerCell.chatBtnClick = { [weak self] (chatterID) in
                    guard let self = self else { return }
                    jumpToChatController?(self, chatterID, { [weak self] in
                        guard let self = self else { return }
                        UDToast().showFailure(with: BundleI18n.Calendar.Lark_Legacy_RecallMessage, on: self.view)
                    })

                }
            }
        }

        if !viewModel.rxBasicInfoViewData.value.cellsData.isEmpty,
           !viewModel.rxBasicInfoViewData.value.cellsData[0].content.isEmpty {
            containerView.addSubview(basicInfoView)
            let upperView = hasStatusView ? statusContentView : titleView
            basicInfoView.snp.makeConstraints {
                $0.left.width.bottom.equalToSuperview()
                $0.top.equalTo(upperView.snp.bottom)
            }
        }

        if let picture = viewModel.rxMeetingRoomDetailEntity.value.picture {
            basicInfoView.pictureCell.pictureClickHandler = { [weak self] (image) in
                guard let self = self else { return }
                let asset = LKDisplayAsset()
                asset.placeHolder = image.image
                asset.visibleThumbnail = image
                // 暂不支持保存，待相关重构完成替换（Calendar 当前有三个场景使用）
                let imageController = LKAssetBrowserViewController(assets: [asset], pageIndex: 0)
                imageController.isSavePhotoButtonHidden = true
                imageController.longPressEnable = false
                imageController.getExistedImageBlock = { _ -> UIImage? in
                    return image.image
                }
                self.userResolver.navigator.present(imageController, from: self)
            }
        }
    }
    
    func setUpConfigFromFreebusy(height: CGFloat) {
        isNavigationBarHidden = true
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.cornerRadius = 7
        view.layer.shadowOffset = CGSize(width: 0, height: -3)
        view.layer.shadowOpacity = 1
        view.layer.ud.setShadowColor(UIColor.ud.shadowDefaultSm, bindTo: view)
        titleView.subTitleLabel.numberOfLines = 1
        titleView.subTitleLabel.font = .ud.body2
        titleView.subTitleLabel.lineBreakMode = .byTruncatingTail
        titleView.titleLabel.numberOfLines = 0
        titleView.titleLabel.font = .ud.title3
        titleView.titleLabel.lineBreakMode = .byTruncatingTail

        let panIndicatorView: UIView = {
            let indicatorView = UIView()
            indicatorView.layer.cornerRadius = 2
            indicatorView.backgroundColor = UIColor.ud.N300
            return indicatorView
        }()

        view.addSubview(panIndicatorView)
        panIndicatorView.snp.makeConstraints {
            $0.width.equalTo(40)
            $0.height.equalTo(4)
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(8)
        }
        
        let pan = UIPanGestureRecognizer()
        view.addGestureRecognizer(pan)
        pan.delegate = self
        pan.rx.event.asDriver().drive(onNext: { [weak self] gesture in
            guard let originalTransform = self?.meetingRoomInfoTransform,
                  let view = gesture.view else { return }

            let minY = -(height) / 2 + 88
            let maxY: CGFloat = 0

            switch gesture.state {
            case .changed:
                let translation = gesture.translation(in: nil)
                var targetTransform = originalTransform.translatedBy(x: 0, y: translation.y)
                targetTransform.ty = max(minY, min(maxY, targetTransform.ty))
                view.transform = targetTransform
            case .cancelled, .ended:
                let centerPoint = (minY + maxY) / 2
                let finalY = view.transform.ty > centerPoint ? maxY : minY
                var finalTransform = view.transform
                finalTransform.ty = finalY
                if finalY == maxY {
                    self?.containerView.contentOffset = .zero
                }
                self?.meetingRoomInfoTransform = finalTransform
                UIView.animate(withDuration: 0.2) {
                    view.transform = finalTransform
                }
            default:
                // do nothing
                break
            }
        })
        .disposed(by: disposeBag)
       containerView.panGestureRecognizer.require(toFail: pan)

    }

    private func bindViewData() {
        viewModel.rxTitleViewData.bind(to: titleView).disposed(by: disposeBag)
        viewModel.rxBasicInfoViewData.bind(to: basicInfoView).disposed(by: disposeBag)
        if case .detailWithStatus = viewModel.input {
            viewModel.rxStatusContentViewData.bind(to: statusContentView).disposed(by: disposeBag)
        }
    }

    private func bindViewState() {
        viewModel.rxViewState.distinctUntilChanged()
            .subscribe(onNext: { [weak self] viewState in
                self?.updateViewState(with: viewState)
            })
            .disposed(by: disposeBag)
    }

    private func updateViewState(with state: MeetingRoomDetailViewState) {
        switch state {
        case .loading:
            loadingPlaceholderView.isHidden = false
        case .failed:
            retryLoadingView.isHidden = false
            retryLoadingView.retryAction = { [weak self] in
                self?.viewModel.setupDetailContent { [weak self] in
                    guard let self = self else { return }
                    self.bindViewData()
                    self.setupViews()
                }
            }
        case .data:
            retryLoadingView.removeFromSuperview()
            loadingPlaceholderView.removeFromSuperview()
        case .idle:
            break
        }
    }
}

extension MeetingRoomDetailViewController: UIGestureRecognizerDelegate {
    @nonobjc
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer,
           let view = pan.view {
            if view.transform.isIdentity { return true }
            let currentLocationY = pan.location(in: view).y
            let translationY = pan.translation(in: view).y
            return currentLocationY - translationY < 50
        }
        return true
    }
}
