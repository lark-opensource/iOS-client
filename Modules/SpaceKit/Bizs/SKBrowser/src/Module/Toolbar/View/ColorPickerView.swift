//
//  ColorPickerView.swift
//  SKBrowser
//
//  Created by zoujie on 2020/12/3.
//  


import Foundation
import SKCommon
import SKUIKit
import SKResource
import EENavigator
import UniverseDesignColor
import LarkContainer

public final class ColorPickerView: SKSubToolBarPanel {

    private var pickerViewHeight: CGFloat {
        get {
            if realPickerViewHeight == 0 {
                return 326 + (self.userResolver.navigator.mainSceneWindow?.safeAreaInsets.bottom ?? 0)
            } else {
                return realPickerViewHeight
            }
        }
        set {
            realPickerViewHeight = newValue
        }
    }
    
    private var realPickerViewHeight: CGFloat = 0
    
    private let navigationHeight: CGFloat = 48
    private var viewWidth: CGFloat = 0

    lazy private var colorPickerNavigationView: ColorPickerNavigationView = {
        let view = ColorPickerNavigationView(frame: .zero)
        view.backgroundColor = UDColor.bgBody
        view.titleLabel.text = BundleI18n.SKResource.Doc_Doc_ColorSelectTitle
        return view
    }()

    weak var colorPickerPanelV2: ColorPickerPanelV2?
    
    let userResolver: UserResolver
    
    init(colorPickerPanelV2: ColorPickerPanelV2, userResolver: UserResolver, width: CGFloat) {
        self.userResolver = userResolver
        colorPickerPanelV2.isHidden = false
        colorPickerPanelV2.isNewShowingMode = true
        self.colorPickerPanelV2 = colorPickerPanelV2
        self.viewWidth = width
        super.init(frame: .zero)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear
        layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
        layer.shadowOffset = CGSize(width: 0, height: -6)
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 24
        guard let colorPickerPanel = colorPickerPanelV2 else { return }

        colorPickerNavigationView.delegate = self
        colorPickerPanel.backgroundColor = UDColor.bgBody
        addSubview(colorPickerNavigationView)
        addSubview(colorPickerPanel)

        colorPickerPanel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.lessThanOrEqualTo(pickerViewHeight)
        }
        colorPickerNavigationView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalTo(colorPickerPanel.snp.top)
            make.height.equalTo(navigationHeight)
        }
    }

    public func setDisplayHeight(height: CGFloat) {
        guard height < (getCurrentDisplayHeight() ?? 0) else { return }
        colorPickerPanelV2?.collectionViewCanScroll = true
        pickerViewHeight = height - navigationHeight
    }

    public override func refreshViewLayout() {
        colorPickerPanelV2?.refreshViewLayout()
    }

    public override func getCurrentDisplayHeight() -> CGFloat? {
        return pickerViewHeight + navigationHeight
    }
}

extension ColorPickerView: ColorPickerNavigationViewDelegate {
    func colorPickerNavigationViewRequestExit(view: ColorPickerNavigationView) {
        let transition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = .push
        transition.subtype = .fromLeft
        self.superview?.layer.add(transition, forKey: nil)
        self.removeFromSuperview()
    }
}
