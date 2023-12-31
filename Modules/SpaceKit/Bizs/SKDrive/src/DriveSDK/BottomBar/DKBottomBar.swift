//
//  DKBottomBar.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/7/7.
//

import UIKit
import SKFoundation

protocol DKBottomBarItemView: UIView {
    var dismissed: ((DKBottomBarItemView) -> Void)? { get set }
}

class DKBottomBar: UIView {
    private lazy var container: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 0
        return stackView
    }()
    private lazy var bottomPlaceHolderView = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    private func setupSubviews() {
        backgroundColor = UIColor.ud.N00
        addSubview(container)
        addSubview(bottomPlaceHolderView)
        bottomPlaceHolderView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0)
        }
        container.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.bottom.equalTo(bottomPlaceHolderView.snp.top)
        }
        layer.shadowOffset = CGSize(width: 0.0, height: -1.0)
        layer.shadowColor = UIColor.ud.N1000.cgColor
        layer.shadowRadius = 5.0
        layer.shadowOpacity = 0.05
    }

    //更新底部safeArea高度
    override func safeAreaInsetsDidChange() {
        bottomPlaceHolderView.snp.updateConstraints { (make) in
            make.height.equalTo(safeAreaInsets.bottom)
        }
    }
        
    func pushItemVew(_ view: DKBottomBarItemView) {
        view.dismissed = {[weak self] view in
            guard let self = self else { return }
            if self.container.arrangedSubviews.count > 1 { // 有多个itemView，只将当前的itemView移除
                self.container.removeArrangedSubview(view)
            } else { // 只有一个itemView， 将buttombar dismiss
                self.dismiss(animate: true)
            }
        }
        container.addArrangedSubview(view)
    }
    
    func dismiss(animate: Bool) {
        guard let view = self.superview else { return }
        let interval = animate ? 0.2 : 0.0
        let height = container.intrinsicContentSize.height + view.safeAreaInsets.bottom

        UIView.animate(withDuration: interval, delay: 0.0, options: .curveEaseOut, animations: {
            self.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(height)
            }
            view.layoutIfNeeded()
        }, completion: { finished in
            if finished {
                self.removeFromSuperview()
            }
        })
    }
    
    func show(on view: UIView, animate: Bool) {
        view.addSubview(self)
        let height = container.intrinsicContentSize.height + view.safeAreaInsets.bottom
        self.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(height)
        }
        view.layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
            let interval = animate ? 0.2 : 0.0
            UIView.animate(withDuration: interval, delay: 0.0, options: .curveEaseOut, animations: {
                self.snp.updateConstraints { (make) in
                    make.bottom.equalToSuperview()
                }
                view.layoutIfNeeded()
            })
        }
    }
}
