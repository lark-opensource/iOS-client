//
//  DocsKeyboardObservingView.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/3/6.
//

import Foundation
import RxSwift

protocol DocsKeyboardObservingViewDelegate: AnyObject {
    func keyboardFrameChanged(frame: CGRect)
}

public final class DocsKeyboardObservingView: UIView {
    weak var delegate: DocsKeyboardObservingViewDelegate?

    private var disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func willMove(toSuperview newSuperview: UIView?) {
        guard newSuperview != nil else {
            disposeBag = DisposeBag()
            return
        }
        newSuperview?.rx.observe(CGPoint.self, "center", options: [.initial, .new])
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let newFrame = self.superview?.frame {
                    self.delegate?.keyboardFrameChanged(frame: newFrame)
                }
            })
            .disposed(by: disposeBag)
    }
}
