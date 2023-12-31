//
//  InsertColorPickerViewController.swift
//  SKBrowser
//
//  Created by zoujie on 2020/11/23.
//  


import SKFoundation
import SKCommon
import SnapKit
import SKUIKit
import UniverseDesignColor
import SKResource

public protocol InsertColorPickerDelegate: AnyObject {
    func didSelectBlock(id: String)
    func noticeWebScrollUpHeight(height: CGFloat)
}

public final class InsertColorPickerViewController: UIViewController {
    weak var colorPickPanel: ColorPickerPanelV2?
    public weak var delegate: InsertColorPickerDelegate?
    private lazy var uiConstant = ColorPickerUIConstant(hostView: view)
    
    struct Layout {
        static var contentWidth: CGFloat = 375
        static var contentHeight: CGFloat = 389
        static var panelHeight: CGFloat = 340
    }

    private var containerView: UIScrollView = {
        let view = UIScrollView(frame: .zero)
        view.showsVerticalScrollIndicator = false
        return view
    }()
    
    var titleLabel: UILabel = {
       let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.text = BundleI18n.SKResource.Doc_Doc_ColorSelectTitle
       return label
    }()
    
    var seperatorView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
       return view
    }()
    
    public init(colorPickPanel: ColorPickerPanelV2) {
        colorPickPanel.isNewShowingMode = true
        self.colorPickPanel = colorPickPanel
        self.colorPickPanel?.backgroundColor = .clear
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupContentView()
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        colorPickPanel?.uiConstant = uiConstant
    }

    private func setupContentView() {
        guard let colorPickView = colorPickPanel else { return }
        view.addSubview(containerView)
        view.addSubview(titleLabel)
        view.addSubview(seperatorView)
        containerView.addSubview(colorPickView)
        view.layer.ud.setBackgroundColor(UDColor.bgBody)
        preferredContentSize = CGSize(width: Layout.contentWidth, height: Layout.contentHeight)
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(seperatorView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(14)
        }
        
        seperatorView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.height.equalTo(0.5)
        }
        
        colorPickView.snp.makeConstraints { (make) in
            make.top.left.right.width.bottom.equalToSuperview()
            make.height.equalTo(Layout.panelHeight)
        }
        colorPickView.uiConstant = uiConstant
        colorPickView.isHidden = false
        containerView.contentSize = CGSize(width: 0, height: Layout.panelHeight)
        DispatchQueue.main.async {
            colorPickView.refreshViewLayout()
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        noticeWebviewToScrollUp()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.didSelectBlock(id: "close")
    }

    func noticeWebviewToScrollUp() {
        guard colorPickPanel != nil else { return }
        // 根据投影计算实际 webview 需要上移的高度
        delegate?.noticeWebScrollUpHeight(height: Layout.contentHeight)
    }
}
