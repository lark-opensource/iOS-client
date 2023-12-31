//
//  BTSKeletonView.swift.swift
//  SKBitable
//
//  Created by X-MAN on 2023/10/10.
//

import Foundation

public final class BTSkeletonView: UIView {
    
    init() {
        super.init(frame: .zero)
        self.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if let loadingLayer = layer.sublayers?.first(where: {
            $0.isKind(of: CAGradientLayer.self)
        }) {
            adjustLoadingLayer(loadingLayer)
        }
    }
    
    func adjustLoadingLayer(_ layer: CALayer) {
        layer.frame = bounds
    }
}
