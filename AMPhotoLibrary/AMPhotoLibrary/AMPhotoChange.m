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

- (AMPhotoChangeDetails *)changeDetailsForObject:(NSObject *)object
{
    AMPhotoChangeDetails *changeDetails = nil;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO_8_0) {
        if ([object isKindOfClass:[PHObject class]]) {
            changeDetails = [AMPhotoChangeDetails changeDetailsWithPHChange: _changeInstance forPHObject: (PHObject *)object];
        }
    }
    else {
        if ( ([object isKindOfClass:[ALAssetsGroup class]]) || ([object isKindOfClass:[ALAsset class]]) ) {
            changeDetails = [AMPhotoChangeDetails changeDetailsWithNotificationInfo:_noteUserInfo forObject: object];
        }
    }
    return changeDetails;
}

@end

#pragma mark - AMPhotoChangeDetails
@interface AMPhotoChangeDetails ()
{
    __weak PHChange *_changeInstance;
    PHObject *_phObject;
    
    __weak NSDictionary *_userInfo;
    NSObject *_object;
}
@end

@implementation AMPhotoChangeDetails

+ (instancetype)changeDetailsWithNotificationInfo:(NSDictionary *)userInfo forObject:(NSObject *)object
{
    if (nil == userInfo) {
        return nil;
    }
    return [[self class] initWithNotificationInfo: userInfo forObject: object];
}

+ (instancetype)changeDetailsWithPHChange:(PHChange *)changeInstance forPHObject:(PHObject *)phObject
{
    if ((nil == changeInstance) || (nil == phObject)) {
        return nil;
    }
    return [[self class] initWithPHChange: changeInstance forPHObject: phObject];
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

- (instancetype)initWithPHChange:(PHChange *)changeInstance forPHObject:(PHObject *)phObject
{
    self = [super init];
    if (self) {
        _changeInstance = changeInstance;
        _phObject = phObject;
    }
    return self;
}

@end
