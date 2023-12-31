//
//  SketchCometHandler.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/12/9.
//

import Foundation
import QuartzCore
import RxSwift

private class SketchWeakProxy: NSObject {
    weak var target: SketchCometHandler?

    init(target: SketchCometHandler) {
        self.target = target
        super.init()
    }

    // pecker:ignore
    @objc func step(sender: CADisplayLink) {
        target?.step(sender: sender)
    }
}

class SketchCometHandler: SketchNicknameHandler, CALayerDelegate {
    let cometLayer: CALayer
    let sketch: RustSketch
    private var displayLink: CADisplayLink?
    private var status: AnimationStatus = .paused

    private enum AnimationStatus {
        case paused
        case running
    }

    private var drawable: CometSnippetDrawable? {
        didSet {
            cometLayer.setNeedsDisplay()
        }
    }

    init(sketch: RustSketch, meeting: InMeetMeeting) {
        self.cometLayer = CALayer()
        self.sketch = sketch
        super.init(meeting: meeting)
        self.cometLayer.delegate = self
    }

    deinit {
        // Another thing to be careful of is that a layer’s reference to its delegate is ARC-weak.
        // This means that if you set a layer’s delegate, you must not allow the delegate object
        // to go out of existence before the layer itself does. Letting that happen is a good way to crash mysteriously.
        // Programming iOS 12, Ninth Edition by Matt Neuburg
        self.cometLayer.delegate = nil
        displayLink?.invalidate()
    }

    func start(data: SketchDataUnit) {
        switch self.status {
        case .paused:
            self.displayLink = CADisplayLink(target: SketchWeakProxy(target: self),
                                             selector: #selector(step(sender:)))
            self.displayLink?.add(to: .current, forMode: .common)
            self.displayLink?.isPaused = false
            sketch.receive(comet: data)
            self.status = .running
        case .running:
            sketch.receive(comet: data)
        }
    }

    func draw(_ layer: CALayer, in ctx: CGContext) {
        drawable?.drawIn(context: ctx)
    }

    func clearContext() {
        displayLink?.invalidate()
        status = .paused
        cometLayer.contents = nil
    }

    @objc func step(sender: CADisplayLink) {
        let snippet = sketch.getCometSnippet()

        self.drawable = snippet

        if snippet.pause || snippet.exit {
            sender.invalidate()
            self.status = .paused
            self.displayLink = nil
        }

        if snippet.exit {
            ByteViewSketch.logger.info("comet exited")
            self.drawable = nil
        }
    }
}
