//
//  AMALChange.m
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import "AMALAsset.h"
#import "AMALAlbum.h"
#import "AMALChange.h"

#pragma mark - AMALChange
@interface AMALChange ()
{
    NSDictionary *_noteUserInfo;
    BOOL _isAlbumCreated;
    BOOL _isAlbumDeleted;
}
@end

@implementation AMALChange

@synthesize isAlbumCreated = _isAlbumCreated;
@synthesize isAlbumDeleted = _isAlbumDeleted;

+ (instancetype)changeWithALChange:(NSDictionary *)changeInfo {
    return [[[self class] alloc] initWithALChange:changeInfo];
}

- (instancetype)initWithALChange:(NSDictionary *)changeInfo {
    self = [super init];
    if (self) {
        _noteUserInfo = changeInfo;
        _isAlbumCreated = NO;
        _isAlbumDeleted = NO;
    }
    return self;
}

- (void)setAlbumCreated:(BOOL)created
{
    _isAlbumCreated = created;
}

- (void)setAlbumDeleted:(BOOL)deleted
{
    _isAlbumDeleted = deleted;
}

- (id<AMPhotoChangeDetails>)changeDetailsForObject:(id)object {
    id<AMPhotoChangeDetails> changeDetails = nil;
    if ([object isKindOfClass:[AMALAsset class]]) {
        AMALAsset *asset = (AMALAsset *)object;
        changeDetails = [AMALChangeDetails changeDetailsWithNotificationInfo: _noteUserInfo forObject:asset.wrappedInstance];
    }
    else if ([object isKindOfClass:[AMALAlbum class]]) {
        AMALAlbum *album = (AMALAlbum *)object;
        changeDetails = [AMALChangeDetails changeDetailsWithNotificationInfo: _noteUserInfo forObject:album.wrappedInstance];
    }
    return changeDetails;
}

@end

#pragma mark - AMALChangeDetails
@interface AMALChangeDetails ()
{
    NSDictionary *_userInfo;
    NSObject *_object;
}
@end

@implementation AMALChangeDetails

+ (instancetype)changeDetailsWithNotificationInfo:(NSDictionary *)userInfo forObject:(NSObject *)object {
    if (nil == userInfo) {
        return nil;
    }
    return [[[self class] alloc] initWithNotificationInfo: userInfo forObject: object];
}


- (instancetype)initWithNotificationInfo:(NSDictionary *)userInfo forObject:(NSObject *)object {
    self = [super init];
    if (self) {
        _userInfo = userInfo;
        _object = object;
    }
    return self;
}


- (id)objectBeforeChanges {
    return _object;
}

- (id)objectAfterChanges {
    return nil;
}

- (BOOL)objectWasChanged {
    __block BOOL wasChanged = NO;
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
    return wasChanged;
}

- (BOOL)objectWasDeleted {
    __block BOOL wasDeleted = NO;
    if ([_object isKindOfClass:[ALAssetsGroup class]]) {
        NSSet *deletedAssetsGroups = _userInfo[ALAssetLibraryDeletedAssetGroupsKey];
        NSURL *objectURL = [((ALAssetsGroup *)_object) valueForProperty:ALAssetsGroupPropertyURL];
        [deletedAssetsGroups enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            NSURL *assetURL = (NSURL *)obj;
            wasDeleted = [assetURL isEqual: objectURL];
            *stop = wasDeleted;
        }];
    }
    return wasDeleted;
}

@end
