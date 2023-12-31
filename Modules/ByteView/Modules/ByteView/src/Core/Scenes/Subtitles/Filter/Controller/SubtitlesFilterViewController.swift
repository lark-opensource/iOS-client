//
//  SubtitlesFilterViewController.swift
//  ByteView
//
//  Created by 夏汝震 on 2020/4/16.
//

import RxSwift
import SnapKit
import RxCocoa
import ByteViewUI
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import UniverseDesignIcon

// MARK: - 筛选控制器 用于历史字幕页面 -> 筛选
final class SubtitlesFilterViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {

    struct Layout {
        static let rowHeight: CGFloat = 64.0
        static let popoverWidth: CGFloat = 310.0
    }

    var isIPadLayout: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    /// 人员表视图
    lazy var tableView: SubtitlesFilterTableView = {
        let tableView = SubtitlesFilterTableView()
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()

    lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = I18n.View_G_NoOneTalkNow
        label.isHidden = true
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    var padRegularStyle: Bool {
        return traitCollection.userInterfaceIdiom == .pad && VCScene.rootTraitCollection?.horizontalSizeClass == .regular
    }

    private let viewModel: FilterViewModel

    init(viewModel: FilterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setupNavTitleAndLeftButton()
        let item = UIBarButtonItem(
            title: I18n.View_G_Clear,
            style: .plain,
            target: self,
            action: nil
        )
        item.tintColor = padRegularStyle ? UIColor.ud.primaryContentDefault : UIColor.ud.textDisabled
        navigationItem.rightBarButtonItem = item
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //  支持横竖屏
    override var shouldAutorotate: Bool {
        return Display.phone ? false : true
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Display.phone ? .portrait : .allButUpsideDown
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        dataProduce()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // NavigationController会在viewWillAppear设置navigationBar的背景色，因此要在这里再次设为nil
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if oldContext.layoutType != newContext.layoutType {
            setupNavTitleAndLeftButton()
        }
    }

    func setupNavTitleAndLeftButton() {
        if padRegularStyle {
            title = ""
            let label = UILabel()
            label.text = I18n.View_G_FilterByParticipant
            label.textColor = UIColor.ud.textTitle
            label.font = .boldSystemFont(ofSize: 17)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: label)
        } else {
            title = I18n.View_G_FilterByParticipant
            let closeButton = UIButton()
            closeButton.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
            closeButton.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN3, size: CGSize(width: 24, height: 24)), for: .highlighted)
            closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
            closeButton.addInteraction(type: .highlight, shape: .roundedRect(CGSize(width: 44, height: 36), 8.0))
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
        }
    }

    @objc func close() {
        doBack()
    }

    /// 添加子视图 布局
    private func setupViews() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        isIPadLayout.subscribe(onNext: { [weak self] _ in
            let backgroundColor: UIColor = Display.pad ? UIColor.ud.bgFloat : UIColor.ud.bgBody
            self?.view.backgroundColor = backgroundColor
            self?.setNavigationBarBgColor(backgroundColor)
        }).disposed(by: rx.disposeBag)

        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        // 默认会有一个比较大的size，数据更新后size缩小，可能会导致视觉上比较明显的闪动，因此先在didLoad里设置一个比较小的size
        updatePopoverHeight(numbersOfRow: 0)
    }
    /// 初始化数据
    private func dataProduce() {
        //  拉去参会人基本数据
        viewModel.fetchParticipantList { [weak self] in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                let count = self.viewModel.avatarInfoAndNameArray.count
                self.emptyLabel.isHidden = (count > 0)
                self.updatePopoverHeight(numbersOfRow: count > 0 ? count : 1)
                self.dataProduceComplateAction(isSuccess: true)
            }

        } failure: { [weak self] in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.dataProduceComplateAction(isSuccess: false)
            }
        }

    }

    // 手动更新popover的高度，高度等于navigatorbar+tableview
    private func updatePopoverHeight(numbersOfRow: Int) {
        let height = CGFloat(numbersOfRow) * Layout.rowHeight
        self.updateDynamicModalSize(CGSize(width: Layout.popoverWidth, height: height))
    }

    /// 数据流程成功或者失败的action
    private func dataProduceComplateAction(isSuccess: Bool) {
        assert(Thread.isMainThread, "please call this method in main thread")
        if isSuccess {
            switch viewModel.state {
            case .none:
                navigationItem.rightBarButtonItem?.action = nil
                navigationItem.rightBarButtonItem?.tintColor = UIColor.ud.textDisabled
            case .filterPeople:
                navigationItem.rightBarButtonItem?.action = #selector(clearFilter)
                navigationItem.rightBarButtonItem?.tintColor = UIColor.ud.primaryContentDefault
            }
        } else {
            //  失败
            navigationItem.rightBarButtonItem?.action = nil
            navigationItem.rightBarButtonItem?.tintColor = UIColor.ud.textDisabled
        }
        tableView.reloadData()
    }

    /// 清除筛选
    @objc
    private func clearFilter() {
        VCTracker.post(name: .vc_meeting_transcribe_click, params: ["click": "delete_filter", "location": "clear"])
        VCTracker.post(name: .vc_meeting_subtitle_page, params: [.action_name: "filter_clear"])
        viewModel.clear()
        if Display.pad {
            self.presentingViewController?.dismiss(animated: false, completion: nil)
        } else {
            //  退出页面
            self.doBack()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Layout.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.filter(withIndex: indexPath.row) {
            if Display.pad {
                self.presentingViewController?.dismiss(animated: false, completion: nil)
            } else {
                //  退出页面
                self.doBack()
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.avatarInfoAndNameArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SubtitlesFilterTableViewCell.cellIdentifier,
            for: indexPath
        )
        cell.selectedBackgroundView = {
            let view = UIView()
            view.backgroundColor = UIColor.ud.textTitle.withAlphaComponent(0.05)
            return view
        }()
        if let view = cell as? SubtitlesFilterTableViewCell {
            let info = viewModel.avatarInfoAndNameArray[indexPath.row]
            switch viewModel.state {
            case .none:
                view.updateCell(with: info.0, name: info.1, pid: info.2)
            case .filterPeople(let people):
                    let user = viewModel.byteviewUserArray[indexPath.row]
                if user.id == people.id {
                    //  如果是选择了筛选人，被筛选的那个需要高亮打勾
                    view.updateCell(with: info.0, name: info.1, pid: info.2, isFilter: true)
                } else {
                    view.updateCell(with: info.0, name: info.1, pid: info.2)
                }
            }
        }
        return cell
    }

}
// MARK: - 字幕筛选工具View
/// 表视图
class SubtitlesFilterTableView: BaseTableView {
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        backgroundColor = .clear
        estimatedRowHeight = UITableView.automaticDimension
        rowHeight = UITableView.automaticDimension
        register(SubtitlesFilterTableViewCell.self, forCellReuseIdentifier: SubtitlesFilterTableViewCell.cellIdentifier)
        separatorColor = .clear
        separatorStyle = .none
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
/// 表视图Cell
class SubtitlesFilterTableViewCell: UITableViewCell {
    static let cellIdentifier = "SubtitlesFilterTableViewCellIdentifier"
    /// 头像视图
    private lazy var avatarView = AvatarView()
    /// 人名标签
    private lazy var nameLabel: UILabel = {
        var label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.font = UIFont.systemFont(ofSize: 17.0)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var conveniencePSTNIcon: UIImageView = {
        return UIImageView(image: UDIcon.getIconByKey(.officephoneFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: 20.0, height: 20.0)))
    }()

    private lazy var doneIcon: UIImageView = {
        let image = UDIcon.getIconByKey(.doneOutlined, iconColor: .ud.primaryContentDefault, size: CGSize(width: 20, height: 20))
        return UIImageView(image: image)
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupViews()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /// 添加子视图 布局
    private func setupViews() {
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(conveniencePSTNIcon)
        contentView.addSubview(doneIcon)
        avatarView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.height.width.equalTo(40)
        }

        doneIcon.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(20)
        }
        doneIcon.isHidden = true

        conveniencePSTNIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(doneIcon.snp.left).offset(-16)
            make.height.equalTo(20)
            make.width.equalTo(20)
        }
        conveniencePSTNIcon.isHidden = true

        nameLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.right.equalTo(conveniencePSTNIcon.snp.left).offset(-4)
        }
    }
    /// 配置cell
    /// - Parameters:
    ///   - avatarInfo: 头像信息
    ///   - name: 名字
    ///   - isFilter: 是否是选中的筛选状态
    func updateCell(with avatarInfo: AvatarInfo,
                    name: String,
                    pid: ParticipantId?,
                    isFilter: Bool = false) {
        avatarView.setTinyAvatar(avatarInfo)
        nameLabel.text = name
        if  let pid = pid, let bindInfo = pid.bindInfo, bindInfo.id.isEmpty == false, bindInfo.type == .lark {
            conveniencePSTNIcon.isHidden = false
        } else {
            conveniencePSTNIcon.isHidden = true
        }
        changeFilter(isFilter: isFilter)
    }
    /// 按照是否筛选改变样式
    /// - Parameter isFilter: 是否筛选
    func changeFilter(isFilter: Bool) {
        if isFilter {
            nameLabel.textColor = UIColor.ud.primaryContentDefault
            //  显示打勾图片
            doneIcon.isHidden = false
        } else {
            nameLabel.textColor = UIColor.ud.textTitle
            //  不显示打勾图片
            doneIcon.isHidden = true
        }
    }
}
