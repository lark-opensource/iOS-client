//
//  MailHomeController+Refresh.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/2/11.
//

import Foundation
import RxSwift
import LarkUIKit
import Lottie
import ESPullToRefresh
import UniverseDesignLoading
import UniverseDesignIcon

extension MailHomeController: RefreshHeaderViewDelegate, MailLoadMoreRefreshDelegate {
    func refreshAnimationBegin(view: ESRefreshComponent) {
    }

    func refreshAnimationEnd(view: ESRefreshComponent) {
    }

    func progressDidChange(view: ESRefreshComponent, progress: CGFloat) {
        header.alpha = progress
    }

    func stateDidChange(view: ESRefreshComponent, state: ESRefreshViewState) {}

    func configTabelViewRefresh() {
        guard !didCongfigRefresh else { return }
        configHeaderRefresh()
        configFooterRefresh()
        didCongfigRefresh = true
    }

    func addObserver() {
        MailStateManager.shared.addObserver(self)
    }

    func configHeaderRefresh() {
        header.delegate = self
        esHeaderView = tableView.es.addPullToRefresh(animator: header) { [unowned self] in
            self.topLoadMoreRefresh()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (viewModel.hasFirstLoaded ? 0.0 : timeIntvl.normal)) { [weak self] in
            self?.header.refreshPostion()
        }
    }

    func configFooterRefresh() {
        footer.delegate = self
        tableView.es.addInfiniteScrolling(animator: footer) { [weak self] in
            self?.loadMoreIfNeeded()
        }
    }

    func loadMoreIfNeeded() {
        if viewModel.isLastPage() {
            if self.viewModel.datasource.count > 0 {
                self.tableView.es.noticeNoMoreData()
            } else {
                self.tableView.es.stopLoadingMore()
            }
        } else {
            self.viewModel.loadMore()
        }
    }

    var shouldAdjustPullRefresh: Bool {
        let mailHomePullToRefresh = ProviderManager.default.commonSettingProvider?.IntValue(key: "mailHomePullToRefresh") ?? 0
        return mailHomePullToRefresh == 1
    }

    func stopRefresh() {
        //print("[mail_refresh] stopRefresh tableView.contentOffset.y: \(tableView.contentOffset.y) previousOffset: \(esHeaderView?.previousOffset ?? -10000)")
//        if shouldAdjustPullRefresh && tableView.contentOffset.y > 0 {
//            esHeaderView?.previousOffset = tableView.contentOffset.y
//            esHeaderView?.scrollViewInsets = UIEdgeInsets(top: -tableView.contentOffset.y, left: 0,
//                                                          bottom: esHeaderView?.scrollViewInsets.bottom ?? 0, right: 0)
//        }
        tableView.es.stopPullToRefresh(ignoreDate: true)
    }

    func topLoadMoreRefresh() {
        header.refreshTips.alpha = 0
        viewModel.apmMarkThreadListStart(sence: .sence_reload)

        let listBag = viewModel.listViewModel.disposeBag
        // 设计觉得刷新返回结果太快，愣是要先转一圈 所以需要延时
        let delayer = Observable<()>.just(()).delay(.seconds(1), scheduler: MainScheduler.instance)
        // 数据不做delay
        let dataOb = viewModel.listViewModel.topLoadMoreRefreshProvider()
            .map({ [weak self] (response, cells) -> () in
            guard let `self` = self else { return }
            if response.newThreadCount > 0 {
                self.header.refreshTips.text = ""
            } else {
                self.header.refreshTips.text = BundleI18n.MailSDK.Mail_Refresh_NoMoreMessage
            }
            // 清空本地数据 刷新当前ThreadList
            let newThreadList = cells
            self.viewModel.listViewModel.setThreadsListOfLabel(self.viewModel.currentLabelId, mailList: newThreadList)
            self.viewModel.listViewModel.isLastPage = response.response.isLastPage
            self.viewModel.syncDataSource()
            self.tableView.reloadData()
            self.viewModel.apmHolder[MailAPMEvent.ThreadListLoaded.self]?.endParams
                .appendOrUpdate(MailAPMEvent.ThreadListLoaded.EndParam.from_db(response.response.isFromDb ? 1 : 0))
            self.viewModel.apmMarkThreadListEnd(status: .status_success)
            self.refreshListDataReady.accept((.pullToRefresh, true))

            return ()
        })

        /// 需要区分是 Observable complete 了还是 disposeBag 释放的
        var hasResult = false

        Observable
            .zip(dataOb, delayer)
            .subscribe(onNext: { [weak self] (_, _) in
                guard let `self` = self else { return }
                hasResult = true
                handlerResult()
            }, onError: { [weak self] (error) in
                hasResult = true
                if error.mailErrorCode == MailErrorCode.getMailListEmpty {
                    self?.header.refreshTips.text = BundleI18n.MailSDK.Mail_Refresh_NoMoreMessage
                } else {
                    self?.header.refreshTips.text = BundleI18n.MailSDK.Mail_Refresh_ServerError
                }
                MailLogger.error("Send refreshThreadList request failed error: \(error).")
                handlerResult()
                self?.viewModel.apmHolder[MailAPMEvent.ThreadListLoaded.self]?.endParams.appendError(errorCode: error.mailErrorCode,
                                                                                                     errorMessage: error.getMessage())
                self?.viewModel.apmMarkThreadListEnd(status: .status_rust_fail)
            }, onDisposed: { [weak self] in
                guard !hasResult else { return }
                self?.stopRefresh()
            }).disposed(by: listBag)

        func handlerResult() {
            let animateDuration: Double = 0.6
            UIView.animate(withDuration: animateDuration, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
                self?.header.circle.isHidden = true
                self?.header.refreshTips.alpha = 1.0
            }) { [weak self] (_)  in
                let delayTime: Double = 1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                    self?.stopRefresh()
                }
            }
        }
    }

    func getTableViewTopMargin() -> CGFloat {
        var margin = statusAndNaviHeight
        if multiAccountView.isDescendant(of: view) {
            margin += CGFloat(48)
        }
        return margin
    }

    func loadMoreRetryHandler() {}
    func loadMoreCheckTrashMailHandler() {}
    func loadMoreCacheMailHandler() {
        let cacheSettingVC: MailCacheSettingViewController = MailCacheSettingViewController(viewModel: MailSettingViewModel(accountContext: userContext.getCurrentAccountContext()), accountContext: userContext.getCurrentAccountContext())
        cacheSettingVC.delegate = self
        cacheSettingVC.scene = .home
        let cacheSettingNav = LkNavigationController(rootViewController: cacheSettingVC)
        cacheSettingNav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        navigator?.present(cacheSettingNav, from: self)
        MailTracker.log(event: "email_thread_list_click", params: ["click": "offline_cache_set", "target": "none"])
    }
}

protocol RefreshHeaderViewDelegate: AnyObject {
    func refreshAnimationBegin(view: ESRefreshComponent)
    func refreshAnimationEnd(view: ESRefreshComponent)
    func progressDidChange(view: ESRefreshComponent, progress: CGFloat)
    func stateDidChange(view: ESRefreshComponent, state: ESRefreshViewState)
}

final class MailRefreshHeaderAnimator: ESRefreshComponent, ESRefreshProtocol, ESRefreshAnimatorProtocol {
    var insets: UIEdgeInsets = UIEdgeInsets.zero
    var view: UIView { return self }
    var duration: TimeInterval = 0.3
    var trigger: CGFloat = 56.0
    var executeIncremental: CGFloat = 56.0
    var state: ESRefreshViewState = .pullToRefresh

    var showingRefreshAnimation = false
    var loadingLayer = CAShapeLayer()
    private let lineWidth: CGFloat = 2.0
    var angle: CGFloat = 0
    var circle = CALayer()

    var refreshTips: UILabel = {
        let refreshTips = UILabel()
        refreshTips.alpha = 0.0
        refreshTips.textColor = UIColor.ud.textPlaceholder
        refreshTips.font = UIFont.systemFont(ofSize: 12.0)
        refreshTips.textAlignment = .center
        return refreshTips
    }()

    weak var delegate: RefreshHeaderViewDelegate?

    func point() -> CGPoint {
        return CGPoint(x: (bounds.width - 20) / 2.0, y: (bounds.height - 20) / 2.0)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayer(in: layer, size: CGSize(width: 20, height: 20), color: UIColor.ud.primaryPri500)
        addSubview(refreshTips)
        refreshTips.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(20)
            make.center.equalToSuperview()
        }
    }

    func setUpLayer(in layer: CALayer, size: CGSize, color: UIColor) {
        circle = layerWith(size: size, color: color)
        circle.frame = CGRect(origin: point(), size: size)
        layer.addSublayer(circle)
    }

    func layerWith(size: CGSize, color: UIColor) -> CALayer {
        let layer: CAShapeLayer = CAShapeLayer()
        let path: UIBezierPath = UIBezierPath()
        path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
        radius: size.width / 2,
        startAngle: 0,
        endAngle: .pi / 2,
        clockwise: false)
        layer.fillColor = nil
        layer.strokeColor = color.cgColor
        layer.lineWidth = lineWidth
        layer.lineCap = .round
        layer.backgroundColor = nil
        layer.path = path.cgPath
        layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        return layer
    }

    func startAnimation() {
        layer.speed = 1

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.byValue = Float.pi * 2
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)

        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [rotationAnimation]
        groupAnimation.duration = 1.0
        groupAnimation.repeatCount = .infinity
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.fillMode = .forwards
        circle.add(groupAnimation, forKey: "animation")
    }

    func stopAnimation() {
        loadingLayer.removeAllAnimations()
        circle.removeAllAnimations()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshAnimationBegin(view: ESRefreshComponent) {
        refreshPostion()
        startAnimation()
        showingRefreshAnimation = true
    }

    func refreshPostion() {
        circle.frame = CGRect(origin: point(), size: CGSize(width: 20, height: 20))
    }

    func refreshAnimationEnd(view: ESRefreshComponent) {
        stopAnimation()
        showingRefreshAnimation = false
    }

    func refresh(view: ESRefreshComponent, progressDidChange progress: CGFloat) {
        let p = max(0.0, min(1.0, progress))
        var trans = CATransform3DIdentity
        let angel = CGFloat(.pi * 2 * p)
        trans = CATransform3DMakeRotation(angel, 0, 0, 1)
        circle.transform = trans
        alpha = p
    }

    func refresh(view: ESRefreshComponent, stateDidChange state: ESRefreshViewState) {
        guard self.state != state else {
            return
        }
        self.state = state

        switch state {
        case .pullToRefresh:
            circle.isHidden = false
            refreshTips.alpha = 0
        case .releaseToRefresh:
            break
        case .noMoreData:
            break
        default:
            break
        }
        delegate?.stateDidChange(view: view, state: state)
    }
}
// MARK: - MailLoadMoreRefreshAnimator
protocol MailLoadMoreRefreshDelegate: AnyObject {
    func loadMoreRetryHandler()
    func loadMoreCacheMailHandler()
    func loadMoreCheckTrashMailHandler()
}

// MARK: - MailLoadMoreRefreshAnimator
class MailLoadMoreRefreshAnimator: ESRefreshComponent, ESRefreshProtocol, ESRefreshAnimatorProtocol {
    var view: UIView { return self }
    var insets: UIEdgeInsets = UIEdgeInsets.zero
    var trigger: CGFloat = 180
    var executeIncremental: CGFloat = 180
    var state: ESRefreshViewState = .pullToRefresh
    var topOffset: CGFloat = 30 {
        didSet {
            titleLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(topOffset)
            }
        }
    }
    private var duration: TimeInterval = 0.3
    var showingRefreshAnimation: Bool {
        return self.state == .refreshing || self.state == .autoRefreshing
    }
    var titleText = BundleI18n.MailSDK.Mail_ThreadList_NoMoreConversations
    var canRetry = false {
        didSet {
            titleLabel.font = canRetry ? UIFont.systemFont(ofSize: 12.0, weight: .medium) : UIFont.systemFont(ofSize: 12.0)
            retryBtn.isHidden = !canRetry
            refreshTitleIfNeeded()
        }
    }
    var checkTrashMail = false {
        didSet {
            checkTrashMailBtn.isHidden = !checkTrashMail
            refreshTitleIfNeeded()
        }
    }
    var canCacheMore = false {
        didSet {
            titleLabel.font = canCacheMore ? UIFont.systemFont(ofSize: 12, weight: .medium) : UIFont.systemFont(ofSize: 12.0)
            cacheBtn.isHidden = !canCacheMore
            refreshTitleIfNeeded()
        }
    }
    weak var delegate: MailLoadMoreRefreshDelegate?
    private lazy var retryBtn: UIButton = {
        let retryBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 125, height: 20))
        retryBtn.setTitle(BundleI18n.MailSDK.Mail_InternetCutOff_Reload_Button, for: .normal)
        retryBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
        retryBtn.setImage(UDIcon.refreshOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        retryBtn.imageView?.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
        retryBtn.imageView?.tintColor = .ud.primaryContentDefault
        retryBtn.imageView?.contentMode = .scaleAspectFit
        retryBtn.setTitleColor(.ud.primaryContentDefault, for: .normal)
        let space: CGFloat = 4.0
        retryBtn.imageEdgeInsets = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 1.0)
        retryBtn.titleEdgeInsets = UIEdgeInsets(top: 0, left: -4.0, bottom: 0, right: 2.0)
        retryBtn.contentVerticalAlignment = .center
        retryBtn.contentHorizontalAlignment = .center
        retryBtn.rx.tap.bind { [weak self] in
            self?.delegate?.loadMoreRetryHandler()
        }.disposed(by: disposeBag)
        retryBtn.isHidden = true
        retryBtn.isUserInteractionEnabled = true
        return retryBtn
    }()
    private lazy var checkTrashMailBtn: UIButton = {
        let checkTrashMailBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 125, height: 20))
        checkTrashMailBtn.setTitle(BundleI18n.MailSDK.Email_Shared_SearchMail_ViewMessages_Button, for: .normal)
        checkTrashMailBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
        checkTrashMailBtn.setTitleColor(.ud.primaryPri500, for: .normal)
        checkTrashMailBtn.rx.tap.bind { [weak self] in
            self?.delegate?.loadMoreCheckTrashMailHandler()
        }.disposed(by: disposeBag)
        checkTrashMailBtn.isHidden = true
        checkTrashMailBtn.isUserInteractionEnabled = true
        return checkTrashMailBtn
    }()

    private lazy var cacheBtn: UIButton = {
        let cacheBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 125, height: 20))
        cacheBtn.setTitle(BundleI18n.MailSDK.Mail_EmailCache_ReadMoreWhenOffline_EmailCache_Button, for: .normal)
        cacheBtn.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
        cacheBtn.setTitleColor(.ud.primaryPri500, for: .normal)
        cacheBtn.rx.tap.bind { [weak self] in
            self?.delegate?.loadMoreCacheMailHandler()
        }.disposed(by: disposeBag)
        cacheBtn.isHidden = true
        cacheBtn.isUserInteractionEnabled = true
        return cacheBtn
    }()
    private let disposeBag = DisposeBag()
    
    fileprivate let titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.alpha = 0.0
        label.numberOfLines = 0
        return label
    }()

    private let animationView: LOTAnimationView = {
        let animation = AnimationViews.spinAnimation
        animation.frame = CGRect(x: 146, y: 100, width: 20, height: 20)
        animation.backgroundColor = UIColor.clear
        animation.contentMode = .scaleAspectFit
        animation.alpha = 0.0
        return animation
    }()

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.text = nil
        addSubview(titleLabel)
        addSubview(animationView)
        addSubview(retryBtn)
        addSubview(checkTrashMailBtn)
        addSubview(cacheBtn)
        isUserInteractionEnabled = true

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.trailing.leading.equalToSuperview().inset(28)
            make.top.equalToSuperview().offset(topOffset)
        }
        titleLabel.sizeToFit()
        animationView.snp.makeConstraints { make in
            make.center.equalTo(titleLabel)
            make.width.height.equalTo(20)
        }
        retryBtn.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.width.equalTo(titleLabel)
        }
        checkTrashMailBtn.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.centerX.equalToSuperview()
            make.width.equalTo(titleLabel)
        }
        cacheBtn.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.centerX.equalToSuperview()
            make.width.equalTo(titleLabel)
        }
    }
    
    func refreshTitleIfNeeded() {
        let containButtonOffset = 15
        let textOffset = 30
        let centerYOffset = (checkTrashMail || canCacheMore || canRetry) ? containButtonOffset : textOffset
        titleLabel.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(centerYOffset)
        }
        setTipsText()
        titleLabel.sizeToFit()
    }

    func refreshAnimationBegin(view: ESRefreshComponent) {
        animationView.play()
        showLoading(animation: false)
    }

    func refreshAnimationEnd(view: ESRefreshComponent) {
        animationView.stop()
        hideLoading(animation: false)
    }

    func refresh(view: ESRefreshComponent, progressDidChange progress: CGFloat) {
    }

    func refresh(view: ESRefreshComponent, stateDidChange state: ESRefreshViewState) {
        guard self.state != state else { return }
        self.state = state
        if state == .noMoreData {
            self.superview?.alpha = 1.0
            self.retryBtn.isHidden = true
            self.cacheBtn.isHidden = true
            self.checkTrashMailBtn.isHidden = true
            if canRetry {
                retryBtn.isHidden = false
                titleLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
                showTips(animation: true)
            } else if checkTrashMail {
                checkTrashMailBtn.isHidden = false
                titleLabel.font = UIFont.systemFont(ofSize: 12.0)
                showTips(animation: true)
            } else if canCacheMore {
                cacheBtn.isHidden = false
                titleLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
                showTips(animation: true)
            } else {
                titleLabel.font = UIFont.systemFont(ofSize: 12.0)
                retryBtn.isHidden = true
                showNoMore(animation: true)
            }
        } else {
            retryBtn.isHidden = true
            cacheBtn.isHidden = true
            checkTrashMailBtn.isHidden = true
            titleLabel.text = nil
        }
        self.setNeedsLayout()
    }

    func showNoMore(animation: Bool) {
        setTipsText()
        UIView.animate(withDuration: animation ? timeIntvl.uiAnimateNormal : 0, delay: 0, options: .curveEaseInOut, animations: {
            self.animationView.alpha = 0
            self.titleLabel.alpha = 1.0
        }) { (_) in
            self.animationView.alpha = 0
            self.titleLabel.alpha = 1.0
        }
    }

    func setTipsText() {
        titleLabel.text = {
            if canRetry {
                return BundleI18n.MailSDK.Mail_InternetCutOff_TryAgainLater_Text
            } else if checkTrashMail {
                return BundleI18n.MailSDK.Email_Shared_SearchMail_MatchResultInTrashOrSpam_Notice
            } else if canCacheMore {
                return BundleI18n.MailSDK.Mail_EmailCache_ReadMoreWhenOffline_Text
            } else {
                return titleText
            }
        }()
    }
    
    func hideNomoreTip() {
        self.titleLabel.alpha = 0
    }

    func showTips(animation: Bool = true) {
        MailLogger.info("[mail_search] showTips")
        setTipsText()
        UIView.animate(withDuration: animation ? timeIntvl.uiAnimateNormal : 0, delay: 0, options: .curveEaseInOut, animations: {
            self.animationView.alpha = 0
            self.titleLabel.alpha = 1.0
        }) { (_) in
            self.animationView.alpha = 0
            self.titleLabel.alpha = 1.0
            self.setNeedsLayout()
        }
    }

    func showLoading(animation: Bool) {
        MailLogger.info("[mail_client_search] showLoading")
        if animation {
            UIView.animate(withDuration: animation ? timeIntvl.uiAnimateNormal : 0, delay: 0, options: .curveEaseInOut, animations: {
                self.animationView.alpha = 1.0
            }, completion: { (_) in
                self.animationView.alpha = 1.0
            })
        } else {
            animationView.alpha = 1.0
        }
    }

    func hideLoading(animation: Bool) {
        if animation {
            UIView.animate(withDuration: animation ? timeIntvl.uiAnimateNormal : 0, delay: 0, options: .curveEaseInOut, animations: {
                self.animationView.alpha = 0.0
            }, completion: { (_) in
                self.animationView.alpha = 0.0
            })
        } else {
            animationView.alpha = 0.0
        }

    }
}
