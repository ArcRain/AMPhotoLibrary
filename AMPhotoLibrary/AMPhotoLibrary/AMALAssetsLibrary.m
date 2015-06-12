//
//  AMALAssetsLibrary.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMALAssetsLibrary.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AMPhotoChange_Private.h"

@interface AMALAssetsLibrary ()
{
    ALAssetsLibrary *_assetsLibrary;
    NSMutableSet *_changeObservers;
}
@end

@implementation AMALAssetsLibrary

static AMALAssetsLibrary *s_sharedPhotoManager = nil;
+ (id<AMPhotoManager>)sharedPhotoManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_sharedPhotoManager = [AMALAssetsLibrary new];
    });
    return s_sharedPhotoManager;
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

+ (AMAuthorizationStatus)authorizationStatus
{
    return [[self class] authorizationStatusFromALAuthorizationStatus:[ALAssetsLibrary authorizationStatus]];
}

+ (void)requestAuthorization:(void(^)(AMAuthorizationStatus status))handler
{
    @autoreleasepool {
        ALAssetsLibrary *testLibrary = [ALAssetsLibrary new];
        [testLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (nil == group) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler([[self class] authorizationStatus]);
                    }
                });
                return;
            }
            *stop = YES;
        } failureBlock:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (handler) {
                    handler([[self class] authorizationStatus]);
                }
            });
        }];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_changeObservers removeAllObjects];
    _changeObservers = nil;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _assetsLibrary = [ALAssetsLibrary new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryDidChange:) name:ALAssetsLibraryChangedNotification object:nil];
    }
    return self;
}

- (NSMutableSet *)changeObservers
{
    if (nil == _changeObservers) {
        _changeObservers = [NSMutableSet new];
    }
    return _changeObservers;
}

- (void)registerChangeObserver:(id<AMPhotoLibraryChangeObserver>)observer
{
    [self.changeObservers addObject: observer];
}

- (void)unregisterChangeObserver:(id<AMPhotoLibraryChangeObserver>)observer
{
    [self.changeObservers removeObject: observer];
}

- (void)createAlbum:(NSString *)title resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    void (^notifyResult)(BOOL success, NSError *error) = ^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    };
    
    [_assetsLibrary addAssetsGroupAlbumWithName:title resultBlock:^(ALAssetsGroup *group) {
        notifyResult(nil != group, nil);
    } failureBlock:^(NSError *error) {
        notifyResult(NO, error);
    }];
}

- (void)checkAlbum:(NSString *)title resultBlock:(AMPhotoManagerCheckBlock)resultBlock
{
    __block AMPhotoAlbum *foundAlbum = nil;
    [self enumerateAlbums:^(AMPhotoAlbum *album, BOOL *stop) {
        if ([album.title isEqualToString: title]) {
            foundAlbum = album;
            *stop = YES;
        }
    } resultBlock:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(foundAlbum, error);
        }
    }];
}

- (void)enumerateAlbums:(AMPhotoManagerAlbumEnumerationBlock)enumerationBlock resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    void (^notifyResult)(BOOL success, NSError *error) = ^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    };
        
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (nil == group) {
            notifyResult(YES, nil);
            return;
        }
        if (enumerationBlock) {
            AMPhotoAlbum *photoAlbum = [AMPhotoAlbum photoAlbumWithALAssetsGroup: group];
            enumerationBlock(photoAlbum, stop);
        }
    } failureBlock:^(NSError *error) {
        notifyResult(NO, error);
    }];    
}

- (void)addAsset:(AMPhotoAsset *)asset toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    BOOL hasAdded = [[photoAlbum asALAssetsGroup] addAsset:[asset asALAsset]];
    if (resultBlock) {
        resultBlock(hasAdded, nil);
    }
}

enum {
    kAMASSET_PENDINGDELETE = 1,
    kAMASSET_ALLFINISHED = 0
};

- (void)deleteAssets:(NSArray *)assets resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    NSMutableArray *deleteAssets = [NSMutableArray array];
    for (AMPhotoAsset *asset in assets) {
        [deleteAssets addObject:[asset asALAsset]];
    }
    if (0 == deleteAssets.count) {
        if (resultBlock) {
            resultBlock(YES, nil);
        }
        return;
    }
    
    __block BOOL isAllDeleted = YES;
    for (ALAsset *alAsset in deleteAssets) {
        if (!alAsset.editable) {
            isAllDeleted = NO;
            continue;
        }
        @autoreleasepool {
            NSConditionLock* assetDeleteLock = [[NSConditionLock alloc] initWithCondition:kAMASSET_PENDINGDELETE];
            [alAsset setImageData:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                [assetDeleteLock lock];
                [assetDeleteLock unlockWithCondition:kAMASSET_ALLFINISHED];
                
                isAllDeleted &= (nil != assetURL);
            }];
            [assetDeleteLock lockWhenCondition:kAMASSET_ALLFINISHED];
            [assetDeleteLock unlock];
            assetDeleteLock = nil;
        }
    }
    
    if (resultBlock) {
        resultBlock(isAllDeleted, nil);
    }
}

- (void)deleteAlbums:(NSArray *)albums resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    if (resultBlock) {
        resultBlock(NO, nil);
    }
}

- (void)writeImageToSavedPhotosAlbum:(UIImage *)image resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [_assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
        if (resultBlock) {
            resultBlock(nil != assetURL, error);
        }
    }];
}

- (void)writeImage:(UIImage *)image toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    void (^notifyResult)(BOOL success, NSError *error) = ^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    };

    [_assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
        if (nil == assetURL) {
            notifyResult(NO, error);
            return;
        }
        [_assetsLibrary assetForURL: assetURL resultBlock:^(ALAsset *asset) {
            if (nil == asset) {
                notifyResult(NO, error);
                return;
            }
            BOOL success = [[photoAlbum asALAssetsGroup] addAsset: asset];
            notifyResult(success, nil);
        } failureBlock:^(NSError *error) {
            notifyResult(NO, error);
        }];
    }];
}

- (void)writeImageDataToSavedPhotosAlbum:(NSData *)imageData metadata:(NSDictionary *)metadata resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [_assetsLibrary writeImageDataToSavedPhotosAlbum: imageData metadata: metadata completionBlock:^(NSURL *assetURL, NSError *error) {
        if (resultBlock) {
            resultBlock(nil != assetURL, error);
        }
    }];
}

- (void)writeImageData:(NSData *)imageData metadata:(NSDictionary *)metadata toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    void (^notifyResult)(BOOL success, NSError *error) = ^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    };
    
    [_assetsLibrary writeImageDataToSavedPhotosAlbum: imageData metadata: metadata completionBlock:^(NSURL *assetURL, NSError *error) {
        if (nil == assetURL) {
            notifyResult(NO, error);
            return;
        }
        [_assetsLibrary assetForURL: assetURL resultBlock:^(ALAsset *asset) {
            if (nil == asset) {
                notifyResult(NO, error);
                return;
            }
            BOOL success = [[photoAlbum asALAssetsGroup] addAsset: asset];
            notifyResult(success, nil);
        } failureBlock:^(NSError *error) {
            notifyResult(NO, error);
        }];
    }];
}

- (void)writeVideoAtPathToSavedPhotosAlbum:(NSString *)filePath resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    [_assetsLibrary writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:filePath] completionBlock:^(NSURL *assetURL, NSError *error) {
        if (resultBlock) {
            resultBlock(nil != assetURL, error);
        }
    }];
}

/*
 In iOS 4.0, the notification’s object is nil. In iOS 4.1 and later, the notification object is the library object that posted the notification.
 In iOS 6.0 and later, the user information dictionary describes what changed:
 If the user information dictionary is nil, reload all assets and asset groups.
 If the user information dictionary an empty dictionary, there is no need to reload assets and asset groups.
 If the user information dictionary is not empty, reload the effected assets and asset groups. For the keys used, see Notification Keys.
 
 This notification is sent on an arbitrary thread.
 */
- (void)assetsLibraryDidChange:(NSNotification *)note
{
    AMPhotoChange *photoChange = nil;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        photoChange = [AMPhotoChange changeWithALChange: note.userInfo];
    }
    
    [_changeObservers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        id<AMPhotoLibraryChangeObserver> changeObserver = obj;
        [changeObserver photoLibraryDidChange: photoChange];
    }];
}

@end
