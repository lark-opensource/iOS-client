//
//  WatermarkConfig.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/4/11.
//  

import Foundation
import LarkWaterMark
import LarkContainer
import RxSwift
import RxCocoa
import SKFoundation
import LarkSensitivityControl

public final class WatermarkViewConfig {
    
    //水印自定义服务
    var waterMarkCustomService: WaterMarkCustomService? {
        guard let service = implicitResolver?.resolve(WaterMarkCustomService.self) else {
            DocsLogger.info("[WatermarkViewConfig] get WaterMarkCustomService nil")
            return nil
        }
        return service
    }
    
    public var needAddWatermark = false {
        didSet {
            self.onFlagChanged()
        }
    }
    private weak var superView: UIView?
    //水印view
    private var waterMarkView: UIView?
    private let disposeBag = DisposeBag()

    private func onFlagChanged() {
        if needAddWatermark {
            guard let sView = superView else { return }
            add(to: sView)
        } else {
            removeFromSuperView()
        }
    }

    private var notLazyView: UIView?
    
    
    //用来渲染绘制到图片上的水印view
    private lazy var renderWaterView: UIView = {
        //获取可以绘制的水印view，先传.zero，业务图片渲染那里回根据传入的size再去改变水印view的frame
        return waterMarkCustomService?.getGlobalCustomWaterMarkViewWithFrame(.zero, forceShow: true) ?? UIView()
    }()

    lazy private(set) var view: UIView? = {
        guard let markText = SKUIKitConfig.shared.userWatermarkText else {
//            spaceAssertionFailure("watermarkText is nil")
            return nil
        }
        let watermark = WatermarkView(markText: markText)
        watermark.isUserInteractionEnabled = false
        watermark.backgroundColor = .clear
        watermark.contentMode = .center
        watermark.clipsToBounds = true
        notLazyView = watermark
        return watermark
    }()

    public init() {}

    public func add(to superView: UIView) {
        self.superView = superView
        guard needAddWatermark else { return }
        DocsLogger.info("[WatermarkViewConfig] needAddWatermark add to superview")
        
        if SKUIKitConfig.shared.enabelUseLarkWaterMarkSDK {
            waterMarkCustomService?.observeGlobalWaterMarkViewWithFrame(.zero, forceShow: true).observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] waterView in
                    guard let `self` = self else {
                        return
                    }
                    self.waterMarkView?.removeFromSuperview()
                    self.waterMarkView = waterView
                    superView.addSubview(waterView)
                    waterView.contentMode = .top
                    waterView.snp.makeConstraints { (make) in
                        make.edges.equalToSuperview()
                    }
                }).disposed(by: disposeBag)
        } else {
            view.map {
                superView.addSubview($0)
                $0.layer.zPosition = CGFloat.greatestFiniteMagnitude
                $0.snp.makeConstraints({ (make) in
                    make.edges.equalToSuperview()
                })
            }
        }
    }

    public func removeFromSuperView() {
        guard !needAddWatermark else { return }
        superView = nil
        DocsLogger.info("[WatermarkViewConfig] waterMark removeFromSuperView")
        if SKUIKitConfig.shared.enabelUseLarkWaterMarkSDK {
            if waterMarkView != nil {
                waterMarkView?.removeFromSuperview()
                waterMarkView = nil
            }
        } else {
            if notLazyView != nil {
                view.map {
                    $0.removeFromSuperview()
                }
                notLazyView = nil
            }
        }
    }
    
    public func renderWatermarkImage(context: CGContext, size: CGSize) {
        DocsLogger.info("[WatermarkViewConfig] renderWatermarkImage: use LarkWaterMarkSDK")
        //获取水印renderWaterView和 renderInContext需要在主线程执行
        DispatchQueue.main.async {
            UIGraphicsPushContext(context)
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 2.0, y: -2.0)
            self.renderWaterView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            //renderInContext在主线程绘制水印view有些卡顿
            //优先用drawHierarchy绘制，返回false再用renderInContext渲染
            do {
                // 敏感api管控 https://bytedance.feishu.cn/wiki/wikcn0fkA8nvpAIjjz4VXE6GC4f
                let tokenString = "LARK-PSDA-render_watermark"
                let token = Token(tokenString, type: .deviceInfo)
                let success = try DeviceInfoEntry.drawHierarchy(forToken: token,
                                                  view: self.renderWaterView,
                                                  rect: self.renderWaterView.bounds,
                                                  afterScreenUpdates: true)
                DocsLogger.info("[LarkSensitivityControl] [WatermarkViewConfig] drawHierarchy approved.")
                if !success {
                    DocsLogger.info("[WatermarkViewConfig] enderWatermarkImage: drawHierarchy false")
                    self.renderWaterView.layer.render(in: context)
                }
            } catch {
                DocsLogger.info("[LarkSensitivityControl] [WatermarkViewConfig] drawHierarchy rejected. error: \(error.localizedDescription)")
                DocsLogger.info("[WatermarkViewConfig] enderWatermarkImage: drawHierarchy false")
                // 用renderInContext渲染
                self.renderWaterView.layer.render(in: context)
            }
            UIGraphicsPopContext()
        }
        
    }
    
    //获取当前后台明水印样式配置，兜底返回默认配置
    public func obviousWaterMarkPatternConfig() -> [String: String] {
        return waterMarkCustomService?.obvoiusWaterMarkConfig ?? [ : ]
    }
}
