//
//  AMALAsset.h
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMPhotoAsset.h"

@interface AMALAsset : NSObject <AMPhotoAsset>

+ (instancetype)photoAssetWithALAsset:(ALAsset *)asset;
- (instancetype)initWithALAsset:(ALAsset *)asset;

@end
