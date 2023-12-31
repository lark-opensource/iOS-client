//
//  DocsStepperView.swift
//  SKCommon
//
//  Created by zoujie on 2022/4/28.
//  


import Foundation
import UIKit
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon

public final class DocsStepperView: UIView {
    private lazy var reduceButton = UIButton().construct { it in
        let reduceImage = UDIcon.getIconByKey(.reduceOutlined, size: CGSize(width: 16, height: 16))
        it.setImage(reduceImage.ud.withTintColor(UDColor.iconN1), for: [.normal])
        it.setImage(reduceImage.ud.withTintColor(UDColor.primaryContentDefault), for: [.highlighted])
        it.addTarget(self, action: #selector(reduceButtonTouchDown), for: .touchDown)
        it.addTarget(self, action: #selector(reduceButtonTouchCancel), for: .touchCancel)
        it.addTarget(self, action: #selector(reduceButtonTouchDragExit), for: .touchDragExit)
        it.addTarget(self, action: #selector(didClickReduce), for: .touchUpInside)
    }

    private lazy var addButton = UIButton().construct { it in
        let addImage = UDIcon.getIconByKey(.addOutlined, size: CGSize(width: 16, height: 16))
        it.setImage(addImage.ud.withTintColor(UDColor.iconN1), for: [.normal])
        it.setImage(addImage.ud.withTintColor(UDColor.primaryContentDefault), for: [.highlighted])
        it.addTarget(self, action: #selector(addButtonTouchDown), for: .touchDown)
        it.addTarget(self, action: #selector(addButtonTouchCancel), for: .touchCancel)
        it.addTarget(self, action: #selector(addButtonTouchDragExit), for: .touchDragExit)
        it.addTarget(self, action: #selector(didClickAdd), for: .touchUpInside)
    }

    private lazy var numberValue = UILabel().construct { it in
        it.font = .systemFont(ofSize: 14)
        it.textColor = UDColor.textTitle
        it.textAlignment = .center
    }

    private lazy var leftPartingLine = UIView().construct { it in
        it.backgroundColor = UDColor.N400
    }

    private lazy var rightPartingLine = UILabel().construct { it in
        it.backgroundColor = UDColor.N400
    }

    private var maxValue: Int
    private var minValue: Int
    private var currentValue: Int = 0

    public var valuePubish = PublishSubject<Int>()

    public init(minValue: Int = 0,
                maxValue: Int = 999) {
        self.minValue = minValue
        self.maxValue = maxValue
        super.init(frame: .zero)
        setUpUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func didClickReduce() {
        currentValue = max(currentValue - 1, minValue)
        updateUI()
        valuePubish.onNext(currentValue)
        reduceButton.backgroundColor = .clear
    }

    @objc
    func didClickAdd() {
        currentValue = min(currentValue + 1, maxValue)
        updateUI()
        valuePubish.onNext(currentValue)
        addButton.backgroundColor = .clear
    }

    @objc
    func reduceButtonTouchDown() {
        reduceButton.backgroundColor = UDColor.fillPressed
    }

    @objc
    func reduceButtonTouchCancel() {
        reduceButton.backgroundColor = .clear
    }

    @objc
    func reduceButtonTouchDragExit() {
        reduceButton.backgroundColor = .clear
    }

    @objc
    func addButtonTouchDown() {
        addButton.backgroundColor = UDColor.fillPressed
    }

    @objc
    func addButtonTouchCancel() {
        addButton.backgroundColor = .clear
    }

    @objc
    func addButtonTouchDragExit() {
        addButton.backgroundColor = .clear
    }

    public func setInitValue(vaule: Int) {
        currentValue = vaule
        updateUI()
    }

    func setUpUI() {
        addSubview(reduceButton)
        addSubview(leftPartingLine)
        addSubview(numberValue)
        addSubview(rightPartingLine)
        addSubview(addButton)

        layer.cornerRadius = 6
        layer.borderWidth = 1
        layer.ud.setBorderColor(UDColor.N400)
        clipsToBounds = true

        reduceButton.snp.makeConstraints { make in
            make.width.equalTo(32)
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(leftPartingLine.snp.left)
        }

        leftPartingLine.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.top.bottom.equalToSuperview()
            make.left.equalTo(reduceButton.snp.right)
            make.right.equalTo(numberValue.snp.left)
        }

        numberValue.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(leftPartingLine.snp.right)
            make.right.equalTo(rightPartingLine.snp.left)
        }

        rightPartingLine.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.top.bottom.equalToSuperview()
            make.left.equalTo(numberValue.snp.right)
            make.right.equalTo(addButton.snp.left)
        }

        addButton.snp.makeConstraints { make in
            make.width.equalTo(32)
            make.right.top.bottom.equalToSuperview()
            make.left.equalTo(rightPartingLine.snp.right)
        }

        updateUI()
    }

    func updateUI() {
        reduceButton.isEnabled = true
        addButton.isEnabled = true

        if currentValue == minValue {
            reduceButton.isEnabled = false
        } else if currentValue == maxValue {
            addButton.isEnabled = false
        }

        numberValue.text = String(currentValue)
    }

    public func shouldShowPartingLine(show: Bool) {
        rightPartingLine.isHidden = !show
        leftPartingLine.isHidden = !show
        layer.ud.setBorderColor(show ? UDColor.N400 : .clear)
        
        addButton.layer.cornerRadius = 6
        addButton.layer.borderWidth = show ? 0 : 1
        addButton.layer.ud.setBorderColor(show ? .clear : UDColor.N400)

        reduceButton.layer.cornerRadius = 6
        reduceButton.layer.borderWidth = show ? 0 : 1
        reduceButton.layer.ud.setBorderColor(show ? .clear : UDColor.N400)
    }
}
