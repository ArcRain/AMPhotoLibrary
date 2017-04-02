//
//  AMPhotoAlbum.h
//  AMPhotoLibrary
//
//  Created by ArcRain on 9/28/14.
//  Copyright (c) 2014 Sora Yang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMAssetsFilter.h"

@protocol AMPhotoAlbum <NSObject>

@required

@property (nonatomic, readonly, strong) id wrappedInstance;
@property (nonatomic, readonly, assign) BOOL isUserLibrary;
@property (nonatomic, readonly, strong) NSString *title;
@property (nonatomic, readonly, assign) NSInteger numberOfAssets;
@property (nonatomic, readonly, strong) UIImage *posterImage;

@property (nonatomic, strong) AMAssetsFilter *assetsFilter;

- (void)changed:(id)afterChanges;
- (void)enumerateAssets:(AMPhotoManagerAssetEnumerationBlock)enumerationBlock resultBlock:(AMPhotoManagerResultBlock)resultBlock;

@end
