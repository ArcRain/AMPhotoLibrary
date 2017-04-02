//
//  AMALChange.h
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMPhotoChange.h"

@interface AMALChange : NSObject<AMPhotoChange>

+ (instancetype)changeWithALChange:(NSDictionary *)changeInfo;
- (instancetype)initWithALChange:(NSDictionary *)changeInfo;

- (void)setAlbumCreated:(BOOL)created;
- (void)setAlbumDeleted:(BOOL)deleted;

@end

@interface AMALChangeDetails : NSObject<AMPhotoChangeDetails>

+ (instancetype)changeDetailsWithNotificationInfo:(NSDictionary *)userInfo forObject:(NSObject *)object;
- (instancetype)initWithNotificationInfo:(NSDictionary *)userInfo forObject:(NSObject *)object;

@end
