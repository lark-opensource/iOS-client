//
//  LoadMoreView.swift
//  Calendar
//
//  Created by Rico on 2021/5/23.
//

import UniverseDesignIcon
import Foundation
import UIKit
import CalendarFoundation
import SnapKit
import UniverseDesignColor

protocol LoadMoreViewDataType {
    var state: LoadMoreState { get }
}

final class LoadMoreView: UIView, ViewDataConvertible {

    var viewData: LoadMoreViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            switch viewData.state {
            case .initial:
                loadingIcon.isHidden = true
                label.isHidden = true
                stopAnimation()
            case .noMore:
                loadingIcon.isHidden = true
                label.isHidden = false
                label.attributedText = noMoreHint
                stopAnimation()
            case .loading:
                loadingIcon.isHidden = false
                label.isHidden = true
                startAnimation()
            case let .failed(action):
                loadingIcon.isHidden = true
                label.isHidden = false
                label.attributedText = retryHint
                retryHandler = action
                stopAnimation()
            }
        }
    }

    private var retryHandler: LoadMoreState.RetryAction?

    override init(frame: CGRect) {
        super.init(frame: frame)

        layoutUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutUI() {
        addSubview(loadingIcon)
        addSubview(label)

        loadingIcon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(CGSize(width: 24, height: 24))
        }

        label.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    @objc
    private func retry() {
        retryHandler?()
    }

    private func startAnimation() {
        startZRotation()
    }

    private func stopAnimation() {
        self.loadingIcon.layer.removeAllAnimations()
    }

    private func startZRotation(duration: CFTimeInterval = 1, repeatCount: Float = Float.infinity, clockwise: Bool = true) {
        if self.layer.animation(forKey: "transform.rotation.z") != nil {
            return
        }
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        let direction = clockwise ? 1.0 : -1.0
        animation.toValue = NSNumber(value: Double.pi * 2 * direction)
        animation.duration = duration
        animation.isCumulative = true
        animation.repeatCount = repeatCount
        self.loadingIcon.layer.add(animation, forKey: "transform.rotation.z")
    }

    private var noMoreHint: NSAttributedString {
        let hint = NSAttributedString(string: BundleI18n.Calendar.Calendar_Common_AllGuestsShown,
                                      attributes: [
                                        .font: UIFont.cd.font(ofSize: 16),
                                        .foregroundColor: UIColor.ud.N600
                                      ])
        return hint
    }

    private var retryHint: NSAttributedString {
        let failed = NSMutableAttributedString(string: BundleI18n.Calendar.Calendar_Common_FailedToLoad + "  ",
                                        attributes: [
                                          .font: UIFont.cd.font(ofSize: 16),
                                          .foregroundColor: UIColor.ud.N600
                                        ])
        let retry = NSAttributedString(string: BundleI18n.Calendar.Calendar_Common_TryAgain,
                                       attributes: [
                                         .font: UIFont.cd.font(ofSize: 16),
                                         .foregroundColor: UIColor.ud.colorfulBlue
                                       ])
        failed.append(retry)
        return .init(attributedString: failed)
    }

    private lazy var loadingIcon: UIImageView = {
        let icon = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.chatLoadingOutlined).ud.withTintColor(UIColor.ud.primaryContentDefault))
        return icon
    }()

    private lazy var label: UILabel = {
        let label = UILabel.cd.textLabel(fontSize: 16)
        label.textColor = UIColor.ud.N600
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(retry)))
        return label
    }()
}
