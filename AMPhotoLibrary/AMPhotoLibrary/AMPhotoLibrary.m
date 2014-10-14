//
//  AMPhotoLibrary.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoLibrary.h"
#import "AMALAssetsLibrary.h"
#import "AMPHPhotoLibrary.h"

@interface AMPhotoLibrary ()
{
    id<AMPhotoManager> _photoManager;
}
@end

@implementation AMPhotoLibrary

static AMPhotoLibrary *s_sharedPhotoLibrary = nil;
+ (instancetype)sharedPhotoLibrary
{    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_sharedPhotoLibrary = [AMPhotoLibrary new];
    });
    return s_sharedPhotoLibrary;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            _photoManager = [AMPHPhotoLibrary sharedPhotoManager];
        }
        else {
            _photoManager = [AMALAssetsLibrary sharedPhotoManager];
        }
    }
    return self;
}

+ (AMAuthorizationStatus)authorizationStatusFromALAuthorizationStatus:(ALAuthorizationStatus)authorizationStatus
{
    AMAuthorizationStatus authStatus = AMAuthorizationStatusNotDetermined;
    switch (authorizationStatus) {
        case ALAuthorizationStatusRestricted:
            authStatus = AMAuthorizationStatusRestricted;
            break;
        case ALAuthorizationStatusDenied:
            authStatus = AMAuthorizationStatusDenied;
            break;
        case ALAuthorizationStatusAuthorized:
            authStatus = AMAuthorizationStatusAuthorized;
            break;
        case ALAuthorizationStatusNotDetermined:
        default:
            authStatus = AMAuthorizationStatusNotDetermined;
            break;
    }
    return authStatus;
}

+ (AMAuthorizationStatus)authorizationStatusFromPHAuthorizationStatus:(PHAuthorizationStatus)authorizationStatus
{
    AMAuthorizationStatus authStatus = AMAuthorizationStatusNotDetermined;
    switch (authorizationStatus) {
        case PHAuthorizationStatusRestricted:
            authStatus = AMAuthorizationStatusRestricted;
            break;
        case PHAuthorizationStatusDenied:
            authStatus = AMAuthorizationStatusDenied;
            break;
        case PHAuthorizationStatusAuthorized:
            authStatus = AMAuthorizationStatusAuthorized;
            break;
        case PHAuthorizationStatusNotDetermined:
        default:
            authStatus = AMAuthorizationStatusNotDetermined;
            break;
    }
    return authStatus;
}

+ (AMAuthorizationStatus)authorizationStatus
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return [[self class] authorizationStatusFromPHAuthorizationStatus:[PHPhotoLibrary authorizationStatus]];
    }
    else {
        return [[self class] authorizationStatusFromALAuthorizationStatus:[ALAssetsLibrary authorizationStatus]];
    }
}

+ (void)requestAuthorization:(void(^)(AMAuthorizationStatus status))handler
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (handler) {
                handler([[self class] authorizationStatusFromPHAuthorizationStatus: status]);
            }
        }];
    }
    else {
        @autoreleasepool {
            ALAssetsLibrary *testLibrary = [ALAssetsLibrary new];
            [testLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                if (nil == group) {
                    if (handler) {
                        handler([[self class] authorizationStatus]);
                    }
                    return;
                }
                *stop = YES;
            } failureBlock:^(NSError *error) {
                if (handler) {
                    handler([[self class] authorizationStatus]);
                }
            }];
        }
    }
}

- (void)createAlbum:(NSString *)title resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [_photoManager createAlbum: title resultBlock: resultBlock];
}

- (void)checkAlbum:(NSString *)title resultBlock:(AMPhotoManagerCheckBlock)resultBlock
{
    [_photoManager checkAlbum: title resultBlock: resultBlock];
}

- (void)enumerateAlbums:(AMPhotoManagerAlbumEnumeratorBlock)enumeratorBlock resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [_photoManager enumerateAlbums: enumeratorBlock resultBlock: resultBlock];
}

- (void)enumerateAssets:(AMPhotoManagerAssetEnumeratorBlock)enumeratorBlock inPhotoAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [_photoManager enumerateAssets: enumeratorBlock inPhotoAlbum: photoAlbum resultBlock: resultBlock];
}

- (void)addAsset:(AMPhotoAsset *)asset toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [_photoManager addAsset:asset toAlbum:photoAlbum resultBlock:resultBlock];
}

- (void)writeImageToSavedPhotosAlbum:(UIImage *)image resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [_photoManager writeImageToSavedPhotosAlbum: image resultBlock: resultBlock];
}

- (void)writeImage:(UIImage *)image toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [_photoManager writeImage: image toAlbum: photoAlbum resultBlock: resultBlock];
}

- (void)writeImageDataToSavedPhotosAlbum:(NSData *)imageData metadata:(NSDictionary *)metadata resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [_photoManager writeImageDataToSavedPhotosAlbum: imageData metadata:metadata resultBlock: resultBlock];
}

- (void)writeImageData:(NSData *)imageData metadata:(NSDictionary *)metadata toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [_photoManager writeImageData:imageData metadata:metadata toAlbum:photoAlbum resultBlock:resultBlock];
}

- (void)writeVideoAtPathToSavedPhotosAlbum:(NSString *)filePath resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [_photoManager writeVideoAtPathToSavedPhotosAlbum:filePath resultBlock:resultBlock];
}

@end
