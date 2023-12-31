//
//  LocalStatusControl.swift
//  LarkMessageCore
//
//  Created by Meng on 2019/4/2.
//

import Foundation
import UIKit

extension LocalStatusControl {

    public enum Status {
        case loading, failed, normal
    }

}

public final class LocalStatusControl: UIControl {

    private var iconView = UIImageView(frame: .zero)

    public var status: Status = .normal {
        didSet {
            _updateUI()
        }
    }

    public override var frame: CGRect {
        didSet { iconView.frame = bounds }
    }

    public var onTapped: ((LocalStatusControl) -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func _updateUI() {
        iconView.lu.removeRotateAnimation()
        switch status {
        case .loading:
            iconView.image = BundleResources.status_send_loading
            iconView.lu.addRotateAnimation()
        case .failed:
            iconView.image = BundleResources.status_send_fail_light
        case .normal:
            iconView.image = nil
        }
    }

    private func _setup() {
        addSubview(iconView)
        _updateUI()
        self.addTarget(self, action: #selector(didTapped), for: .touchUpInside)
    }

    @objc
    func didTapped() {
        self.onTapped?(self)
    }

}
