//
//  SketchPencilHandler.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/12/10.
//

import Foundation
import RxSwift
import RustPB

private class SketchWeakProxy: NSObject {
    weak var target: SketchPencilHandler?

    init(target: SketchPencilHandler) {
        self.target = target
        super.init()
    }

    // pecker:ignore
    @objc func step(sender: CADisplayLink) {
        target?.step(sender: sender)
    }
}

class SketchPencilHandler: SketchNicknameHandler {
    let drawboard: DrawBoard
    let sketch: RustSketch

    private var displayLink: CADisplayLink?
    private var status: AnimationStatus = .paused
    private var byteviewUsers: [ShapeID: ByteviewUser] = [:]
    private let disposeBag = DisposeBag()

    private enum AnimationStatus {
        case paused
        case running
    }

    init(sketch: RustSketch, drawboard: DrawBoard, meeting: InMeetMeeting) {
        self.sketch = sketch
        self.drawboard = drawboard
        super.init(meeting: meeting)
    }

    deinit {
        displayLink?.invalidate()
    }

    func start(unit: SketchDataUnit) {
        guard unit.user.identifier != sketch.user.identifier else {
            sketch.receive(pencil: unit)
            let shapeID = unit.shapeID
            if unit.pencil.finish {
                let pencil = sketch.getPencilBy(id: shapeID)
                drawboard.updateRemote(pencil: pencil)
            }
            return
        }
        byteviewUsers[unit.shapeID] = unit.user.vcType
        switch self.status {
        case .paused:
            self.displayLink = CADisplayLink(target: SketchWeakProxy(target: self),
                                             selector: #selector(step(sender:)))
            self.displayLink?.add(to: .current, forMode: .common)
            self.displayLink?.isPaused = false
            sketch.receive(pencil: unit)
            self.status = .running
        case .running:
            sketch.receive(pencil: unit)
        }
    }

    @objc func step(sender: CADisplayLink) {
        let drawables = sketch.getPencilSnippet()
        if drawables.allSatisfy({ $0.finish || $0.pause }) || drawables.isEmpty {
            sender.invalidate()
            self.status = .paused
            self.displayLink = nil
        }

        for drawable in drawables {
            let wholeDrawable = sketch.getPencilBy(id: drawable.id)
            drawboard.updateRemote(pencil: wholeDrawable)
            if let user = byteviewUsers[drawable.id], let endPoint = drawable.points.last {
                singleNicknameDrawable(with: user, shapeID: drawable.id, position: CGPoint(x: endPoint.x + 3, y: endPoint.y)) { [weak self] in
                    self?.drawboard.updateNickname(drawable: $0)
                }
            }
        }
    }
}
