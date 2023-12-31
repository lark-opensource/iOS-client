// 
// Created by duanxiaochen.7 on 2020/5/6.
// Affiliated with SpaceKit.
// 
// Description:

import Foundation
import SKCommon
import SKResource
import UniverseDesignIcon

protocol SheetToolkitNavigationBarDelegate: AnyObject {
    func didReceivedTapGesture(view: SheetToolkitNavigationBar)
    func didReceivedPanBegin(point: CGPoint, view: SheetToolkitNavigationBar)
    func didReceivedPanMoved(point: CGPoint, view: SheetToolkitNavigationBar)
    func didReceivedPanEnded(point: CGPoint, view: SheetToolkitNavigationBar)
}

class SheetToolkitNavigationBar: UIView {
    weak var delegate: SheetToolkitNavigationBarDelegate?
    
    private let leftPadding: CGFloat = 16
    
    private lazy var backButton: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(onTapBack), for: .touchUpInside)
        btn.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
        btn.setImage(UDIcon.leftSmallCcmOutlined.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        btn.docs.addStandardHighlight()
        return btn
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        return label
    }()

    private lazy var splitLine: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    init(title: String, showSplit: Bool = true) {
        super.init(frame: .zero)
        titleLabel.text = title
        backgroundColor = UIColor.ud.bgBody
        
        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(splitLine)

        backButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.left.equalToSuperview().offset(leftPadding)
            make.top.equalToSuperview().offset(14)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
            make.left.greaterThanOrEqualTo(backButton.snp.right).offset(leftPadding)
        }

        splitLine.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.bottom.equalToSuperview()
        }
        splitLine.isHidden = !showSplit

        let pan = UIPanGestureRecognizer(target: self, action: #selector(didReceivePanGesture(gesture:)))
        self.addGestureRecognizer(pan)
    }

    @objc
    func didReceivePanGesture(gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: self)
        if gesture.state == .began {
            delegate?.didReceivedPanBegin(point: point, view: self)
        } else if gesture.state == .changed {
            delegate?.didReceivedPanMoved(point: point, view: self)
        } else {
            delegate?.didReceivedPanEnded(point: point, view: self)
        }
    }

    @objc
    func onTapBack() {
        delegate?.didReceivedTapGesture(view: self)
    }
    
    func setBackButton(isHidden: Bool) {
        backButton.isHidden = isHidden
    }
    
    func setTitleText(_ text: String?) {
        titleLabel.text = text
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
