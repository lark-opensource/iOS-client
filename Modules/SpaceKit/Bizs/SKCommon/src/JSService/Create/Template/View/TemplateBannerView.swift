//
//  TemplateBannerView.swift
//  SKCommon
//
//  Created by bytedance on 2021/1/15.
//
import SKFoundation
import SKUIKit
import RxSwift
import UniverseDesignColor
import SKInfra

protocol TemplateBannerViewDelegate: AnyObject {
    func didClickBanner(at index: Int, templateBanner: TemplateBanner)
}

class TemplateBannerView: UIView {
    // UI
    private lazy var scrollView = UIScrollView()
    private lazy var shadowView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N00
        view.layer.cornerRadius = 6
        view.layer.ud.setShadowColor(UDColor.shadowDefaultMd)
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 8
        return view
    }()
    
    private lazy var pageControlView = BannerPageControlView()
    
    private lazy var bannerViewArray: [BannerView] = []
    
    // data
    private var dataSource: [TemplateBanner] = []
    
    // interaction
    weak var delegate: TemplateBannerViewDelegate?
    private lazy var proxy = WeakProxy(bannerView: self)
    
    // banner scroll
    private var curDataIndex: Int = 0
    private var timer: Timer?
    
    private var isTimerStopByVC: Bool = false
    private let leftPadding: CGFloat = 16
    
    private var cellSize: CGSize = .zero
    

    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    deinit {
        scrollView.delegate = nil
        timer?.invalidate()
        timer = nil
        DocsLogger.debug("bannerview deinit")
    }
 
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(shadowView)
        addSubview(scrollView)
        addSubview(pageControlView)
        
        shadowView.snp.makeConstraints { (make) in
            make.edges.equalTo(scrollView)
        }
        scrollView.layer.borderWidth = 1
        scrollView.layer.borderColor = UIColor.ud.N300.cgColor
        scrollView.layer.cornerRadius = 6
        scrollView.layer.masksToBounds = true
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shadowView.layer.shadowPath = UIBezierPath(rect: shadowView.bounds).cgPath
    }
    
    private func updatePageControlView() {
        let count = dataSource.count
        if count <= 1 {
            pageControlView.isHidden = true
        } else {
            pageControlView.isHidden = false
            let width = pageControlView.resetPageControl(with: count)
            let height: CGFloat = 8
            pageControlView.snp.remakeConstraints { (make) in
                make.centerX.equalTo(scrollView)
                make.bottom.equalTo(scrollView).offset(-8)
                make.height.equalTo(height)
                make.width.equalTo(width)
            }
            pageControlView.layer.cornerRadius = height / 2.0
            pageControlView.updateCurIndex(to: 0)
        }
    }
    
    func updateTemplateBanner(_ data: [TemplateBanner]) {
        dataSource = data
        reloadBanner()
        updatePageControlView()
        resetTimer(isStart: dataSource.count > 1)
    }
    
    private func reloadBanner() {
        // 从applink过来的带objType筛选参数的时候，会导致banner空白，就3个bannerView，此处不复用了
        bannerViewArray.forEach { $0.removeFromSuperview() }
        bannerViewArray.removeAll()
        guard !dataSource.isEmpty else { return }
        if dataSource.count == 1, let banner = dataSource.first {
            curDataIndex = 0
            let bannerView = BannerView()
            bannerView.delegate = self
            bannerView.frame = CGRect(x: 0, y: 0, width: cellSize.width, height: cellSize.height)
            scrollView.addSubview(bannerView)
            bannerViewArray.append(bannerView)
            scrollView.isScrollEnabled = false
            scrollView.frame = CGRect(x: leftPadding, y: leftPadding, width: self.frame.width - 2 * leftPadding, height: cellSize.height)
            scrollView.contentSize = CGSize(width: cellSize.width, height: cellSize.height)
            self.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            bannerView.config(banner: banner)
            reportShowBanner(banner: banner)
            return
        }
        
        scrollView.isScrollEnabled = true
        if bannerViewArray.isEmpty {
            for _ in 0...2 {
                let bannerView = BannerView()
                bannerView.delegate = self
                scrollView.addSubview(bannerView)
                bannerViewArray.append(bannerView)
            }
        }
        scrollView.frame = CGRect(x: leftPadding, y: leftPadding, width: self.frame.width - 2 * leftPadding, height: cellSize.height)
        scrollView.contentSize = CGSize(width: 3 * cellSize.width, height: cellSize.height)
        resetBannerViewsLayout()
        if let bannerData = dataSource.first, bannerViewArray.count > 2 {
            let bannerView = bannerViewArray[1]
            bannerView.config(banner: bannerData)
            curDataIndex = 0
            reportShowBanner(banner: bannerData)
        }
        setPreBanner()
        setNextBanner()
    }
    private func resetBannerViewsLayout() {
        for i in 0...bannerViewArray.count - 1 {
            let bannerView = bannerViewArray[i]
            let x = cellSize.width * CGFloat(i)
            bannerView.frame = CGRect(x: x, y: 0, width: cellSize.width, height: cellSize.height)
        }
        let offsetX: CGFloat = dataSource.count <= 1 ? 0 : cellSize.width
        scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
    }
    
    private func setPreBanner() {
        var targetIndex = curDataIndex - 1
        if targetIndex < 0 {
            targetIndex = dataSource.count - 1
        }
        if dataSource.count > targetIndex, targetIndex >= 0 {
            let bannerData = dataSource[targetIndex]
            bannerViewArray.first?.config(banner: bannerData)
        }
    }
    
    private func setNextBanner() {
        var targetIndex = curDataIndex + 1
        if targetIndex > dataSource.count - 1 {
            targetIndex = 0
        }
        if dataSource.count > targetIndex, targetIndex >= 0 {
            let bannerData = dataSource[targetIndex]
            bannerViewArray.last?.config(banner: bannerData)
        }
    }
    
    func resetBannerAnimationIfNeed(isStart: Bool) {
        if isTimerStopByVC, isStart {
            resetTimer(isStart: true)
            isTimerStopByVC = true
            if dataSource.count > 1 {
                scrollView.setContentOffset(CGPoint(x: cellSize.width, y: 0), animated: false)
                pageControlView.updateCurIndex(to: curDataIndex)
            } else {
                scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            }
        } else if isTimerStopByVC == false, isStart == false {
            resetTimer(isStart: false)
            isTimerStopByVC = true
        }
    }
    
    func resetScrollViewDelegate(isClear: Bool) {
        scrollView.delegate = isClear ? nil : self
    }
    
    func resetTimer(isStart: Bool) {
        timer?.invalidate()
        timer = nil

        if isStart, dataSource.count > 1 {
            let aTimer = Timer.scheduledTimer(timeInterval: 5, target: proxy, selector: #selector(WeakProxy.timerCount), userInfo: nil, repeats: true)
            RunLoop.current.add(aTimer, forMode: .default)
            timer = aTimer
        }
    }
    
    func scrollBannerToNext() {
        var offsetX = scrollView.contentOffset.x
        if dataSource.count <= 1 {
            offsetX = 0
        }
        let point = CGPoint(x: offsetX + cellSize.width, y: 0)
        scrollView.setContentOffset(point, animated: true)
    }
    
    func updateHostViewWidth(_ width: CGFloat) {
        let width = width - 2 * leftPadding
        let height = SKDisplay.pad ?
            width * 110.0 / 680.0 :
            width * 128.0 / 343.0 + leftPadding
        cellSize = CGSize(width: width, height: height)
        DocsLogger.debug("bannerView height debug: bannerView cellSize: \(cellSize), from updateHostViewWidth: \(width), scrollViewsize: \(scrollView.frame.size)")

        reloadBanner()
        for view in bannerViewArray {
            DocsLogger.debug("bannerView height debug: reloadBanner() 之后bannerView的size:\(view.frame.size)")
        }
    }
    private func reportShowBanner(banner: TemplateBanner) {
        TemplateCenterTracker.reportShowTemplateBannerTracker(bannerCount: dataSource.count,
                                                              bannerType: banner.bannerType,
                                                              topicId: banner.topicId,
                                                              templateId: banner.templateId,
                                                              openlink: banner.jumpLinkUrl,
                                                              bannerId: banner.bannerId)
        if let bannerId = banner.bannerId {
            TemplateCenterTracker.reportBannerShow(bannerId: bannerId)
        }
    }
}

extension TemplateBannerView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView, cellSize.width > 0.001 else { return }

        let offsetX = scrollView.contentOffset.x
        var needResetBannerViewsLayout = false
        if offsetX >= 2 * cellSize.width {
            // 刚刚滑动到第三个bannerView位置, 把第一个bannerView移动到末尾
            let bannerView = bannerViewArray.removeFirst()
            bannerViewArray.append(bannerView)
            needResetBannerViewsLayout = true
            var newIndex = curDataIndex + 1
            if newIndex == dataSource.count {
                newIndex = 0
            }
            curDataIndex = newIndex
        } else if offsetX <= 0 {
            let bannerView = bannerViewArray.removeLast()
            bannerViewArray.insert(bannerView, at: 0)
            needResetBannerViewsLayout = true
            var newIndex = curDataIndex - 1
            if newIndex == -1 {
                newIndex = dataSource.count - 1
            }
            curDataIndex = newIndex
        }
        
        if needResetBannerViewsLayout {
            resetBannerViewsLayout()
            setNextBanner()
            setPreBanner()
            pageControlView.updateCurIndex(to: curDataIndex)
            let bannerData = dataSource[curDataIndex]
            reportShowBanner(banner: bannerData)
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView == self.scrollView else { return }
        resetTimer(isStart: false)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == self.scrollView else { return }
        resetTimer(isStart: true)
    }
}

extension TemplateBannerView: BannerViewDelegate {
    fileprivate func didClickBannerView(_ bannerView: BannerView) {
        // 虽然目前手机上只能点击一个banner，所以取curDataIndex就行了
        guard curDataIndex >= 0, curDataIndex < dataSource.count else { return }
        let bannerData = dataSource[curDataIndex]
        self.delegate?.didClickBanner(at: curDataIndex, templateBanner: bannerData)
        TemplateCenterTracker.reportClickTemplateBannerTracker(bannerCount: dataSource.count,
                                                               bannerType: bannerData.bannerType,
                                                               topicId: bannerData.topicId,
                                                               templateId: bannerData.templateId,
                                                               openlink: bannerData.jumpLinkUrl,
                                                               bannerId: bannerData.bannerId)
        TemplateCenterTracker.reportBannerClick(bannerId: bannerData.bannerId ?? 0)
    }
}

private protocol BannerViewDelegate: AnyObject {
    func didClickBannerView(_ bannerView: BannerView)
}
private class BannerView: UIView {
    lazy var imageView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.layer.masksToBounds = true
        return imgView
    }()
    private var reuseBag = DisposeBag()
    private lazy var clickButton: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(clickButtonAction), for: .touchUpInside)
        return btn
    }()
    
    weak var delegate: BannerViewDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(clickButton)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        clickButton.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        clickButton.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func clickButtonAction() {
        delegate?.didClickBannerView(self)
    }
    
    func config(banner: TemplateBanner) {
        guard let imageUrl = banner.imageUrl, !imageUrl.isEmpty,
              let url = URL(string: imageUrl) else {
            return
        }
        // 为了复用DocsRequest的cookie，以及缩图图manger的缓存逻辑，以及跟主端对接的清缓存逻辑，所以使用SpaceThumbnailManager
        let manager = DocsContainer.shared.resolve(SpaceThumbnailManager.self)!

        manager.getThumbnail(url: url, source: .template)
            .asDriver(onErrorJustReturn: UIImage())
            .drive(onNext: { [weak self] (image) in
                DocsLogger.info("BannerView image size:\(image.size)")
                self?.imageView.image = image
            })
            .disposed(by: reuseBag)
    }
}

class TemplateThemeHeaderView: UICollectionReusableView {
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        view.layer.borderWidth = 0.75
        view.layer.borderColor = UIColor.ud.N300.cgColor
        return view
    }()
    private lazy var shadowView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N00
        view.layer.cornerRadius = 6
        view.layer.shadowColor = UIColor.ud.N900.cgColor
        view.layer.shadowOpacity = 0.04
        view.layer.shadowOffset = CGSize(width: 0, height: 8.4)
        return view
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(shadowView)
        addSubview(imageView)
        let leftpadding: CGFloat = 16
        let topPadding: CGFloat = 16
        imageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(leftpadding)
            make.right.equalToSuperview().offset(-leftpadding)
            make.top.equalToSuperview().offset(topPadding)
            make.bottom.equalToSuperview()
        }
        shadowView.snp.makeConstraints { (make) in
            make.edges.equalTo(imageView)
        }
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class WeakProxy {
    private weak var bannerView: TemplateBannerView?
    
    init(bannerView: TemplateBannerView) {
        self.bannerView = bannerView
    }
    @objc
    func timerCount() {
        bannerView?.scrollBannerToNext()
    }
}

class BannerPageControlView: UIView {
    
    private var dotViews = [UIView]()
    private let indexLineView = UIView()
    
    private let dotHeight: CGFloat = 4
    private let dotPadding: CGFloat = 8
    private let indexLineWidth: CGFloat = 10
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        addSubview(indexLineView)
        indexLineView.snp.makeConstraints { (make) in
            make.height.equalTo(dotHeight)
            make.width.equalTo(indexLineWidth)
            make.centerY.equalToSuperview()
            make.left.equalTo(dotHeight)
        }
        indexLineView.layer.cornerRadius = dotHeight / 2.0
        indexLineView.layer.masksToBounds = true
        indexLineView.layer.borderWidth = 0.5
        indexLineView.layer.borderColor = UIColor.ud.N300.cgColor
        indexLineView.layer.zPosition = 200
        indexLineView.backgroundColor = UIColor.ud.N00 & UIColor.docs.rgb("C4C4C4")
        backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3) & UIColor.docs.rgb("1F2329").withAlphaComponent(0.4)
    }
    // 刷新pageControl的个数，然后返回宽度，让父控件重新布局，主要是改变centerX
    func resetPageControl(with count: Int) -> CGFloat {
        dotViews.forEach({ $0.removeFromSuperview() })
        dotViews.removeAll()
        let realCount = count - 1
        for i in 0...realCount {
            let view = UIView()
            view.backgroundColor = UIColor.ud.N00.withAlphaComponent(0.5) & UIColor.docs.rgb("FFFFFF").withAlphaComponent(0.5)
            view.layer.borderWidth = 0.5
            view.layer.ud.setBorderColor(UIColor.ud.N300 & UIColor.docs.rgb("F0F0F0").withAlphaComponent(0.15))
            view.layer.cornerRadius = dotHeight / 2.0
            view.layer.zPosition = 100
            addSubview(view)
            let x = dotPadding + (dotHeight + dotPadding) * CGFloat(i)
            
            view.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.width.height.equalTo(dotHeight)
                make.left.equalTo(x)
            }
            dotViews.append(view)
        }
        let totalWidth: CGFloat = dotPadding + (dotHeight + dotPadding) * CGFloat(count)
        return totalWidth
    }
    
    func updateCurIndex(to index: Int) {
        guard index >= 0, index < dotViews.count else { return }
        let dotView = dotViews[index]
        var newFrame = indexLineView.frame
        newFrame.origin.x = dotView.center.x - indexLineWidth / 2.0
        UIView.animate(withDuration: 0.2) {
            self.indexLineView.frame = newFrame
        }
    }
}
