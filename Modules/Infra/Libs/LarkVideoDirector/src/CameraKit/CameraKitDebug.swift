//
//  CameraKitDebug.swift
//  LarkVideoDirector
//
//  Created by Saafo on 2023/7/11.
//

// disable-lint: magic_number

#if ALPHA
import AVKit
import Combine
import SwiftUI
import LarkMedia
import Foundation
import LarkStorage
import LarkContainer

@available(iOS 15, *)
public struct CameraKitConfigView: View {

    typealias Config = LarkCameraKit.CameraConfig

    @State private var cameraType: Config.CameraType = .automatic
    @State private var photoAction: Config.AfterTakePhotoAction = .enterImageEditor
    @State private var mediaType: Config.MediaType = .photoAndVideo
    @State private var autoSave: Bool = true
    @State private var position: AVCaptureDevice.Position = .unspecified
    @State private var videoMaxDuration: Int = 0

    @State private var image: UIImage?
    @State private var video: URL?
    @State private var message: String?
    @State private var presentResult: Bool = false


    @EnvironmentObject private var hostingProvider: ViewControllerProvider

    public init() {}

    public var body: some View {
        VStack {
            configList
            buttonView
        }
        .navigationTitle("CameraKit")
        .sheet(isPresented: $presentResult) {
            PreviewMediaView(image: $image, video: $video, message: $message)
        }
    }
    private var configList: some View {
        List {
            Picker(.init("\(Config.CameraType.self)"), selection: $cameraType) {
                ForEach(Config.CameraType.allCases) {
                    Text(verbatim: "\($0)")
                }
            }
            Picker(.init("\(Config.AfterTakePhotoAction.self)"), selection: $photoAction) {
                ForEach(Config.AfterTakePhotoAction.allCases) {
                    Text(verbatim: "\($0)")
                }
            }
            Picker(.init("\(Config.MediaType.self)"), selection: $mediaType) {
                ForEach(Config.MediaType.allCases) {
                    Text(verbatim: "\($0)")
                }
            }
            Toggle("AutoSave", isOn: $autoSave)
            Picker(.init("\(AVCaptureDevice.Position.self)"), selection: $position) {
                ForEach(AVCaptureDevice.Position.allCase) {
                    Text(verbatim: "\($0)")
                }
            }
            Stepper("videoMaxDuration \(videoMaxDuration)s", value: $videoMaxDuration, step: 10)
        }
    }
    private var buttonView: some View {
        HStack {
            Button("Open Camera", action: {
                openCamera()
            })
            .buttonStyle(.automatic)
            .tint(.blue)
        }
        .frame(height: 50, alignment: .center)
    }

    private func openCamera() {
        var config = LarkCameraKit.CameraConfig()
        config.cameraType = cameraType
        config.afterTakePhotoAction = photoAction
        config.mediaType = mediaType
        config.autoSave = autoSave
        config.cameraPosition = position
        config.videoMaxDuration = TimeInterval(videoMaxDuration)
        config.showDialogWhenCreatingFailed = true

        config.didCancel = { error in
            if let error {
                message = "\(error)"
            }
            self.presentResult = true
        }
        config.didTakePhoto = { image, vc, _, _ in
            vc.dismiss(animated: true) {
                self.image = image
                self.presentResult = true
            }
        }
        config.didRecordVideo = { video, vc, _, _ in
            vc.dismiss(animated: true) {
                self.video = video
                self.presentResult = true
            }
        }

        if let vc = hostingProvider.viewController {
            let userResolver = Container.shared.getCurrentUserResolver()
            LarkCameraKit.createCamera(with: config, from: vc, userResolver: userResolver) { [weak vc] result in
                switch result {
                case .success(let camera):
                    vc?.present(camera, animated: true)
                case .failure(let error):
                    if case .mediaOccupiedByOthers(let scene, let msg) = error {
                        message = "\(scene) \(msg ?? "")"
                    } else {
                        message = "\(error)"
                    }
                    presentResult = true
                }
            }
        }
    }
}

extension AVCaptureDevice.Position: Identifiable, CustomStringConvertible {
    static var allCase: [Self] { [.unspecified, .back, .front] }
    public var id: Self { self }
    public var description: String {
        switch self {
        case .unspecified: return "unspecified"
        case .back: return "back"
        case .front: return "front"
        @unknown default: return "unknown"
        }
    }
}

@available(iOS 15, *)
struct PreviewMediaView: View {
    @Binding var image: UIImage?
    @Binding var video: URL?
    @Binding var message: String?
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let video {
                VStack {
                    VideoPlayer(player: player)
                        .onAppear() {
                            let player = AVPlayer(url: video)
                            self.player = player
                            player.play()
                        }
                        .onDisappear() {
                            player?.pause()
                        }
                    Button {
                        guard let player else { return }
                        if player.timeControlStatus == .paused {
                            if let currentItem = player.currentItem,
                               player.currentTime().seconds >= currentItem.duration.seconds {
                                player.seek(to: .zero)
                            }
                            player.play()
                        } else {
                            player.pause()
                        }
                    } label: {
                        Image(systemName: "play")
                            .padding()
                    }
                }
            } else {
                Text(message ?? "No media available")
            }
        }
        .onDisappear() {
            image = nil
            if let video, let path = AbsPath(url: video), path.exists {
                try? path.notStrictly.removeItem()
            }
            video = nil
            message = nil
        }
    }
}

@available(iOS 13, *)
extension View {
    public func embeddedInHostingController() -> UIHostingController<some View> {
        let provider = ViewControllerProvider()
        let hostingAccessingView = environmentObject(provider)
        let hostingController = UIHostingController(rootView: hostingAccessingView)
        provider.viewController = hostingController
        return hostingController
    }
}

@available(iOS 13, *)
final public class ViewControllerProvider: ObservableObject {
    public fileprivate(set) weak var viewController: UIViewController?
}

//@available(iOS 15, *)
//struct MyPreviewProvider_Previews: PreviewProvider {
//    static var previews: some View {
//        CameraKitConfigView()
//        PreviewMediaView(image: .constant(nil), video: .constant(nil))
//    }
//}

#endif
