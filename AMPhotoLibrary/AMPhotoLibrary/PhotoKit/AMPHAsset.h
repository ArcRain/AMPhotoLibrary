//
//  AMPHAsset.h
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMPhotoAsset.h"

@interface AMPHAsset : NSObject <AMPhotoAsset>

+ (instancetype)photoAssetWithPHAsset:(PHAsset *)asset;
- (instancetype)initWithPHAsset:(PHAsset *)asset;

@end
