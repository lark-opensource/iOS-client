//
//  SheetBrowserTopContainer.swift
//  SKBrowser
//  


import Foundation
import SnapKit
import RxSwift
import SKFoundation
import SKUIKit
import SKBrowser

public typealias BrowserTopBarTransition = (hidden: Bool, animated: Bool)

public final class SheetBrowserTopContainer: BrowserTopContainer {

    weak var sheetDelegate: SheetBrowserTopContainerDelegate?

    let disposeBag = DisposeBag()

    public lazy var tabSwitcher = SheetTabSwitcherView(frame: .zero).construct { it in
        it.isHidden = true
    }
    
    public var tabSwitcherTransitioner = PublishSubject<BrowserTopBarTransition>()
    
    var showTabSwitcherConstraint: Constraint?
    var hideTabSwitcherConstraint: Constraint?

    public override var preferredHeight: CGFloat {
        var height: CGFloat = super.preferredHeight
        height += tabSwitcher.isHidden ? 0.0 : SheetTabSwitcherView.preferredHeight
        return height
    }

    public required init(navBar: SKNavigationBar) {
        super.init(navBar: navBar)
        tabSwitcherTransitioner
            .distinctUntilChanged { $0.hidden == $1.hidden }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (hidden, animated) in
                guard let self = self else {
                    DocsLogger.info("Browser's topContainer is nil, failed to transition tab switcher")
                    return
                }
                self.setTabSwitcherHidden(hidden, animated: animated)
            })
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func setup() {
        setupSubviews()
        sheetDelegate?.topContainerDidUpdateSubviews()
    }

    public override func setupSubviews() {
        super.setupSubviews()
        insertSubview(tabSwitcher, belowSubview: navBar)
        updateLayout()
    }

    public override func updateSubviewsContraints() {
        sheetDelegate?.topContainerDidUpdateSubviews()
    }

    /// Change the alpha of the tab switcher and remove if needed.
    private func setTabSwitcherHidden(_ hidden: Bool, animated: Bool) {
        guard tabSwitcher.isHidden != hidden, tabSwitcher.superview != nil else { return }

        if tabSwitcher.isHidden {
            // Tab switcher will appear
            tabSwitcher.alpha = 0.0
            tabSwitcher.isHidden = false
            updateLayout()
            animateIfNeeded(animated, animation: { [self] in
                tabSwitcher.alpha = 1.0
                self.layoutIfNeeded()
                sheetDelegate?.topContainerDidUpdateTabSwitcherViewAppearance(true)
            })
        } else {
            // Tab switcher will disappear
            updateLayout()
            animateIfNeeded(animated, animation: { [self] in
                tabSwitcher.alpha = 0.0
                self.layoutIfNeeded()
                sheetDelegate?.topContainerDidUpdateTabSwitcherViewAppearance(false)
            }, completion: { [self] _ -> Void in
                tabSwitcher.isHidden = true
                updateLayout()
            })
        }
    }
    
    public override func updateLayout() {
        guard banners.superview != nil, tabSwitcher.superview != nil, catalogueContainer.superview != nil else {
            return
        }
        banners.snp.remakeConstraints { it in
            it.top.equalTo(navBar.snp.bottom)
            it.leading.trailing.equalToSuperview()
            it.height.equalTo(banners.isHidden ? 0 : banners.preferedHeight)
            if catalogueContainer.isHidden, tabSwitcher.isHidden {
                it.bottom.equalToSuperview()
            }
        }
        tabSwitcher.snp.remakeConstraints { it in
            if banners.isHidden {
                it.top.equalTo(navBar.snp.bottom)
            } else {
                it.top.equalTo(banners.snp.bottom)
            }
            it.leading.trailing.equalToSuperview()
            it.height.equalTo(SheetTabSwitcherView.preferredHeight)
            if !tabSwitcher.isHidden, catalogueContainer.isHidden {
                it.bottom.equalToSuperview()
            }
        }
        catalogueContainer.snp.remakeConstraints { it in
            if banners.isHidden, tabSwitcher.isHidden {
                it.top.equalTo(navBar.snp.bottom)
            } else if !banners.isHidden, tabSwitcher.isHidden {
                it.top.equalTo(banners.snp.bottom)
            } else if banners.isHidden, !tabSwitcher.isHidden {
                it.top.equalTo(tabSwitcher.snp.bottom)
            } else {
                it.top.equalTo(tabSwitcher.snp.bottom)
            }
            it.left.right.equalToSuperview()
            it.height.equalTo(catalogueContainer.isHidden ? 0 : catalogueContainer.preferedHeight)
            if !catalogueContainer.isHidden {
                it.bottom.equalToSuperview()
            }
        }
    }
}

extension SheetBrowserTopContainer {
    /// 设置允许被截图
    func setCaptureAllowed(_ allow: Bool) {
        tabSwitcher.setCaptureAllowed(allow)
    }
}
