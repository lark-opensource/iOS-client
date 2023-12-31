//
//  FoldView.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/9/16.
//

import Foundation
import UIKit

public final class FoldMessageView: UIView {
    var tapBlock: (() -> Void)?
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgFloat
//        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
//        self.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        tap()
    }

    func tap() {
        self.tapBlock?()
    }
}
