import UIKit
import ByteView
import SnapKit
import UniverseDesignToast

class StreamStatusListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var tableView: UITableView = .init(frame: .zero)
    var segmentCtl: UISegmentedControl!
    var streamStatus: [String] = []
    let streamManager: ParticipantGridStatusChecker

    init(streamManager: ParticipantGridStatusChecker) {
        self.streamManager = streamManager
        super.init(nibName: nil, bundle: nil)
        self.title = streamManager.meetingID
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = UIColor.systemBackground
        } else {
            self.view.backgroundColor = UIColor.white
        }
        self.tableView = UITableView(frame: .zero, style: .plain)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.dataSource = self
        self.tableView.delegate = self

        self.segmentCtl = UISegmentedControl(items: ["Visible Cells", "All Streams"])
        self.segmentCtl.selectedSegmentIndex = 0

        self.view.addSubview(segmentCtl)
        self.view.addSubview(tableView)

        segmentCtl.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(segmentCtl.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refresh))
        let copyBtn = UIButton(type: .system)
        copyBtn.addTarget(self, action: #selector(copyInfo), for: .touchUpInside)
        copyBtn.setTitle("复制", for: .normal)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: copyBtn)
        self.segmentCtl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.refresh()
    }

    @objc
    func copyInfo() {
        Utils.setPasteboardString(streamStatus.joined(separator: "\n"))
        UDToast.showTips(with: "保存至剪贴板", on: self.view, delay: 0.5)
    }

    @objc
    func refresh() {
        switch self.segmentCtl.selectedSegmentIndex {
        case 0:
            self.streamStatus = self.streamManager.checkVisibleCellsStatus().map(\.localizedDescription)
        case 1:
            self.streamStatus = self.streamManager.checkAllStreamStatus().map(\.localizedDescription)
        default:
            break
        }
        self.tableView.reloadData()
    }

    // MARK: - TableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.streamStatus.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = self.streamStatus[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let status = self.streamStatus[indexPath.row]
        Utils.setPasteboardString(status)
        UDToast.showTips(with: "拷贝至剪贴板", on: self.view, delay: 0.5)
    }
}
