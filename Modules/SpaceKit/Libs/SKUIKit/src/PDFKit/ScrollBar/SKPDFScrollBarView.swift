//
//  SKScrollBarView.swift
//  Alamofire
//
//  Created by liweiye on 2019/5/24.
//

import SKResource
import Foundation
import UIKit
import SnapKit
import SKFoundation
import UniverseDesignColor

public protocol SKPDFScrollBarViewDelegate: AnyObject {
    /// 滚动球滑动时的回调
    /// - Parameters:
    ///   - scrollBar: 正在滑动的scrollBar
    ///   - page: 当前页码，1-index
    ///   - ratio: 当前滑动比例
    func scrollBarDidScroll(_ scrollBar: SKPDFScrollBarView, page: UInt, ratio: CGFloat)
    func scrollBarDidBeginScroll(_ scrollBar: SKPDFScrollBarView)
    func scrollBarDidEndScroll(_ scrollBar: SKPDFScrollBarView)
}

extension SKPDFScrollBarViewDelegate {
    func scrollBarDidBeginScroll(_ scrollBar: SKPDFScrollBarView) {}
    func scrollBarDidEndScroll(_ scrollBar: SKPDFScrollBarView) {}
}

public final class SKPDFScrollBarView: UIView {

    private let rollingballWidth: CGFloat
    private let rollingballHeight: CGFloat
    
    private lazy var rollingBallView: SKPDFRollingBallView = {
        let rollingBallView = SKPDFRollingBallView(frame: .zero)
        rollingBallView.layer.ud.setShadowColor(UDColor.shadowDefaultMd)
        rollingBallView.layer.shadowOffset = CGSize(width: 0, height: 3)
        rollingBallView.layer.shadowOpacity = 1
        rollingBallView.image = BundleResources.SKResource.Drive.drive_slide_bar
        rollingBallView.update(label: { (label) in
            label.text = "1"
            label.font = UIFont.ct.systemMedium(ofSize: 16)
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .center
        })
        return rollingBallView
    }()

    private lazy var originalRollingballView: SKPDFRollingBallView = {
        let rollingBallView = SKPDFRollingBallView(frame: .zero)
        rollingBallView.image = BundleResources.SKResource.Drive.drive_black_slide_bar
        rollingBallView.update(label: { (label) in
            label.font = UIFont.ct.systemMedium(ofSize: 10)
            label.textColor = UDColor.primaryOnPrimaryFill
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .center
        })
        return rollingBallView
    }()

    private lazy var placeHolderView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    // 是否需要开启历史记录功能
    var isNeedHistoricalRecords: Bool
    private(set) var isScrolling = false
    // 小球所在位置相对屏幕竖直方向上的比例
    public private(set) var ratio: CGFloat = 0.0
    public private(set) var currentPage: UInt = 1
    public var pageCount: UInt

    public weak var delegate: SKPDFScrollBarViewDelegate?

    public init(pageCount: UInt, rollingballWidth: CGFloat, rollingballHeight: CGFloat, isNeedHistoricalRecords: Bool = true) {
        self.pageCount = pageCount
        self.rollingballWidth = rollingballWidth
        self.rollingballHeight = rollingballHeight
        self.isNeedHistoricalRecords = isNeedHistoricalRecords
        super.init(frame: .zero)
        setupUI()
        setupGesture()
        setupBackgroundMonitor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        isHidden = true
        rollingBallView.alpha = 0
        addSubview(placeHolderView)
        placeHolderView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        addSubview(originalRollingballView)
        originalRollingballView.snp.makeConstraints { make in
            make.right.equalTo(safeAreaLayoutGuide.snp.right)
            make.width.equalTo(22)
            make.height.equalTo(24)
            make.centerY.equalTo(0)
        }
        originalRollingballView.isHidden = true
        addSubview(rollingBallView)
        rollingBallView.snp.makeConstraints { (make) in
            make.right.equalTo(safeAreaLayoutGuide.snp.right)
            make.centerY.equalTo(placeHolderView.snp.bottom)
            make.width.equalTo(rollingballWidth)
            make.height.equalTo(rollingballHeight)
        }
    }

    private func setupGesture() {
        let ges = UIPanGestureRecognizer(target: self, action: #selector(panRollingBall(recognizer:)))
        rollingBallView.addGestureRecognizer(ges)
    }

    private func setupBackgroundMonitor() {
        _ = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification,
                                                   object: nil,
                                                   queue: OperationQueue.main) { [weak self] _ in
                                                    self?.endScrolling()
        }
    }

    private func beginScrolling() {
        isScrolling = true
        delegate?.scrollBarDidBeginScroll(self)
        if isNeedHistoricalRecords {
            originalRollingballViewAppear(at: rollingBallView.frame.centerY)
        }
    }

    private func endScrolling() {
        isScrolling = true
        delegate?.scrollBarDidEndScroll(self)
        if isNeedHistoricalRecords {
            originalRollingballViewDisappear()
        }
    }

    // MARK: - 处理滑动手势
    @objc
    private func panRollingBall(recognizer: UIPanGestureRecognizer) {
        DocsLogger.info("panRollingBall -- ", extraInfo: ["state": recognizer.state.rawValue])

        if recognizer.state == .began {
            beginScrolling()
        }

        // 开始滑动时也通知delegate更新位置
        if recognizer.state == .changed || recognizer.state == .began {
            let location = recognizer.location(in: self)
            let totalLength = frame.height
            if location.y <= 0 {
                updateScrollBar(yPosition: 0.0)
            } else if location.y >= totalLength {
                updateScrollBar(yPosition: totalLength)
            } else {
                updateScrollBar(yPosition: location.y)
            }
        }

        if recognizer.state == .ended {
            endScrolling()
        }
    }

    private func updateScrollBar(yPosition: CGFloat) {
        let ratio = yPosition / frame.height
        placeHolderView.snp.updateConstraints { make in
            make.height.equalTo(self.frame.height * ratio)
        }
        guard pageCount >= 1 else { return }
        let page = UInt(ceil(CGFloat(pageCount - 1) * ratio + 1))
        delegate?.scrollBarDidScroll(self, page: page, ratio: ratio)
        self.currentPage = page
        self.ratio = ratio
        updateScrollBar(labelText: String(page))
    }

    // MARK: - 更新小球位置和内容

    public func updateScrollBar(page: UInt) {
        let ratio: CGFloat
        if page <= 0 {
            DocsLogger.error("drive.pdftron.scrollBar --- invalid page when update scroll bar", extraInfo: ["page": page])
        }
        if pageCount <= 1 || page <= 0 {
            ratio = 0
        } else {
            ratio = CGFloat(page - 1) / CGFloat(pageCount - 1)
        }
        updateScrollBar(ratio: ratio)
        updateScrollBar(labelText: String(page))
        self.currentPage = page
    }

    private func updateScrollBar(labelText text: String) {
        rollingBallView.text = text
    }

    private func updateScrollBar(ratio: CGFloat) {
        if ratio > 1 {
            DocsLogger.info("ratio > 1")
            self.ratio = 1
        } else if ratio < 0 {
            DocsLogger.info("ratio < 0")
            self.ratio = 0
        } else {
            self.ratio = ratio
        }

        placeHolderView.snp.updateConstraints { make in
            make.height.equalTo(self.frame.height * ratio)
        }

        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }

    // MARK: - 辅助功能
    public func fadeIn() {
        guard isHidden else {
            DocsLogger.info("Drive.PDF.scrollball --- ScrollBall already shown.")
            return
        }
        isHidden = false
        UIView.animate(withDuration: 0.5) {
            self.rollingBallView.alpha = 1
        }
    }

    public func fadeOut() {
        guard isHidden == false else {
            DocsLogger.info("Drive.PDF.scrollball --- ScrollBall already dissapear.")
            return
        }
        UIView.animate(withDuration: 0.5, animations: {
            self.rollingBallView.alpha = 0
        }, completion: { _ in
            self.isHidden = true
        })
    }

    //扩大滑动到顶部或底部时滚动球的响应范围
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden || self.alpha < 0.01 { return nil }
        for subview in subviews {
            let subPoint = subview.convert(point, from: self)
            guard let result = subview.hitTest(subPoint, with: event),
                result == rollingBallView else {
                    continue
            }
            return result
        }
        return nil
    }

    // MARK: - 小球历史记录
    private func originalRollingballViewAppear(at positionY: CGFloat) {
        originalRollingballView.snp.updateConstraints { (make) in
            make.centerY.equalTo(positionY)
        }
        if let text = rollingBallView.text {
            originalRollingballView.text = text
        }
        originalRollingballView.isHidden = false
    }

    private func originalRollingballViewDisappear() {
        originalRollingballView.isHidden = true
    }
}
