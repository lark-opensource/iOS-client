//
//  MomentsSingleImageView.swift
//  Moment
//
//  Created by liluobin on 2021/1/15.
//

import Foundation
import UIKit
import LKCommonsLogging
import LarkMessageCore
import ByteWebImage

final class MomentsSingleImageView: UIView {
    static let logger = Logger.log(MomentsSingleImageView.self, category: "Module.Moments.MomentsSingleImageView")
    let displayImageView = SkeletonImageView()
    var setImageAction: SetImageAction
    var imageClick: ((UIImageView) -> Void)?

    init(setImageAction: SetImageAction, imageClick: ((UIImageView) -> Void)?) {
        self.setImageAction = setImageAction
        super.init(frame: .zero)
        setupView()
        updateViewWith(setImageAction: setImageAction, imageClick: imageClick)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        displayImageView.animateRunLoopMode = .default
        displayImageView.contentMode = .scaleAspectFill
        self.clipsToBounds = true
        self.addSubview(displayImageView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(click))
        self.addGestureRecognizer(tap)
    }

    func updateViewWith(setImageAction: SetImageAction, imageClick: ((UIImageView) -> Void)?) {
        self.setImageAction = setImageAction
        self.imageClick = imageClick
        self.setImageAction?(self.displayImageView, 0, { [weak self] (_, error) in
            if let error = error {
                Self.logger.error("\(error)")
                self?.displayImageView.image = Resources.imageDownloadFailed
                self?.displayImageView.contentMode = .center
            } else {
                self?.displayImageView.contentMode = .scaleAspectFill
            }
        })
    }

    func toggleAnimation(_ animated: Bool) {
        if animated {
            self.displayImageView.autoPlayAnimatedImage = true
            self.displayImageView.startAnimating()
        } else {
            self.displayImageView.autoPlayAnimatedImage = false
            self.displayImageView.stopAnimating()
        }
    }

    @objc
    func click() {
        self.imageClick?(self.displayImageView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if displayImageView.frame != self.bounds {
            displayImageView.frame = self.bounds
        }
    }
}
