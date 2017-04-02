//
//  AMALAssetsLibrary.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import "AMPhotoManager.h"

@interface AMALAssetsLibrary : NSObject <AMPhotoManager>

+ (id<AMPhotoManager>)sharedPhotoManager;

@end
