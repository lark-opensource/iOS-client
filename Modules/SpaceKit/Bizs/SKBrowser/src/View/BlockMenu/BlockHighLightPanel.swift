//
//  BlockHighLightPanel.swift
//  SKDoc
//
//  Created by zoujie on 2021/1/24.
//  


import SKFoundation

public final class BlockHighLightPanel: BlockMenuBaseView {

    public weak var colorPickerPanelV2: ColorPickerPanelV2?
    private lazy var currentContenView: UIView = UIView().construct { (ct) in
        ct.clipsToBounds = true
        ct.backgroundColor = .clear
        ct.layer.cornerRadius = 4
    }
    
   public init(colorPickerPanelV2: ColorPickerPanelV2?) {
        colorPickerPanelV2?.isNewShowingMode = true
        self.colorPickerPanelV2 = colorPickerPanelV2
        super.init(shouldShowDropBar: true, isNewMenu: true)
        self.contentView.clipsToBounds = true
        menuLevel = 2
        addSubview()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        countMenuSize()
    }
    
    override func countMenuSize() {
        guard let superview = self.superview else { return }
        menuHeight = 361
        menuWidth = superview.frame.width - 2 * menuMargin - 2 * offsetLeft - (delegate?.getCommentViewWidth ?? 0)
        super.countMenuSize()
    }

    private func addSubview() {
        guard let colorPickerView = colorPickerPanelV2 else { return }
        if !contentView.subviews.contains(currentContenView) {
            contentView.addSubview(currentContenView)
        }
        contentView.layer.cornerRadius = self.layer.cornerRadius
        contentView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(shouldShowDropBar ? 16 : 0)
        }
        
        currentContenView.addSubview(colorPickerView)

        colorPickerView.layer.cornerRadius = 4
        colorPickerView.clipsToBounds = true

        currentContenView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        colorPickerView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        countMenuSize()
    }

    public override func refreshLayout() {
        if isMyWindowCompactSize() {
            hideMenu()
            delegate?.closeMenu(level: self.menuLevel)
            return
        }
        layoutIfNeeded()
        countMenuSize()
        super.refreshLayout()
        colorPickerPanelV2?.refreshViewLayout()
    }

    public override func showMenu() {
        if currentContenView.subviews.count == 0 {
           addSubview()
        }
        countMenuSize()
        super.showMenu()
        DispatchQueue.main.async {
            self.colorPickerPanelV2?.refreshViewLayout()
        }
        
    }

    public override func scale(leftOffset: CGFloat, isShrink: Bool = true) {
        offsetLeft = isShrink ? leftOffset : 0
        layoutIfNeeded()
        countMenuSize()
        super.scale(leftOffset: leftOffset, isShrink: isShrink)
    }
}
