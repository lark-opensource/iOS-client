//
//  ImageEditAddLineView.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/8/2.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit

protocol ImageEditAddLineViewDelegate: AnyObject {
    func addLineViewDidTapped(_ addLineView: ImageEditAddLineView)
    func addLineViewDidBeginToDraw(_ addLineView: ImageEditAddLineView)
    func addLineViewDrawing(_ addLineView: ImageEditAddLineView)
    func addLineViewDidFinishDrawing(_ addLineView: ImageEditAddLineView)
}

final class ImageEditAddLineView: ImageEditBaseView {
    weak var delegate: ImageEditAddLineViewDelegate?

    private(set) var lines: [ImageEditLine] = [] {
        didSet {
            if !lines.isEmpty {
                hasEverOperated = true
            }
        }
    }

    var currentColor: ColorPanelType = .default
    fileprivate var currentLine: ImageEditLine?

    var lineWidth: CGFloat

    var externScale: CGFloat = 1
    var currentScale: CGFloat { return transform.a }

    init(lineWidth: CGFloat) {
        self.lineWidth = lineWidth

        super.init(frame: CGRect.zero)
        backgroundColor = .clear
        let panGesture = lu.addPanGestureRecognizer(action: #selector(panGestureDidInvoke(gesture:)), target: self)
        panGesture.maximumNumberOfTouches = 1

        lu.addTapGestureRecognizer(action: #selector(tapGestureDidInvoke(gesture:)), target: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        var lines = self.lines
        if let currentLine = currentLine {
            lines.append(currentLine)
        }
        lines.forEach { (line) in
            line.color.color().set()
            line.lineJoinStyle = .round
            line.lineCapStyle = .round
            line.stroke()
        }
    }

    @objc
    private func tapGestureDidInvoke(gesture: UITapGestureRecognizer) {
        delegate?.addLineViewDidTapped(self)
    }

    @objc
    func panGestureDidInvoke(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            currentLine = ImageEditLine(color: currentColor)
            currentLine?.lineWidth = lineWidth / externScale / currentScale
            currentLine?.add(point: gesture.location(in: self))
            delegate?.addLineViewDidBeginToDraw(self)
        case .changed:
            currentLine?.add(point: gesture.location(in: self))
            setNeedsDisplay()
            delegate?.addLineViewDrawing(self)
        case .possible:
            break
        case .cancelled, .ended, .failed:
            if let newLine = currentLine {
                currentLine = nil
                addLine(newLine)
                delegate?.addLineViewDidFinishDrawing(self)
            }
        @unknown default:
            break
        }
    }

    @objc
    private func addLine(_ line: ImageEditLine) {
        lines.append(line)
        setNeedsDisplay()
        imageUndoManager()?.registerAndNotifyUndo(withTarget: self, handler: { (target) in
            target.removeLine(line)
        })
    }

    @objc
    private func removeLine(_ line: ImageEditLine) {
        lines.removeAll(where: { $0 === line })
        setNeedsDisplay()
        imageUndoManager()?.registerAndNotifyUndo(withTarget: self, handler: { (target) in
            target.addLine(line)
        })
    }
}
