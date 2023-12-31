//
// Created by duanxiaochen.7 on 2019/8/12.
// Affiliated with SpaceKit.
//
// Description: Sheet Redesign - Toolbar

import RxSwift
import SKFoundation
import SKCommon
import SKBrowser
import SKResource
import UniverseDesignIcon
import UniverseDesignToast
import UniverseDesignColor
import SKUIKit

protocol SheetToolbarDelegate: AnyObject {
    var width: CGFloat { get }
    func didRequestHideKeyboard()
    func didRequestSwitchKeyboard(type: BarButtonIdentifier)
    func checkUploadPermission(_ showTips: Bool) -> Bool
}

class SheetToolbar: UIView {

    weak var delegate: SheetToolbarDelegate?

    let toolbarHeight: CGFloat = 44
    var lastToolBarWidth: CGFloat = 0

    private lazy var hideKeyboardButton = UIButton().construct { it in
        it.isAccessibilityElement = true
        it.accessibilityIdentifier = "sheets.keyboard.switch.collapse"
        it.setImage(UDIcon.keyboardDisplayOutlined.ud.withTintColor(UIColor.ud.iconN1),
                    for: [
                        .normal, .selected, .highlighted, UIControl.State.highlighted.union(.selected)
                    ])
        it.addTarget(self, action: #selector(didClickHideSystemKeyboard), for: .touchUpInside)
        it.backgroundColor = UIColor.ud.bgBody
        it.layer.ud.setShadowColor(UDColor.shadowDefaultSm)
        it.layer.shadowRadius = 4
        it.layer.shadowOpacity = 1
        it.layer.shadowOffset = CGSize(width: -2, height: 0)
    }

    private lazy var flowLayout = UICollectionViewFlowLayout().construct { it in
        let availableWidth = delegate?.width ?? SKDisplay.windowBounds(self).width
        it.scrollDirection = .horizontal
        it.minimumLineSpacing = 0
        it.minimumInteritemSpacing = 0
    }

    private lazy var mainBar = UICollectionView(frame: .zero, collectionViewLayout: flowLayout).construct { it in
        it.dataSource = self
        it.delegate = self
        it.delaysContentTouches = false
        it.backgroundColor = UIColor.ud.bgBody
        it.showsVerticalScrollIndicator = false
        it.showsHorizontalScrollIndicator = false
        it.register(SheetToolbarItemCell.self, forCellWithReuseIdentifier: SheetToolbarItemCell.reuseIdentifier)
    }
    
    private lazy var gradientShadow = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44)).construct { it in
        let layer = CAGradientLayer()
        layer.position = it.center
        layer.bounds = it.bounds
        it.layer.addSublayer(layer)
        layer.ud.setColors([
            UDColor.N00.withAlphaComponent(0.00),
            UDColor.N00.withAlphaComponent(0.70),
            UDColor.N00.withAlphaComponent(0.94)
        ])
        layer.locations = [0, 0.37, 1]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.needsDisplayOnBoundsChange = true
    }

    var badgedItems: [String] {
        toolbarItems
            .filter { $0.isBadged }
            .map { $0.id.rawValue }
    }

    var toolbarItems: [SheetToolbarItemInfo] = [] {
        didSet {
            let mainBarWidth = getAvailableMainBarWidth()
            if oldValue.count != toolbarItems.count {
                updateMainBarLayout(mainBarWidth)
            } else {
                if mainBarWidth != self.lastToolBarWidth {
                    updateMainBarLayout(mainBarWidth)
                }
            }
            updateMainBarData()
        }
    }

    private var needsScrollToRevealAllItems: Bool = false
    let disposeBag = DisposeBag()

    func updateCanScrollTips(_ offset: CGPoint) {
        if mainBar.contentSize.width > mainBar.frame.width, offset.x <= 0 {
            gradientShadow.isHidden = false
        } else {
            gradientShadow.isHidden = true
        }
    }
    
    init(delegate: SheetToolbarDelegate?) {
        self.delegate = delegate
        super.init(frame: .zero)
        self.backgroundColor = .clear

        addSubview(mainBar)
        addSubview(gradientShadow)
        addSubview(hideKeyboardButton)

        hideKeyboardButton.snp.makeConstraints { make in
            make.width.equalTo(toolbarHeight)
            make.trailing.bottom.top.equalToSuperview()
        }
        mainBar.snp.makeConstraints { (make) in
            make.leading.bottom.top.equalToSuperview()
            make.trailing.equalTo(hideKeyboardButton.snp.leading)
        }
        gradientShadow.snp.makeConstraints { (make) in
            make.width.height.equalTo(44)
            make.bottom.equalToSuperview()
            make.trailing.equalTo(hideKeyboardButton.snp.leading)
        }
        
        mainBar.rx.contentOffset
            .subscribe(onNext: { [weak self] offset in
                self?.updateCanScrollTips(offset)
            })
            .disposed(by: disposeBag)
    }
    
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        hideKeyboardButton.docs.removeAllPointer()
        hideKeyboardButton.docs.addStandardLift()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientShadow.layer.sublayers?.forEach { layer in
            if layer is CAGradientLayer {
                layer.position = gradientShadow.bounds.center
                layer.bounds = gradientShadow.bounds
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didClickHideSystemKeyboard() {
        delegate?.didRequestHideKeyboard()
    }
    
    private func getAvailableMainBarWidth() -> CGFloat {
        let availableMainBarWidth = (delegate?.width ?? frame.width) - toolbarHeight
        return availableMainBarWidth
    }

    func updateMainBarLayout(_ availableMainBarWidth: CGFloat) {
        let itemCount = CGFloat(toolbarItems.count)
        self.lastToolBarWidth = availableMainBarWidth
        var finalMainBarWidth = availableMainBarWidth
        let averageItemWidth = floor(availableMainBarWidth / itemCount)
        var itemWidth = averageItemWidth
        let maxItemWidth: CGFloat = 109
        let minItemWidth: CGFloat = 55
        if averageItemWidth > maxItemWidth { // toolbar reaches maximum width
            itemWidth = maxItemWidth
            finalMainBarWidth = maxItemWidth * itemCount
            mainBar.snp.remakeConstraints { (make) in
                make.bottom.top.equalToSuperview()
                make.center.equalToSuperview()
                make.width.equalTo(finalMainBarWidth)
            }
            needsScrollToRevealAllItems = false
        } else if averageItemWidth < minItemWidth { // cannot show all items at the same time
            var count = itemCount
            while itemWidth < minItemWidth {
                count -= 1
                itemWidth = floor(availableMainBarWidth / count)
            }
            mainBar.snp.remakeConstraints { (make) in
                make.leading.bottom.top.equalToSuperview()
                make.trailing.equalTo(hideKeyboardButton.snp.leading)
            }
            needsScrollToRevealAllItems = true
        } else { // toolbar item should fit evenly in available space
            mainBar.snp.remakeConstraints { (make) in
                make.leading.bottom.top.equalToSuperview()
                make.trailing.equalTo(hideKeyboardButton.snp.leading)
            }
            needsScrollToRevealAllItems = false
        }
        flowLayout.itemSize = CGSize(width: itemWidth, height: toolbarHeight)
        updateMainBarData()
        gradientShadow.isHidden = !needsScrollToRevealAllItems
    }

    func updateMainBarData() {
        mainBar.reloadData()
        if let selectedIndex = toolbarItems.firstIndex(where: { $0.isSelected == true }) {
            let indexPath = IndexPath(item: selectedIndex, section: 0)
            mainBar.selectItem(at: indexPath, animated: false, scrollPosition: .right)
        }
    }

    func switchSelectedItem(to newItemID: BarButtonIdentifier) {
        if let newSelectedItemIndex = toolbarItems.firstIndex(where: { $0.id == newItemID }) {
            let indexPath = IndexPath(item: newSelectedItemIndex, section: 0)
            mainBar.selectItem(at: indexPath, animated: false, scrollPosition: .right)
            collectionView(mainBar, didSelectItemAt: indexPath)
        }
    }

    func revealHiddenItemsIfNeededBeforeOnboarding(completion: @escaping () -> Void) {
        let hiddenItemIndexPath = IndexPath(item: toolbarItems.count - 1, section: 0)
        guard needsScrollToRevealAllItems else {
            DocsLogger.info("sheet 工具栏没有看不到的 item，显示引导前不需要滚一下", component: LogComponents.toolbar)
            completion()
            return
        }
        // collection view 动画时长要硬写，单纯用 DispatchQueue.main.async {} 是没用的
        mainBar.scrollToItem(at: hiddenItemIndexPath, at: .right, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) { [weak self] in
            self?.mainBar.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                completion()
            }
        }
    }

    func frameOfItem(id: BarButtonIdentifier) -> CGRect? {
        guard let index = toolbarItems.firstIndex(where: { $0.id == id }) else { return nil }
        let indexPath = IndexPath(item: index, section: 0)
        guard mainBar.indexPathsForVisibleItems.contains(indexPath),
              let cell = mainBar.cellForItem(at: indexPath) else { return nil }

        return mainBar.convert(cell.frame, to: self)
    }
}

extension SheetToolbar: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < toolbarItems.count else {
            return
        }
        let item = toolbarItems[indexPath.item]
        let tappedID = item.id
        if let previousSelectedItem = toolbarItems.first(where: { $0.isSelected == true }),
           let previousSelectedItemIndex = toolbarItems.firstIndex(where: { $0.id == previousSelectedItem.id }),
           previousSelectedItem.id != tappedID {
            if item.id == .insertImage &&
                !item.isEnabled &&
                !(delegate?.checkUploadPermission(true) ?? false) {
                toolbarItems[previousSelectedItemIndex].updateValue(toSelected: true)
                collectionView.selectItem(at: IndexPath(item: previousSelectedItemIndex, section: 0), animated: false, scrollPosition: .right)
                toolbarItems[indexPath.item].updateValue(toSelected: false)
                collectionView.deselectItem(at: indexPath, animated: false)
                self.delegate?.didRequestHideKeyboard()
                return
            }
            if toolbarItems[indexPath.item].hasSelectedState {
                toolbarItems[indexPath.item].updateValue(toSelected: true)
                // selection is performed by UIKit
                toolbarItems[previousSelectedItemIndex].updateValue(toSelected: false)
                collectionView.deselectItem(at: IndexPath(item: previousSelectedItemIndex, section: 0), animated: false)
            } else {
                toolbarItems[previousSelectedItemIndex].updateValue(toSelected: true)
                collectionView.selectItem(at: IndexPath(item: previousSelectedItemIndex, section: 0), animated: false, scrollPosition: .right)
                toolbarItems[indexPath.item].updateValue(toSelected: false)
                collectionView.deselectItem(at: indexPath, animated: false)
            }
        }
        
        delegate?.didRequestSwitchKeyboard(type: tappedID)
    }
}

extension SheetToolbar: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        toolbarItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SheetToolbarItemCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? SheetToolbarItemCell {
            cell.setupCell(with: toolbarItems[indexPath.item])
        }
        return cell
    }
}
