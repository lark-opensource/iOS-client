//
//  DemoViewController.swift
//  LarkRoomsWebView
//
//  Created by zhouyongnan on 2022/7/19.
//

import Foundation
import UIKit
import LarkTab
import LarkNavigation
import SnapKit
import PocketSVG
import RxCocoa
import RxSwift
import EENavigator
import LarkQRCode
import LarkRVC
import LarkAccountInterface
import LarkContainer

class DemoViewController: UIViewController {

    override
    func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.yellow
        addTestBtns()
    }

    override
    func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    func addTestBtns() {

        let btn = addBtn(title: "打开RVC页面")
        btn.addTarget(self, action: #selector(openRVCPage), for: .touchUpInside)

        let btn2 = addBtn(title: "打开白板页面")
        btn2.addTarget(self, action: #selector(openWhiteBoardPage), for: .touchUpInside)

        let btn3 = addBtn(title: "展示toast")
        btn3.addTarget(self, action: #selector(showPhotoSentToast), for: .touchUpInside)


        let btn4 = addBtn(title: "打开扫码页面")
        btn4.addTarget(self, action: #selector(openScanPage), for: .touchUpInside)

        let btn5 = addBtn(title: "打开飞书控制会议室页面")
        btn5.addTarget(self, action: #selector(openLRVCPage), for: .touchUpInside)

    }

    private var btnList: [UIButton] = []
    func addBtn(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        view.addSubview(btn)
        btn.snp.makeConstraints { make in
            if (btnList.isEmpty) {
                make.top.equalTo(100)
            } else {
                make.top.equalTo(btnList.last!.snp.bottom)
            }
            make.left.equalTo(100)
            make.width.equalTo(200)
            make.height.equalTo(40)
        }
        btnList.append(btn)
        return btn
    }

    @objc
    func showPhotoSentToast() {
        LarkRoomWebViewManager.showImageSentToast()
    }

    @objc
    func openScanPage() {
        let body = QRCodeControllerBody()
        Navigator.shared.push(body: body, from: self)
    }

    // roomid: 6992111907842899970 meetingId: 7166853490626674690
    @objc
    func openLRVCPage() {

        let body = LRVCWebContainerBody(roomId: "6992111907842899970", meetingId: "7166853490626674690")
        Navigator.shared.push(body: body, from: self)
    }

    @objc
    func openRVCPage() {
//        Navigator.shared.push(URL(string: "https://internal-api.feishu-pre.cn/view/room_bind/rvc/scan?token=b9c4f5ea-d2e2-4c7f-ae95-e4ce70d20f6e")!, from: self)
        @Injected var passportService: PassportService // Global
        let vc = LarkRoomWebViewManager.createLarkRoomWebViewVC(url: URL(string: "https://internal-api.feishu-pre.cn/view/room_bind/rvc/scan?token=b9c4f5ea-d2e2-4c7f-ae95-e4ce70d20f6e")!,
                                                                userId: passportService.foregroundUser?.userID ?? "")
//        navigationController?.pushViewController(vc, animated: true)
        vc.closePageCallBack = { [weak self] (rvc) in
//            self?.navigationController?.popViewController(animated: true)
            self?.navigationController?.dismiss(animated: true)
        }
        vc.modalPresentationStyle = .fullScreen
        navigationController?.present(vc, animated: true, completion: nil)

    }

    @objc
    func openWhiteBoardPage() {
        Navigator.shared.push(URL(string:
        "https://room.feishu-pre.cn/view/room_bind/whiteboard/save?token=b4958e2bfb19aa3121ab37d1381de118&whiteboard_id=7123811002323353602")!, from: self)
    }

    @objc
    func openBindPage() {
        Navigator.shared.push(URL(string:
        "https://internal-api.feishu-pre.cn/view/room_bind/scan/bind/index?device_token=23ce034a-7e3a-4fd6-85c8-0b2a2fed7a97")!, from: self)
    }
}
