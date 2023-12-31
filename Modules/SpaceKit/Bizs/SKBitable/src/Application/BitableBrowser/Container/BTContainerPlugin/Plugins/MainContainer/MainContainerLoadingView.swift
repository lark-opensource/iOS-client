//
//  MainContainerLoadingView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/9/7.
//

import Foundation
import SkeletonView
import UniverseDesignColor

fileprivate final class LoadingItemView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        let top = BTSkeletonView()
        top.isSkeletonable = true
        top.layer.cornerRadius = 7
        let second = BTSkeletonView()
        second.layer.cornerRadius = 7
        second.isSkeletonable = true
        let last = BTSkeletonView()
        last.layer.cornerRadius = 7
        last.isSkeletonable = true
        addSubview(top)
        addSubview(second)
        addSubview(last)
        top.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.height.equalTo(14)
            make.width.equalToSuperview()
            make.left.equalToSuperview()
        }
        second.snp.makeConstraints { make in
            make.height.equalTo(14)
            make.width.equalToSuperview()
            make.left.equalToSuperview()
            make.top.equalTo(top.snp.bottom).offset(20)
        }
        
        last.snp.makeConstraints { make in
            make.height.equalTo(14)
            make.left.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.441)
            make.bottom.equalToSuperview().offset(-6)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MainContainerLoadingView: UIView {
    struct Const {
        static let cornerRadius: CGFloat = 8
        static let itemHeight: CGFloat = 94
        static let margin: CGFloat = 16
    }
    private lazy var topLine: BTSkeletonView = {
        let view = BTSkeletonView()
        view.layer.cornerRadius = Const.cornerRadius
        view.isSkeletonable = true
        return view
    }()
    private lazy var secondLine: BTSkeletonView = {
        let view = BTSkeletonView()
        view.isSkeletonable = true
        view.layer.cornerRadius = Const.cornerRadius
        return view
    }()
    private lazy var topRight: BTSkeletonView = {
        let view = BTSkeletonView()
        view.isSkeletonable = true
        view.layer.cornerRadius = 2
        return view
    }()
    private lazy var topRight2: BTSkeletonView = {
        let view = BTSkeletonView()
        view.isSkeletonable = true
        view.layer.cornerRadius = 2
        return view
    }()
    
    private lazy var firstBlock: LoadingItemView = {
        let view = LoadingItemView()
        view.isSkeletonable = true
        return view
    }()
    
    private lazy var secondBlock: LoadingItemView = {
        let view = LoadingItemView()
        view.isSkeletonable = true
        return view
    }()
    
    private lazy var thirdBlock: LoadingItemView = {
        let view = LoadingItemView()
        view.isSkeletonable = true
        return view
    }()
    
    private lazy var fourthBlock: LoadingItemView = {
        let view = LoadingItemView()
        view.isSkeletonable = true
        return view
    }()
    
    private lazy var fifthBlock: LoadingItemView = {
        let view = LoadingItemView()
        view.isSkeletonable = true
        return view
    }()
    
    private lazy var sixthBlock: LoadingItemView = {
        let view = LoadingItemView()
        view.isSkeletonable = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = UDColor.bgBody    // 设置一个背景色防止底下内容提前透出
        
        layer.cornerRadius = BTContainer.Constaints.viewContainerCornerRadius     // 顶上要有圆角
        layer.maskedCorners = .top
        clipsToBounds = true
        
        addSubview(topLine)
        addSubview(secondLine)
        addSubview(topRight)
        addSubview(topRight2)
        addSubview(firstBlock)
        addSubview(secondBlock)
        addSubview(thirdBlock)
        addSubview(fourthBlock)
        addSubview(fifthBlock)
        addSubview(sixthBlock)
        topLine.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(22)
            make.left.equalToSuperview().offset(Const.margin)
            make.width.equalToSuperview().multipliedBy(0.288)
            make.height.equalTo(16)
        }
        secondLine.snp.makeConstraints { make in
            make.top.equalTo(topLine.snp.bottom).offset(30)
            make.left.equalTo(topLine)
            make.width.equalToSuperview().multipliedBy(0.208)
            make.height.equalTo(16)
        }
        topRight.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Const.margin)
            make.centerY.equalTo(secondLine.snp.centerY)
            make.size.equalTo(20)
        }
        topRight2.snp.makeConstraints { make in
            make.right.equalTo(topRight.snp.left).offset(-12)
            make.centerY.equalTo(topRight)
            make.size.equalTo(topRight)
        }
        firstBlock.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Const.margin)
            make.right.equalToSuperview().offset(-Const.margin)
            make.top.equalTo(secondLine.snp.bottom).offset(32)
            make.height.equalTo(Const.itemHeight)
        }
        secondBlock.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Const.margin)
            make.right.equalToSuperview().offset(-Const.margin)
            make.top.equalTo(firstBlock.snp.bottom).offset(32)
            make.height.equalTo(Const.itemHeight)
        }
        thirdBlock.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Const.margin)
            make.right.equalToSuperview().offset(-Const.margin)
            make.top.equalTo(secondBlock.snp.bottom).offset(32)
            make.height.equalTo(Const.itemHeight)
        }
        fourthBlock.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Const.margin)
            make.right.equalToSuperview().offset(-Const.margin)
            make.top.equalTo(thirdBlock.snp.bottom).offset(32)
            make.height.equalTo(Const.itemHeight)
        }
        fifthBlock.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Const.margin)
            make.right.equalToSuperview().offset(-Const.margin)
            make.top.equalTo(fourthBlock.snp.bottom).offset(32)
            make.height.equalTo(Const.itemHeight)
        }
        sixthBlock.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Const.margin)
            make.right.equalToSuperview().offset(-Const.margin)
            make.top.equalTo(fifthBlock.snp.bottom).offset(32)
            make.height.equalTo(Const.itemHeight)
        }
    }
}
