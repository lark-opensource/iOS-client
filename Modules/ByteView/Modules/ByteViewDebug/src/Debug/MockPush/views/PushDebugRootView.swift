import SwiftUI
import UIKit
import ByteViewNetwork
import ByteView
import LarkStorage

func log(_ v: String) {
    print("[RecordReplay]", v)
}

struct ShareFileItem: Identifiable {
    var id: String {
        path
    }
    var path: String
}

@available(iOS 14.0, *)
struct PushDebugRootView: View {
    @EnvironmentObject
    var toastState: ToastState

    @State
    var presentMockParticipant = false

    @State
    var presentMockWebinarAttendee = false

    @State
    var presentMockWebinarPanelList = false

    @State
    var recordPath: ShareFileItem?

    @State
    var isDisplayingReplayList: Bool = false

    @State
    var isDisplayingShareReplayList: Bool = false

    var body: some View {
        ToastContainer {
            NavigationView {
                List {
                    Section {
                        Button("开始参会人变更推送") {
                            presentMockParticipant = true
                        }
                        Button("停止参会人变更推送") {
                            toastState.showToast("Stop ParticipantChange Mock", duration: .seconds(2))
                            PushDebug.shared.stopMockParticipantChanges()
                        }
                    }

                    Section {
                        Button("开始 Webinar 观众变更推送") {
                            presentMockWebinarAttendee = true
                        }
                        Button("停止 Webinar观众 变更推送") {
                            toastState.showToast("Stop WebinarAttendeeChange Mock", duration: .seconds(2))
                            PushDebug.shared.stopMockWebinarAttendeeChanges()
                        }

                    }

                    Section {
                        Button("开始 Webinar PanelList(观众视角) 变更推送") {
                            presentMockWebinarPanelList = true
                        }
                        Button("停止 Webinar PanelList(观众视角) 变更推送") {
                            toastState.showToast("Stop WebinarAttendeePanelList Mock", duration: .seconds(2))
                            PushDebug.shared.stopMockWebinarPanelListChanges()
                        }

                    }

                    Section {
                        Button("开始录制会中推送") {
                            toastState.showToast("Start Recording", duration: .seconds(2))
                            PushDebug.shared.startRecordPush()
                        }
                        Button("停止录制会中推送") {
                            toastState.showToast("Stop Recording", duration: .seconds(2))
                            PushDebug.shared.stopRecordPush()
                        }
                    }
                    Section {
                        NavigationLink("回放会中推送", isActive: $isDisplayingReplayList) {
                            ReplayListView { record in
                                do {
                                    try PushDebug.shared.replayRecord(record)
                                    toastState.showToast("start replay")
                                } catch {
                                    toastState.showToast("start replay failed, \(error)", duration: .seconds(3))
                                }
                            }
                        }

                        NavigationLink("分享推送记录", isActive: $isDisplayingShareReplayList) {
                            ReplayListView { record in
                                self.recordPath = ShareFileItem(path: record.absoluteString)
                            }
                            .sheet(item: $recordPath) { item in
                                ActivityShareView(url: URL(fileURLWithPath: item.path))
                            }
                        }

                        Button("停止回放会中推送") {
                            toastState.showToast("Stop Replaying")
                            PushDebug.shared.stopReplayRecord()
                        }
                    }
                }
            }
            .navigationViewStyle(.stack)
            .sheet(isPresented: $presentMockWebinarAttendee) {
                MockParticipantView(maxParticipantCount: 500) { pushIntervalMS, maxCount, upsertCount, removeCount in
                    do {
                        try PushDebug.shared.mockWebinarAttendeeChanges(intervalMS: pushIntervalMS,
                                                                        maxCount: maxCount,
                                                                        upsertCount: upsertCount,
                                                                        removeCount: removeCount)
                        toastState.showToast("Mock WebinarAttendeeChange", duration: .seconds(2))
                    } catch {
                        toastState.showToast("Mock WebinarAttendeeChange failed \(error)", duration: .seconds(3))
                    }
                } dismissAction: {
                    presentMockWebinarAttendee = false
                }

            }
            .sheet(isPresented: $presentMockWebinarPanelList) {
                MockParticipantView(maxParticipantCount: 1000) { pushIntervalMS, maxCount, upsertCount, removeCount in
                    do {
                        try PushDebug.shared.mockWebinarPanelListChanges(intervalMS: pushIntervalMS,
                                                                        maxCount: maxCount,
                                                                        upsertCount: upsertCount,
                                                                        removeCount: removeCount)
                        toastState.showToast("Mock WebinarPanelListChange", duration: .seconds(2))
                    } catch {
                        toastState.showToast("Mock WebinarPanelListChange failed \(error)", duration: .seconds(3))
                    }
                } dismissAction: {
                    presentMockWebinarPanelList = false
                }
            }
            .sheet(isPresented: $presentMockParticipant) {
                MockParticipantView { pushIntervalMS, maxCount, upsertCount, removeCount in
                    do {
                        try PushDebug.shared.mockPartricipantChanges(intervalMS: pushIntervalMS,
                                                                     maxCount: maxCount,
                                                                     upsertCount: upsertCount,
                                                                     removeCount: removeCount)
                        toastState.showToast("Mock ParticipantChange", duration: .seconds(2))
                    } catch {
                        toastState.showToast("Mock ParticipantChange failed \(error)", duration: .seconds(3))
                    }
                } dismissAction: {
                    presentMockParticipant = false
                }

            }
        }
    }
}

@available(iOS 14.0, *)
struct RecordReplayView_Preview: PreviewProvider {
    static var previews: some View {
        PushDebugRootView()
    }
}

@available(iOS 14.0, *)
struct ActivityShareView: UIViewControllerRepresentable {
    let url: URL
    init(url: URL) {
        self.url = url
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }

}
