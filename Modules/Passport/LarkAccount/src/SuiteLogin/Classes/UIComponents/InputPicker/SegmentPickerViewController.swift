//
//  SegmentPickerViewController.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/8/17.
//

import UIKit
import LarkUIKit

typealias SegementPickerDataGetter = (_ segIndex: Int, _ superIndex: Int) -> [SegPickerItem]?

class SegmentPickerViewController: UIViewController {
    
    enum PickerPresentationStyle {
        case full                           // 完整尺寸，在 iPad 上使用
        case sheet                          // 高度 *0.7，在 iPhone 上使用
        case fixedHeight(height: CGFloat)   // 固定高度，在 Lark SSO 登录选择后缀时使用
    }

    private var isFirstLayout: Bool = true
    private var pickerView: SegmentPickerView!
    private var presentationStyle: PickerPresentationStyle
    private var didDisappearBlock: (() -> Void)?

    init(segStyle: PickerSegmentView.Style = .default,
         headerStyle: SegmentPickerView.SegmentPickerHeaderStyle = .original,
                  presentationStyle: SegmentPickerViewController.PickerPresentationStyle = .sheet,
         dataSource: [(String, [SegPickerItem])],
         didSelect: @escaping ([Int]) -> Void,
         didDisappear: (() -> Void)? = nil,
         newDataGetter: SegementPickerDataGetter? = nil) {
        self.presentationStyle = presentationStyle
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = self
        didDisappearBlock = didDisappear
        self.pickerView = SegmentPickerView(
            segStyle: segStyle,
            dataSource: dataSource,
            didSelect: { [weak self] indexes in
                didSelect(indexes)
                self?.close()
            },
            headerStyle: headerStyle,
            newDataGetter: newDataGetter,
            cancel: { [weak self] in
                self?.close()
            })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(pickerView)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(close))
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
        pickerView.snp.makeConstraints { (make) in
            make.bottom.right.left.equalToSuperview()
            switch presentationStyle {
            case .full:
                make.height.equalToSuperview()
            case .sheet:
                make.height.equalToSuperview().multipliedBy(0.7)
            case .fixedHeight(let height):
                make.height.equalTo(height)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        didDisappearBlock?()
    }

    @objc
    func close() {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirstLayout {
            isFirstLayout = false
            pickerView.updateInitIndexIfNeed()
        }
    }
}

extension SegmentPickerViewController: UIViewControllerTransitioningDelegate {
    public func presentationController(forPresented presented: UIViewController,
                                       presenting: UIViewController?,
                                       source: UIViewController)
        -> UIPresentationController? {
            return PickerPresentationController(presentedViewController: presented, presenting: presenting)
    }

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return nil
    }

    public func animationController(forDismissed dismissed: UIViewController) ->
        UIViewControllerAnimatedTransitioning? {
            return nil
    }
}

extension SegmentPickerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == view
    }
}
