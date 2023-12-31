//
//  SheetToolkitHostView.swift
//  SKSheet
//
//  Created by huayufan on 2021/1/28.
//  这个 view 会在 navigation controller 的 root view 下面
//  为了让 ipad 工具箱的旁边空白区域也支持 drag up，所以又写了一套 header 的逻辑


import UIKit
import SnapKit

protocol SheetToolkitHostViewDelegate: AnyObject {
    func didPanBegin(point: CGPoint, view: SheetToolkitHostView)
    func didPanMoved(point: CGPoint, view: SheetToolkitHostView)
    func didPanEnded(point: CGPoint, view: SheetToolkitHostView)
}

class SheetToolkitHostView: UIView {
    
    weak var delegate: SheetToolkitHostViewDelegate?
    lazy var topView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = .top
        view.layer.masksToBounds = true
        return view
    }()

    lazy var lineView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.N400
        return view
    }()
    
    lazy var contentView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBasic()
        addSubview(topView)
        addSubview(lineView)
        addSubview(contentView)
        setupLayout()
    }
    
    func setupBasic() {
        backgroundColor = .clear
        layer.construct {
            $0.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
            $0.shadowOpacity = 1
            $0.shadowOffset = CGSize(width: 0, height: -6)
            $0.shadowRadius = 24
        }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(didReceivePanGesture(gesture:)))
        topView.addGestureRecognizer(pan)
    }
    
    private func setupLayout() {
        topView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
        }
        lineView.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.bottom.equalTo(topView.snp.bottom)
            make.width.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.top.equalTo(lineView.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }
    }
    
    @objc
    func didReceivePanGesture(gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: self)
        if gesture.state == .began {
            delegate?.didPanBegin(point: point, view: self)
        } else if gesture.state == .changed {
            delegate?.didPanMoved(point: point, view: self)
        } else {
            delegate?.didPanEnded(point: point, view: self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
