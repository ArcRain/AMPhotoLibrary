//
//  AMPHPhotoLibrary.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPHChange.h"
#import "AMPHAlbum.h"
#import "AMPHPhotoLibrary.h"

@interface AMPHPhotoLibrary () <PHPhotoLibraryChangeObserver>
{
    NSMutableSet *_changeObservers;
    PHFetchResult *_albumFetchResult;
}
@end

@implementation AMPHPhotoLibrary

static AMPHPhotoLibrary *s_sharedPhotoManager = nil;
+ (id<AMPhotoManager>)sharedPhotoManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_sharedPhotoManager = [AMPHPhotoLibrary new];
    });
    return s_sharedPhotoManager;
}

+ (AMAuthorizationStatus)authorizationStatusFromPHAuthorizationStatus:(PHAuthorizationStatus)authorizationStatus {
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

+ (AMAuthorizationStatus)authorizationStatus {
    return [[self class] authorizationStatusFromPHAuthorizationStatus:[PHPhotoLibrary authorizationStatus]];
}

+ (void)requestAuthorization:(void(^)(AMAuthorizationStatus status))handler {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (handler) {
            handler([[self class] authorizationStatusFromPHAuthorizationStatus: status]);
        }
    }];
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    [_changeObservers removeAllObjects];
    _changeObservers = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (NSMutableSet *)changeObservers {
    if (nil == _changeObservers) {
        _changeObservers = [NSMutableSet new];
    }
    return _changeObservers;
}

- (void)registerChangeObserver:(id<AMPhotoLibraryChangeObserver>)observer {
    [self.changeObservers addObject: observer];
}

- (void)unregisterChangeObserver:(id<AMPhotoLibraryChangeObserver>)observer {
    [self.changeObservers removeObject: observer];
}

- (void)createAlbum:(NSString *)title resultBlock:(AMPhotoManagerResultBlock)resultBlock {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle: title];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

- (void)checkAlbum:(NSString *)title resultBlock:(AMPhotoManagerCheckBlock)resultBlock {
    __block id<AMPhotoAlbum> foundAlbum = nil;
    [self enumerateAlbums:^(id<AMPhotoAlbum> album, BOOL *stop) {
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

- (void)enumerateAlbums:(AMPhotoManagerAlbumEnumerationBlock)enumerationBlock resultBlock:(AMPhotoManagerResultBlock)resultBlock {
    void (^notifyResult)(BOOL success, NSError *error) = ^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    };
    
    __block BOOL isStop = NO;
    do {       
        PHFetchResult *smartAlbumResult = [PHAssetCollection fetchAssetCollectionsWithType: PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        [smartAlbumResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (enumerationBlock) {
                id<AMPhotoAlbum> photoAlbum = [AMPHAlbum photoAlbumWithPHAssetCollection: obj];
                enumerationBlock(photoAlbum, stop);
                isStop = *stop;
            }
        }];
        if (isStop) {
            break;
        }
        
        _albumFetchResult = [PHAssetCollection fetchAssetCollectionsWithType: PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        [_albumFetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (enumerationBlock) {
                id<AMPhotoAlbum> photoAlbum = [AMPHAlbum photoAlbumWithPHAssetCollection: obj];
                enumerationBlock(photoAlbum, stop);
                isStop = *stop;
            }
        }];
    } while (false);
    notifyResult(YES, nil);
}

- (void)addAsset:(id<AMPhotoAsset>)asset toAlbum:(id<AMPhotoAlbum>)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock {
    PHAssetCollection *collection = photoAlbum.wrappedInstance;
    PHAsset *phAsset = asset.wrappedInstance;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCollectionChangeRequest *collectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection: collection];
        [collectionRequest addAssets: @[phAsset]];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

- (void)deleteAssets:(NSArray *)assets resultBlock:(AMPhotoManagerResultBlock)resultBlock {
    NSMutableArray *deleteAssets = [NSMutableArray array];
    for (id<AMPhotoAsset> asset in assets) {
        [deleteAssets addObject:asset.wrappedInstance];
    }
    if (0 == deleteAssets.count) {
        if (resultBlock) {
            resultBlock(YES, nil);
        }
        return;
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest deleteAssets:deleteAssets];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

- (void)deleteAlbums:(NSArray *)albums resultBlock:(AMPhotoManagerResultBlock)resultBlock {
    NSMutableArray *deleteAlbums = [NSMutableArray array];
    for (id<AMPhotoAlbum> album in albums) {
        [deleteAlbums addObject:album.wrappedInstance];
    }
    if (0 == deleteAlbums.count) {
        if (resultBlock) {
            resultBlock(YES, nil);
        }
        return;
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest deleteAssetCollections:deleteAlbums];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

- (void)writeImageToSavedPhotosAlbum:(UIImage *)image resultBlock:(AMPhotoManagerResultBlock)resultBlock {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage: image];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

- (void)writeImage:(UIImage *)image toAlbum:(id<AMPhotoAlbum>)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock {
    PHAssetCollection *collection = photoAlbum.wrappedInstance;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage: image];
        PHAssetCollectionChangeRequest *collectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection: collection];
        [collectionRequest addAssets: @[assetRequest.placeholderForCreatedAsset]];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

- (UIImage *)imageWithData:(NSData *)imageData metadata:(NSDictionary *)metadata {
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    NSMutableDictionary *source_metadata = (NSMutableDictionary *)CFBridgingRelease(CGImageSourceCopyProperties(source, NULL));
    [source_metadata addEntriesFromDictionary: metadata];
    
    NSMutableData *dest_data = [NSMutableData data];
    CFStringRef UTI = CGImageSourceGetType(source);
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data, UTI, 1,NULL);
    CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef)source_metadata);
    CGImageDestinationFinalize(destination);
    CFRelease(source);
    CFRelease(destination);
    return [UIImage imageWithData: dest_data];
}

- (void)writeImageDataToSavedPhotosAlbum:(NSData *)imageData metadata:(NSDictionary *)metadata resultBlock:(AMPhotoManagerResultBlock)resultBlock {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        UIImage *image = [self imageWithData: imageData metadata:metadata];
        [PHAssetChangeRequest creationRequestForAssetFromImage: image];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

- (void)writeImageData:(NSData *)imageData metadata:(NSDictionary *)metadata toAlbum:(id<AMPhotoAlbum>)photoAlbum resultBlock:(AMPhotoManagerResultBlock)resultBlock {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        UIImage *image = [self imageWithData: imageData metadata:metadata];
        PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage: image];
        PHAssetCollectionChangeRequest *collectionRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection: photoAlbum.wrappedInstance];
        [collectionRequest addAssets: @[assetRequest.placeholderForCreatedAsset]];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

- (void)writeVideoAtPathToSavedPhotosAlbum:(NSString *)filePath resultBlock:(AMPhotoManagerResultBlock)resultBlock {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:filePath]];
    } completionHandler:^(BOOL success, NSError *error) {
        if (resultBlock) {
            resultBlock(success, error);
        }
    }];
}

#pragma mark - PHPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    AMPHChange *photoChange = [AMPHChange changeWithPHChange: changeInstance];
    
    PHFetchResultChangeDetails *albumResultChangeDetails = [changeInstance changeDetailsForFetchResult:_albumFetchResult];
    [photoChange setAlbumCreated: albumResultChangeDetails.insertedObjects.count > 0];
    [photoChange setAlbumDeleted: albumResultChangeDetails.removedObjects.count > 0];
    
    [_changeObservers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        id<AMPhotoLibraryChangeObserver> changeObserver = obj;
        [changeObserver photoLibraryDidChange: photoChange];
    }];
}

@end
