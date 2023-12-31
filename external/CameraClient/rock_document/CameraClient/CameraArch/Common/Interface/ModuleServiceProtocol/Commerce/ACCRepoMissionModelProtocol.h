//
//  ACCRepoMissionModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/9/21.
//

#ifndef ACCRepoMissionModelProtocol_h
#define ACCRepoMissionModelProtocol_h

@protocol ACCTaskModelProtocol;
@protocol ACCRepoMissionModelProtocol <NSObject>

- (id<ACCTaskModelProtocol>)acc_mission;

- (NSString *)acc_missionName;

- (NSString *)acc_missionID;

- (NSString *)acc_missionFrom;

- (BOOL)acc_isAssignmentMission;

- (BOOL)acc_excludeCustomStickerEntrance;

- (BOOL)acc_isRecordLiveMission;

- (NSDictionary *)acc_selectedMissionInfo;

- (BOOL)shouldShowMissionItem;

- (void)updateMissionID:(NSString *)missionID
            missionType:(NSString *)missionType
            missionName:(NSString *)missionName
    isAssignmentMission:(BOOL)isAssignmentMission
    selectedMissionInfo:(NSDictionary *)selectedMissionInfo;

@end

#endif /* ACCRepoMissionModelProtocol_h */
