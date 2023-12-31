//
//  SketchScreenWrapperView.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/12/16.
//

import UIKit
import SnapKit
import RxRelay
import RxSwift
import ByteViewRtcBridge

class SketchScreenWrapperView: UIView {

    var disposeBag = DisposeBag()

    var zoomScale: BehaviorRelay<CGFloat>? {
        didSet {
            disposeBag = DisposeBag()
            zoomScale?.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] scale in
                self?.sketchView?.zoomScale = scale
            })
            .disposed(by: disposeBag)
        }
    }

    // 视图层级: 视频 -> 标注 -> 鼠标
    private lazy var videoViewContainer = UIView()
    private lazy var sketchViewContainer = UIView()
    let videoView = StreamRenderView()
    private lazy var cursorLayer = CursorLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        // 防止鼠标超边界
        clipsToBounds = true

        addSubview(videoViewContainer)
        addSubview(sketchViewContainer)
        layer.addSublayer(cursorLayer)
        videoView.layoutType = "share_screen"
        videoView.isMini = false
        videoViewContainer.addSubview(videoView)
        videoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if let sketchView = self.sketchView {
            sketchView.snp.remakeConstraints {
                $0.edges.equalTo(videoView.videoContentLayoutGuide)
            }
        }

        videoViewContainer.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        sketchViewContainer.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        videoView.addListener(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var sketchView: SketchView? {
        willSet {
            sketchView?.removeFromSuperview()
        }
        didSet {
            if let view = sketchView {
                sketchViewContainer.addSubview(view)
                view.snp.makeConstraints {
                    $0.edges.equalTo(videoView.videoContentLayoutGuide)
                }
                view.zoomScale = zoomScale?.value ?? 1.0
            }
        }
    }

    private var isVideoViewRendering: Bool {
        return videoView.isRendering
    }

    func updateCursor(info: CursorInfo) {
        cursorLayer.updateCursor(info: info, isVideoViewRendering: isVideoViewRendering, containerFrame: frame)
    }
}

extension SketchScreenWrapperView: StreamRenderViewListener {
    func streamRenderViewDidChangeRendering(_ renderView: StreamRenderView, isRendering: Bool) {
        self.sketchViewContainer.isHidden = !isRendering
    }
}

class CursorLayer: CALayer {

    func updateCursor(info: CursorInfo, isVideoViewRendering: Bool, containerFrame: CGRect) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        isHidden = !info.enableCursorShare || info.isZero || !isVideoViewRendering
        contents = info.image?.cgImage

        let scaleX: CGFloat = {
            guard info.cursorFrame.sharedRectWidth > 0 else { return 0.0 }
            return containerFrame.width / info.cursorFrame.sharedRectWidth
        }()
        let scaleY: CGFloat = {
            guard info.cursorFrame.sharedRectHeight > 0 else { return 0.0 }
            return containerFrame.height / info.cursorFrame.sharedRectHeight
        }()

        frame = .init(
            x: {
                if info.cursorFrame.cursorRenderSrcX > 0 {
                    // 横轴超边界发生截断
                    return -info.cursorFrame.cursorRenderSrcX * scaleX
                } else {
                    return info.cursorFrame.cursorRenderDstX * scaleX
                }
            }(),
            y: {
                if info.cursorFrame.cursorRenderSrcY > 0 {
                    // 纵轴超边界发生截断
                    return -info.cursorFrame.cursorRenderSrcY * scaleY
                } else {
                    return info.cursorFrame.cursorRenderDstY * scaleY
                }
            }(),
            width: info.cursorFrame.cursorFrameWidth * scaleX,
            height: info.cursorFrame.cursorFrameHeight * scaleY
        )

        CATransaction.commit()
    }
}
