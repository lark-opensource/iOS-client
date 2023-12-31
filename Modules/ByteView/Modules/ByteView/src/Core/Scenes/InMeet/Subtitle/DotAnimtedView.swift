//
//  DotAnimtedView.swift
//  ByteView
//
//  Created by Yang Yao on 7/13/22.
//

import Foundation
import UIKit

class DotAnimtedView: UIView {
  let leftDot = UIView()
  let centerDot = UIView()
  let rightDot = UIView()

  let dotSize = 3.0
  let animateDuration = 0.5

  var timer: Timer?

  override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(leftDot)
    addSubview(centerDot)
    addSubview(rightDot)

    leftDot.backgroundColor = .white
    centerDot.backgroundColor = .white
    rightDot.backgroundColor = .white

    let cornerRadius = dotSize / 2.0
    leftDot.layer.cornerRadius = cornerRadius
    centerDot.layer.cornerRadius = cornerRadius
    rightDot.layer.cornerRadius = cornerRadius

    reset()
    startAnimation()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    timer?.invalidate()
    timer = nil
  }

  func startAnimation() {
    let loopDuration = animateDuration * 3
    timer = Timer(timeInterval: loopDuration, repeats: true, block: { [weak self] _ in
      self?.reset()
      self?.animate()
    })
    if let timer = timer {
      RunLoop.current.add(timer, forMode: .common)
      timer.fire()
    }
  }

  func reset() {
    leftDot.alpha = 0.0
      centerDot.alpha = 0.0
      rightDot.alpha = 0.0
  }

    func animate() {
        let duration = animateDuration
        UIView.animate(withDuration: duration, animations: {
            self.leftDot.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: duration, animations: {
                self.centerDot.alpha = 1.0
            }, completion: { _ in
                UIView.animate(withDuration: duration, animations: {
                    self.rightDot.alpha = 1.0
                })
            })
        })
    }

  override func layoutSubviews() {
    super.layoutSubviews()

    let space = (bounds.size.width - dotSize * 3) / 2.0

    let originY = bounds.size.height / 2.0 - dotSize / 2.0
    leftDot.frame = CGRect(x: 0, y: originY, width: dotSize, height: dotSize)
    centerDot.frame = CGRect(x: leftDot.frame.maxX + space, y: originY, width: dotSize, height: dotSize)
    rightDot.frame = CGRect(x: centerDot.frame.maxX + space, y: originY, width: dotSize, height: dotSize)
  }
}
