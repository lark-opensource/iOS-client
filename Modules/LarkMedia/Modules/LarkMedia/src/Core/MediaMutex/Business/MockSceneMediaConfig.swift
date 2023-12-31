//
//  MockSceneMediaConfig.swift
//  LarkMedia
//
//  Created by fakegourmet on 2022/11/15.
//

class VCMeetingMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .vcMeeting,
                  mediaConfig: [.record: .high, .play: .high])
    }
}

class VCRingMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .vcRing,
                  mediaConfig: [.play: .high])
    }
}

class VCRingtoneAuditionMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .vcRingtoneAudition,
                  mediaConfig: [.play: .low])
    }
}

class UltraWaveMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .ultrawave,
                  mediaConfig: [.record: .high])
    }
}

class VoIPMeetingMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .voip,
                  mediaConfig: [.record: .high, .play: .high])
    }
}

class VoIPRingMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .voipRing,
                  mediaConfig: [.play: .high])
    }
}

class MMRecordMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .mmRecord,
                  mediaConfig: [.record: .medium])
    }
}

class MMPlayMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .mmPlay,
                  mediaConfig: [.play: .default])
    }
}

class IMRecordMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .imRecord,
                  mediaConfig: [.record: .default])
    }
}

class IMPlayMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .imPlay,
                  mediaConfig: [.play: .default])
    }
}

class IMVideoPlayMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .imVideoPlay,
                  mediaConfig: [.play: .default])
    }
}

class IMCameraMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .imCamera,
                  mediaConfig: [.camera: .default])
    }
}

class MicroPlayMediaConfig: SceneMediaConfig {
    convenience init(id: String = "") {
        self.init(scene: .microPlay(id: id),
                  mediaConfig: [.play: .default, .record: .low])
    }
}

class MicroRecordMediaConfig: SceneMediaConfig {
    convenience init(id: String = "") {
        self.init(scene: .microRecord(id: id),
                  mediaConfig: [.record: .default])
    }
}

class CCMRecordMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .ccmRecord,
                  mediaConfig: [.record: .default])
    }
}

class CCMPlayMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .ccmPlay,
                  mediaConfig: [.play: .high])
    }
}

final class CommonCameraMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .commonCamera,
                  mediaConfig: [.camera: .default])
    }
}

final class CommonVideoRecordMediaConfig: SceneMediaConfig {
    convenience init() {
        self.init(scene: .commonVideoRecord,
                  mediaConfig: [.camera: .default, .record: .default])
    }
}
