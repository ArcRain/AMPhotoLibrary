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
#if __AMPHOTOLIB_USE_PHOTO__
+ (instancetype)changeWithPHChange:(PHChange *)changeInstance;
#endif

@end

#pragma mark - AMPhotoChangeDetails
@interface AMPhotoChangeDetails (Private)

+ (instancetype)changeDetailsWithNotificationInfo:(NSDictionary *)userInfo forObject:(NSObject *)object;

#if __AMPHOTOLIB_USE_PHOTO__
+ (instancetype)changeDetailsWithPHObjectChangeDetails:(PHObjectChangeDetails *)changeDetails;
+ (instancetype)changeDetailsWithPHFetchResultChangeDetails:(PHFetchResultChangeDetails *)fetchResultChangeDetails;
#endif

@end
