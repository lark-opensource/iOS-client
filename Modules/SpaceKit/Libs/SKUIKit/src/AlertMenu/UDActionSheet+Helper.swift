//
//  UDActionSheet+Helper.swift
//  SKUIKit
//
//  Created by 曾浩泓 on 2021/6/25.
//  


import UniverseDesignActionPanel
import LarkTraitCollection
import RxSwift
import SKFoundation

public extension UDActionSheet {
    
    /// 创建一个 UDActionSheet 实例
    /// - Parameters:
    ///   - title: 标题
    ///   - popSource: 用于适配iPad。若指定该参数，则在iPad上将以Popover的形式展现
    ///   - dismissedByTapOutside: 点击外部区域dismiss时的回调
    /// - Returns: UDActionSheet 实例
    static func actionSheet(title: String? = nil, popSource: UDActionSheetSource? = nil, backgroundColor: UIColor? = nil,autoDissmissWhenChangeStatus: Bool = false, dismissedByTapOutside: (() -> Void)? = nil) -> UDActionSheet {
        let isShowTitle = title != nil
        let config: UDActionSheetUIConfig
        if let popSource = popSource {
            if let bg = backgroundColor {
                config = UDActionSheetUIConfig(isShowTitle: isShowTitle,
                                               backgroundColor: bg,
                                               popSource: popSource,
                                                   dismissedByTapOutside: dismissedByTapOutside)
            } else {
                config = UDActionSheetUIConfig(isShowTitle: isShowTitle,
                                               popSource: popSource,
                                                   dismissedByTapOutside: dismissedByTapOutside)
            }
            
        } else {
            if let bg = backgroundColor {
                config = UDActionSheetUIConfig(isShowTitle: isShowTitle,
                                               backgroundColor: bg,
                                                   dismissedByTapOutside: dismissedByTapOutside)
            } else {
                config = UDActionSheetUIConfig(isShowTitle: isShowTitle,
                                                   dismissedByTapOutside: dismissedByTapOutside)
            }
        }
        
        let actionSheet = RotatableActionSheet(config: config, autoDissmissWhenChangeStatus: autoDissmissWhenChangeStatus)
        if let title = title {
            actionSheet.setTitle(title)
        }
        return actionSheet
    }
    
    /// 添加一个item
    /// - Parameters:
    ///   - text: 文字
    ///   - textColor: 文字颜色
    ///   - style: 样式
    ///   - action: 回调
    func addItem(text: String,
                 textColor: UIColor? = nil,
                 style: UDActionSheetItem.Style = .default,
                 isEnable: Bool = true,
                 action: (() -> Void)? = nil) {
        let item = UDActionSheetItem(title: text,
                                     titleColor: textColor,
                                     style: style,
                                     isEnable: isEnable,
                                     action: action)
        self.addItem(item)
    }
}

class RotatableActionSheet: UDActionSheet {
    private var hasAppeared = false
    private let bag = DisposeBag()
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    override init(config: UDActionSheetUIConfig) {
        super.init(config: config)
    }
    
    /* autoDissmissWhenChangeStatus这个参数用来处理需要在旋转时隐藏 UDActionSheet
     Drive文件 More面板iPad下旋转会导致UDActionSheet位置错位，所以参考MoreViewConterV2处理方式隐藏，默认情况下不隐藏
    */
    convenience init(config: UDActionSheetUIConfig, autoDissmissWhenChangeStatus: Bool) {
        self.init(config: config)
        if autoDissmissWhenChangeStatus {
            NotificationCenter.default.addObserver(self, selector: #selector(willChangeStatusBarOrientation(_:)), name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if SKDisplay.pad && hasAppeared {
            dismiss(animated: true, completion: nil)
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // 监听sizeClass
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] change in
                if change.old != change.new || self?.modalPresentationStyle == .popover {
                    self?._dismissIfNeed()
                }
            }).disposed(by: bag)

    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppeared = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func willChangeStatusBarOrientation(_ notice: Notification) {
        _dismissIfNeed()
    }
    
    private func _dismissIfNeed() {
        if SKDisplay.pad {
            dismiss(animated: true, completion: nil)
        }
    }
}
