//
//  AMPHPhotoLibrary.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMPhotoManager.h"

@interface AMPHPhotoLibrary : NSObject <AMPhotoManager>

+ (id<AMPhotoManager>)sharedPhotoManager;

@end
