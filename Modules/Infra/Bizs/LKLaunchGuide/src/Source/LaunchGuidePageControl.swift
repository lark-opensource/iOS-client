//
//  LaunchGuidePageControl.swift
//  AFgzipRequestSerializer
//
//  Created by Miaoqi Wang on 2020/3/26.
//

import UIKit
import Foundation

private struct Layout {
    static let indicatorWidth: CGFloat = 15
    static let indicatorHeight: CGFloat = 3
    static let interval: CGFloat = 4
}

final class LaunchGuidePageControl: UIView {
    let indicatorWidth: CGFloat = Layout.indicatorWidth
    let indicatorHeight: CGFloat = Layout.indicatorHeight
    let interval: CGFloat = Layout.interval

    weak var delegate: LaunchGuideDelegate?
    var lastCenterX: CGFloat = Layout.indicatorWidth/2

    override func layoutSubviews() {
        super.layoutSubviews()
        self.selectView?.center = CGPoint(
            x: lastCenterX,
            y: self.selectView!.center.y
        )
    }

    var currentPage: Int = 0 {
        didSet {
            let trackIndex = self.currentPage + 1
            Tracker.trackGuideShow(index: trackIndex)
            delegate?.launchGuideDidShowPage(index: trackIndex)
        }
    }
    var numberOfPages: Int = 0 {
        didSet {
            setupSubviews()
        }
    }
    var selectView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        guard numberOfPages > 0 else { return }

        var leftView: UIView = self
        for i in 0..<numberOfPages {
            let view = UIView()
            view.backgroundColor = UIColor.ud.iconDisabled
            view.layer.cornerRadius = indicatorHeight / 2
            self.addSubview(view)
            view.snp.makeConstraints { (make) in
                if i == 0 {
                    make.left.equalToSuperview()
                } else {
                    make.left.equalTo(leftView.snp.right).offset(interval)
                }
                if i == numberOfPages - 1 {
                    make.right.equalToSuperview()
                }
                make.width.equalTo(indicatorWidth)
                make.height.equalTo(indicatorHeight)
                make.top.bottom.equalToSuperview()
            }
            leftView = view
        }
        self.selectView = UIView()
        self.addSubview(self.selectView!)
        self.selectView?.backgroundColor = UIColor.ud.iconN1
        self.selectView?.snp.makeConstraints({ (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(indicatorWidth)
            make.height.equalTo(indicatorHeight)
        })
        self.selectView?.layer.cornerRadius = indicatorHeight / 2
    }

    func updateSelectViewPosition(by offset: CGFloat, fromWidth: CGFloat) {
        self.lastCenterX = self.selectView!.frame.width / 2 + (indicatorWidth + interval) * offset / fromWidth
        self.selectView?.center = CGPoint(
            x: lastCenterX,
            y: self.selectView!.center.y
        )
    }
}
