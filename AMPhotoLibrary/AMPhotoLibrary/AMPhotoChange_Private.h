//
//  AMPhotoChange_Private.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoChange.h"

#pragma mark - AMPhotoChange
@interface AMPhotoChange (Private)

+ (instancetype)changeWithALChange:(NSDictionary *)changeInfo;
#ifdef __AMPHOTOLIB_USE_PHOTO__
+ (instancetype)changeWithPHChange:(PHChange *)changeInstance;
#endif

- (void)setAlbumCreated:(BOOL)created;
- (void)setAlbumDeleted:(BOOL)deleted;

@end

#pragma mark - AMPhotoChangeDetails
@interface AMPhotoChangeDetails (Private)

+ (instancetype)changeDetailsWithNotificationInfo:(NSDictionary *)userInfo forObject:(NSObject *)object;

#ifdef __AMPHOTOLIB_USE_PHOTO__
+ (instancetype)changeDetailsWithPHObjectChangeDetails:(PHObjectChangeDetails *)changeDetails PHFetchResultChangeDetails:(PHFetchResultChangeDetails *)fetchResultChangeDetails;
#endif

@end
