//
//  AMPhotoChange.m
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoChange_Private.h"

#pragma mark - AMPhotoChange
@interface AMPhotoChange ()
{
#ifdef __AMPHOTOLIB_USE_PHOTO__
    PHChange *_changeInstance;
#endif
    NSDictionary *_noteUserInfo;
}
@end

@implementation AMPhotoChange

+ (instancetype)changeWithALChange:(NSDictionary *)changeInfo
{
    return [[AMPhotoChange alloc] initWithALChange:changeInfo];
}

- (instancetype)initWithALChange:(NSDictionary *)changeInfo
{
    self = [super init];
    if (self) {
        _noteUserInfo = changeInfo;
    }
    return self;
}

#ifdef __AMPHOTOLIB_USE_PHOTO__

+ (instancetype)changeWithPHChange:(PHChange *)changeInstance
{
    return [[AMPhotoChange alloc] initWithPHChange:changeInstance];
}

- (instancetype)initWithPHChange:(PHChange *)changeInstance
{
    self = [super init];
    if (self) {
        _changeInstance = changeInstance;
    }
    return self;
}

#endif

- (AMPhotoChangeDetails *)changeDetailsForObject:(id)object
{
    AMPhotoChangeDetails *changeDetails = nil;
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        if ([object isKindOfClass:[AMPhotoAsset class]]) {
            AMPhotoAsset *asset = (AMPhotoAsset *)object;
            changeDetails = [AMPhotoChangeDetails changeDetailsWithPHObjectChangeDetails: [_changeInstance changeDetailsForObject:[asset asPHAsset]]];
        }
        else if ([object isKindOfClass:[AMPhotoAlbum class]]) {
            AMPhotoAlbum *album = (AMPhotoAlbum *)object;
            changeDetails = [AMPhotoChangeDetails changeDetailsWithPHObjectChangeDetails: [_changeInstance changeDetailsForObject:[album asPHAssetCollection]]];
        }
    }
    else
#endif
    {
        if ([object isKindOfClass:[AMPhotoAsset class]]) {
            AMPhotoAsset *asset = (AMPhotoAsset *)object;
            changeDetails = [AMPhotoChangeDetails changeDetailsWithNotificationInfo: _noteUserInfo forObject:[asset asALAsset]];
        }
        else if ([object isKindOfClass:[AMPhotoAlbum class]]) {
            AMPhotoAlbum *album = (AMPhotoAlbum *)object;
            changeDetails = [AMPhotoChangeDetails changeDetailsWithNotificationInfo: _noteUserInfo forObject:[album asALAssetsGroup]];
        }
    }
    return changeDetails;
}

- (AMPhotoChangeDetails *)changeDetailsForFetchResult:(id)object
{
    AMPhotoChangeDetails *changeDetails = nil;
    if ([object isKindOfClass:[AMPhotoAlbum class]]) {
        AMPhotoAlbum *album = (AMPhotoAlbum *)object;
#ifdef __AMPHOTOLIB_USE_PHOTO__
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
            changeDetails = [AMPhotoChangeDetails changeDetailsWithPHFetchResultChangeDetails: [_changeInstance changeDetailsForFetchResult:album.fetchResult]];
        }
        else
#endif
        {
            changeDetails = [AMPhotoChangeDetails changeDetailsWithNotificationInfo: _noteUserInfo forObject:[album asALAssetsGroup]];
        }
    }
    return changeDetails;
}

@end

#pragma mark - AMPhotoChangeDetails
@interface AMPhotoChangeDetails ()
{
#ifdef __AMPHOTOLIB_USE_PHOTO__
    PHObjectChangeDetails *_changeDetails;
    PHFetchResultChangeDetails *_fetchResultChangeDetails;
#endif
    
    NSDictionary *_userInfo;
    NSObject *_object;
}
@end

@implementation AMPhotoChangeDetails

+ (instancetype)changeDetailsWithNotificationInfo:(NSDictionary *)userInfo forObject:(NSObject *)object
{
    if (nil == userInfo) {
        return nil;
    }
    return [[[self class] alloc] initWithNotificationInfo: userInfo forObject: object];
}


- (instancetype)initWithNotificationInfo:(NSDictionary *)userInfo forObject:(NSObject *)object
{
    self = [super init];
    if (self) {
        _userInfo = userInfo;
        _object = object;
    }
    return self;
}

#ifdef __AMPHOTOLIB_USE_PHOTO__

+ (instancetype)changeDetailsWithPHObjectChangeDetails:(PHObjectChangeDetails *)changeDetails
{
    if (nil == changeDetails) {
        return nil;
    }
    return [[[self class] alloc] initWithPHObjectChangeDetails: changeDetails];
}

+ (instancetype)changeDetailsWithPHFetchResultChangeDetails:(PHFetchResultChangeDetails *)fetchResultChangeDetails
{
    if (nil == fetchResultChangeDetails) {
        return nil;
    }
    return [[[self class] alloc] initWithPHFetchResultChangeDetails: fetchResultChangeDetails];
}

- (instancetype)initWithPHObjectChangeDetails:(PHObjectChangeDetails *)changeDetails
{
    self = [super init];
    if (self) {
        _changeDetails = changeDetails;
        _fetchResultChangeDetails = nil;
    }
    return self;
}

- (instancetype)initWithPHFetchResultChangeDetails:(PHFetchResultChangeDetails *)fetchResultChangeDetails
{
    self = [super init];
    if (self) {
        _changeDetails = nil;
        _fetchResultChangeDetails = fetchResultChangeDetails;
    }
    return self;
}

#endif

- (id)objectBeforeChanges
{
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        if (nil != _changeDetails) {
            return _changeDetails.objectBeforeChanges;
        }
        else if (nil != _fetchResultChangeDetails) {
            return _fetchResultChangeDetails.fetchResultBeforeChanges;
        }
        else {
            return nil;
        }
    }
    else
#endif
    {
        return _object;
    }
}

- (id)objectAfterChanges
{
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        if (nil != _changeDetails) {
            return _changeDetails.objectAfterChanges;
        }
        else if (nil != _fetchResultChangeDetails) {
            return _fetchResultChangeDetails.fetchResultAfterChanges;
        }
        else {
            return nil;
        }
    }
    else
#endif
    {
        return nil;
    }
}

- (BOOL)objectWasChanged
{
    __block BOOL wasChanged = NO;
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        if (nil != _changeDetails) {
            wasChanged = _changeDetails.assetContentChanged;
        }
        else if (nil != _fetchResultChangeDetails) {
            wasChanged = (_fetchResultChangeDetails.fetchResultAfterChanges != _fetchResultChangeDetails.fetchResultBeforeChanges);
        }
    }
    else
#endif
    {
        if ([_object isKindOfClass:[ALAsset class]]) {
            NSSet *updatedAssets = _userInfo[ALAssetLibraryUpdatedAssetsKey];
            NSURL *objectURL = [((ALAsset *)_object) valueForProperty:ALAssetPropertyAssetURL];
            [updatedAssets enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                NSURL *assetURL = (NSURL *)obj;
                wasChanged = [assetURL isEqual: objectURL];
                *stop = wasChanged;
            }];
        }
        else if ([_object isKindOfClass:[ALAssetsGroup class]]) {
            NSSet *updatedAssetsGroups = _userInfo[ALAssetLibraryUpdatedAssetGroupsKey];
            NSURL *objectURL = [((ALAssetsGroup *)_object) valueForProperty:ALAssetsGroupPropertyURL];
            [updatedAssetsGroups enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                NSURL *assetURL = (NSURL *)obj;
                wasChanged = [assetURL isEqual: objectURL];
                *stop = wasChanged;
            }];
        }
    }
    return wasChanged;
}

- (BOOL)objectWasDeleted
{
    __block BOOL wasDeleted = NO;
#ifdef __AMPHOTOLIB_USE_PHOTO__
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        wasDeleted = _changeDetails.objectWasDeleted;
    }
    else
#endif
    {
        if ([_object isKindOfClass:[ALAssetsGroup class]]) {
            NSSet *deletedAssetsGroups = _userInfo[ALAssetLibraryDeletedAssetGroupsKey];
            NSURL *objectURL = [((ALAssetsGroup *)_object) valueForProperty:ALAssetsGroupPropertyURL];
            [deletedAssetsGroups enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                NSURL *assetURL = (NSURL *)obj;
                wasDeleted = [assetURL isEqual: objectURL];
                *stop = wasDeleted;
            }];
        }
    }
    return wasDeleted;
}

@end
