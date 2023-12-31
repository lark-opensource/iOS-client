//
//  ParticipantGridDebugTool.swift
//  ByteViewDebug
//
//  Created by liujianlong on 2021/12/31.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//
import UIKit
import UniverseDesignToast
import ByteView
import ByteViewRtcBridge

// suppress diagnostic debug_description_in_string_interpolation_segment
extension String.StringInterpolation {
    mutating func appendInterpolation<T>(_ val: T?) {
        if let noNil = val {
            appendInterpolation(noNil)
        } else {
            appendInterpolation("<nil>")
        }
    }
}

extension String {
    func indent(by indention: String) -> String {
        self.split(separator: "\n")
            .map { indention + $0 }
            .joined(separator: "\n")
    }
}

extension StreamStatus {
    var localizedDescription: String {
        let streamKeyDesc: String
        if self.streamKey.isLocal {
            streamKeyDesc = "本地相机流"
        } else if self.streamKey.isScreen {
            streamKeyDesc = "共享屏幕流(\(self.streamKey.uid))"
        } else {
            streamKeyDesc = "视频流(\(self.streamKey.uid))"
        }
        let details = [
            "视频流类型: \(streamKeyDesc)",
            "视频流ID: \(self.streamID)",
            "OnStreamAdd 是否回调: \(self.streamAdded)",
            "渲染视图是否存在: \(self.hasRenderer)",
            "Muted: \(self.muted)",
            "\(self.lastSDKCall)"
        ].joined(separator: "\n")

        return details
    }
}

extension ParticipantGridDiagnosticInfo {
    var localizedDescription: String {
        let streamDesc = self.streamStatus?.localizedDescription.indent(by: "\t")
        let details = [
            "IndexPath: \(self.indexPath)",
            "参会人ID: \(self.participantID?.pid)",
            "rtcJoinID: \(self.rtcJoinID)",
            "viewSize: \(self.viewSize.width)x\(self.viewSize.height) * \(UIScreen.main.scale)",
            "头像可见: \(!self.isAvatarHidden)",
            "cell 可见: \(self.isCellVisible)",
            "相机开启: \(self.isCamMuted.map({ !$0 }))",
            "麦克风开启: \(self.isMicrophoneMuted.map({ !$0 }))",
            "正在渲染: \(self.isRendering)",
            "视频流状态:\n\(streamDesc)"
        ]

        return details.joined(separator: "\n")
    }
}

class ParticipantGridDebugTool: NSObject, ParticipantGridDebugToolProtocol, UIGestureRecognizerDelegate {
    var collectionView: UICollectionView?
    var statusChecker: ParticipantGridStatusChecker?
    var tripleTapGest: UIGestureRecognizer?
    var quadrupleTapGest: UIGestureRecognizer?
    func setup(collectionView: UICollectionView, statusChecker: ParticipantGridStatusChecker) {
        self.collectionView = collectionView
        self.statusChecker = statusChecker
        let gest = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap(gest:)))
        gest.numberOfTapsRequired = 3
        gest.numberOfTouchesRequired = 2
        collectionView.addGestureRecognizer(gest)
        self.tripleTapGest = gest

        let gest2 = UITapGestureRecognizer(target: self, action: #selector(handleQuadriTap(gest:)))
        gest2.numberOfTapsRequired = 4
        gest2.numberOfTouchesRequired = 2
        collectionView.addGestureRecognizer(gest2)
        self.quadrupleTapGest = gest2
        self.quadrupleTapGest?.delegate = self

        gest.require(toFail: gest2)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === self.quadrupleTapGest {
            return true
        }
        return false
    }

    @objc
    private func handleQuadriTap(gest: UITapGestureRecognizer) {
        guard let statusChecker = self.statusChecker else {
            return
        }

        let vc = UINavigationController(rootViewController: StreamStatusListVC(streamManager: statusChecker))
        vc.modalPresentationStyle = .formSheet
        UIApplication.shared.keyWindow?.rootViewController?.present(vc, animated: true, completion: nil)
    }

    @objc
    private func handleTripleTap(gest: UITapGestureRecognizer) {
        guard let collectionView = self.collectionView,
              let statusChecker = self.statusChecker else {
            return
        }

        let pos = gest.location(in: collectionView)
        for cell in collectionView.visibleCells {
            if cell.convert(cell.bounds, to: self.collectionView).contains(pos),
               let status = statusChecker.checkCellStatus(cell) {
                var desc = status.localizedDescription
                if let streamStatus = status.streamStatus {
                    if !status.isRendering {
                        if streamStatus.isOK {
                            desc += "\n\n已订阅，无首帧"
                        } else if status.isCamMuted != streamStatus.muted {
                            desc += "\n\nRTC 相机开关状态不一致"
                        } else if !streamStatus.streamAdded {
                            desc += "\n\nonStreamAdd 未回调"
                        } else if !streamStatus.hasRenderer {
                            desc += "\n\n未订阅"
                        }
                    }
                }
                Utils.setPasteboardString(desc)

                if let window = UIApplication.shared.keyWindow {
                    UDToast.showTips(with: "拷贝参会人订阅渲染信息", on: window, delay: 0.5)
                }
            }
        }
    }

    func destroy() {
        self.collectionView = nil
        self.statusChecker = nil
    }
}
