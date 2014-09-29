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

- (instancetype)init
{
    self = [super init];
    if (self) {
        _assetsLibrary = [ALAssetsLibrary new];
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
        resultBlock(foundAlbum, error);
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
        }
        if (enumeratorBlock) {
            AMPhotoAsset *asset = [AMPhotoAsset photoAssetWithALAsset: result];
            enumeratorBlock(asset, index, stop);
        }        
    }];
}

- (void)addAsset:(AMPhotoAsset *)asset toAlbum:(AMPhotoAlbum *)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock
{
    resultBlock([[photoAlbum asALAssetsGroup] addAsset:[asset asALAsset]], nil);
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

@end
