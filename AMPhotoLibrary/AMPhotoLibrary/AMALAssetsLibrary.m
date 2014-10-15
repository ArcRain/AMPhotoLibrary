//
//  AMALAssetsLibrary.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMALAssetsLibrary.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface AMALAssetsLibrary ()
{
    ALAssetsLibrary *_assetsLibrary;
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)enumerateAlbums:(AMPhotoManagerAlbumEnumeratorBlock)enumeratorBlock resultBlock:(AMPhotoManagerResultBlock)resultBlock
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
        if (enumeratorBlock) {
            AMPhotoAlbum *photoAlbum = [AMPhotoAlbum photoAlbumWithALAssetsGroup: group];
            enumeratorBlock(photoAlbum, stop);
        }
    } failureBlock:^(NSError *error) {
        notifyResult(NO, error);
    }];    
}

- (void)enumerateAssets:(AMPhotoManagerAssetEnumeratorBlock)enumeratorBlock inPhotoAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    void (^notifyResult)(BOOL success, NSError *error) = ^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    };
    
    [[photoAlbum asALAssetsGroup] enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (nil == result) {
            notifyResult(YES, nil);
            return;
        }
        if (enumeratorBlock) {
            AMPhotoAsset *asset = [AMPhotoAsset photoAssetWithALAsset: result];
            enumeratorBlock(asset, index, stop);
        }        
    }];
}

- (void)addAsset:(AMPhotoAsset *)asset toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    BOOL hasAdded = [[photoAlbum asALAssetsGroup] addAsset:[asset asALAsset]];
    if (resultBlock) {
        resultBlock(hasAdded, nil);
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

- (void)assetsLibraryDidChange:(NSNotification *)note
{
    //TODO:
}

@end
