//
//  TimeZoneSelectListViewController.swift
//  SKCommon
//
//  Created by zengsenyuan on 2022/6/1.
//  


import SKUIKit
import SKFoundation
import BDXLynxKit
import BDXServiceCenter
import BDXBridgeKit
import CoreGraphics
import UniverseDesignColor


public final class TimeZoneSelectListViewController: DraggableViewController, UIViewControllerTransitioningDelegate {
    
    public var isIpadAndNoSplit: Bool = false
    
    public var didFinishSelect: (() -> Void)?
    
    public var commonTrackParams: [String: String] = [:]
    
    private var timeZone: String
    
    private var model: BrowserModelConfig
    
    private var timeZoneList: [[String: Any]]
    
    private weak var presentation: SKDimmingPresentation?
    
    lazy var timeZoneListView = TimeZoneSelectListView(frame: self.view.bounds,
                                                       timeZone: timeZone,
                                                       timeZoneList: timeZoneList,
                                                       model: model,
                                                       isIpadAndNoSplit: isIpadAndNoSplit)

    
    public init(timeZone: String, timeZoneList: [[String: Any]], model: BrowserModelConfig) {
        self.timeZone = timeZone
        self.timeZoneList = timeZoneList
        self.model = model
        super.init(nibName: nil, bundle: nil)
        self.contentViewMinY = 124
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isIpadAndNoSplit {
            timeZoneListView.lynxView?.triggerLayout()
        }
    }

    private func setupView() {
        
        let bgColor = UIColor.ud.bgFloat
        if isIpadAndNoSplit {
            view.backgroundColor = bgColor
            view.addSubview(timeZoneListView)
            timeZoneListView.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            timeZoneListView.didPressBack = {[weak self] in
                self?.trackEvent(.cancel)
                self?.navigationController?.popViewController(animated: true)
            }
            timeZoneListView.didFinishSelect = {[weak self] in
                self?.didFinishSelect?()
            }
        } else {
            
            let dismissCover = UIView().construct({
                $0.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
                $0.layer.shadowOffset = CGSize(width: 5, height: -10)
                $0.layer.shadowOpacity = 2
                $0.layer.shadowRadius = 22
                $0.isUserInteractionEnabled = true
                $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapDismiss)))
            })
            
            contentView = UIView().construct({
                $0.backgroundColor = bgColor
                $0.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
                $0.layer.shadowOffset = CGSize(width: 5, height: -10)
                $0.layer.shadowOpacity = 2
                $0.layer.shadowRadius = 22
                $0.layer.cornerRadius = 12
                $0.layer.maskedCorners = .top
                $0.addGestureRecognizer(panGestureRecognizer)
                
            })
            
            let topDragView = UIView().construct {
                $0.backgroundColor = .clear
            }
            
            let dragViewLine = UIView().construct { it in
                it.backgroundColor = UDColor.lineBorderCard
                it.layer.cornerRadius = 2
            }
            
            let bottomSafeAreaView = UIView().construct {
                $0.backgroundColor = bgColor
            }
            
            view.addSubview(dismissCover)
            view.addSubview(contentView)
            view.addSubview(bottomSafeAreaView)
            contentView.addSubview(topDragView)
            contentView.addSubview(timeZoneListView)
            topDragView.addSubview(dragViewLine)
            
            dismissCover.snp.makeConstraints { (make) in
                make.left.right.top.equalToSuperview()
                make.bottom.equalTo(contentView.snp.top)
            }
    
            contentView.snp.makeConstraints { (make) in
                make.left.equalTo(self.view.safeAreaLayoutGuide.snp.left)
                make.right.equalTo(self.view.safeAreaLayoutGuide.snp.right)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
                make.top.equalTo(contentViewMinY)
            }
            // 这个要在 contentView 布局后才能设置。
            self.gapState = .min
            
            bottomSafeAreaView.snp.makeConstraints {
                $0.bottom.left.right.equalToSuperview()
                $0.top.equalTo(contentView.snp.bottom)
            }
           
            topDragView.snp.makeConstraints {
                $0.left.top.right.equalToSuperview()
                $0.height.equalTo(12)
            }
            
            timeZoneListView.snp.makeConstraints {
                $0.left.bottom.right.equalToSuperview()
                $0.top.equalTo(topDragView.snp.bottom)
            }
            
            dragViewLine.snp.makeConstraints {
                $0.center.equalToSuperview()
                $0.height.equalTo(4)
                $0.width.equalTo(40)
            }
            
            timeZoneListView.didFinishSelect = {[weak self] in
                guard let self = self else { return }
                self.presentation?.isNeedChangeDimmingWhenDismiss = false
                self.dismiss(animated: false) {
                    self.didFinishSelect?()
                }
            }
        }
        
        timeZoneListView.didClickItem = {[weak self] in
            self?.trackEvent(.item($0))
        }
    }
    
    @objc
    private func tapDismiss() {
        trackEvent(.cancel)
        self.dismiss(animated: true, completion: nil)
    }
    
    public override func dragDismiss() {
        trackEvent(.cancel)
        self.dismiss(animated: true, completion: nil)
    }
    
    public override func dragFinish() {
        self.timeZoneListView.notifySizeChangeIfNeed(type: .height)
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentation = SKDimmingPresentation(presentedViewController: presented, presenting: presenting)
        self.presentation = presentation
        return presentation
    }
    
    enum TrackEventType {
    case item(String)
    case cancel
    }
    
    private func trackEvent(_ eventType: TrackEventType) {
        var params = commonTrackParams
        switch eventType {
        case .item(let selected):
            params.updateValue("time_zone_type", forKey: "click")
            params.updateValue("none", forKey: "target")
            params.updateValue(selected, forKey: "time_zone_type_value")
        case .cancel:
            params.updateValue("cancel", forKey: "click")
            params.updateValue("none", forKey: "target")
        }
        params.updateValue("bitable_app", forKey: "bitable_type")
        params.updateValue("true", forKey: "is_full_screen")
        DocsTracker.newLog(enumEvent: .bitableTimeZoneSettingClick, parameters: params)
    }
}
