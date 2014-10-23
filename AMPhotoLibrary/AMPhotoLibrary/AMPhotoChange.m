//
//  AMPhotoChange.m
//  AMPhotoLibrary
//
//  Created by Anwu Yang on 10/17/14.
//  Copyright (c) 2014 arcrain. All rights reserved.
//

#import "AMPhotoChange_Private.h"

#pragma mark - AMPhotoChange
@interface AMPhotoChange ()
{
    PHChange *_changeInstance;
    NSDictionary *_noteUserInfo;
}
@end

@implementation AMPhotoChange

+ (instancetype)changeWithALChange:(NSDictionary *)changeInfo
{
    return [[AMPhotoChange alloc] initWithALChange:changeInfo];
}

+ (instancetype)changeWithPHChange:(PHChange *)changeInstance
{
    return [[AMPhotoChange alloc] initWithPHChange:changeInstance];
}

- (instancetype)initWithALChange:(NSDictionary *)changeInfo
{
    self = [super init];
    if (self) {
        _noteUserInfo = changeInfo;
    }
    return self;
}

- (instancetype)initWithPHChange:(PHChange *)changeInstance
{
    self = [super init];
    if (self) {
        _changeInstance = changeInstance;
    }
    return self;
}

- (AMPhotoChangeDetails *)changeDetailsForObject:(id)object
{
    AMPhotoChangeDetails *changeDetails = nil;
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
    else {
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

@end

#pragma mark - AMPhotoChangeDetails
@interface AMPhotoChangeDetails ()
{
    PHObjectChangeDetails *_changeDetails;
    
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

+ (instancetype)changeDetailsWithPHObjectChangeDetails:(PHObjectChangeDetails *)changeDetails
{
    if (nil == changeDetails) {
        return nil;
    }
    return [[[self class] alloc] initWithPHObjectChangeDetails: changeDetails];
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

- (instancetype)initWithPHObjectChangeDetails:(PHObjectChangeDetails *)changeDetails
{
    self = [super init];
    if (self) {
        _changeDetails = changeDetails;
    }
    return self;
}

- (id)objectBeforeChanges
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return _changeDetails.objectBeforeChanges;
    }
    else {
        return _object;
    }
}

- (id)objectAfterChanges
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        return _changeDetails.objectAfterChanges;
    }
    else {
        return nil;
    }
}

- (BOOL)objectWasChanged
{
    __block BOOL wasChanged = NO;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        wasChanged = _changeDetails.assetContentChanged;
    }
    else {
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
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        wasDeleted = _changeDetails.objectWasDeleted;
    }
    else {
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
