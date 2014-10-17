//
//  AMPhotoChange_Private.h
//  AMPhotoLibrary
//
//  Created by Anwu Yang on 10/17/14.
//  Copyright (c) 2014 arcrain. All rights reserved.
//

#import "AMPhotoChange.h"

#pragma mark - AMPhotoChange
@interface AMPhotoChange (Private)

+ (instancetype)changeWithALChange:(NSDictionary *)changeInfo;
+ (instancetype)changeWithPHChange:(PHChange *)changeInstance;

@end

#pragma mark - AMPhotoChangeDetails
@interface AMPhotoChangeDetails (Private)

+ (instancetype)changeDetailsWithNotificationInfo:(NSDictionary *)userInfo forObject:(NSObject *)object;
+ (instancetype)changeDetailsWithPHChange:(PHChange *)changeInstance forPHObject:(PHObject *)phObject;

@end
