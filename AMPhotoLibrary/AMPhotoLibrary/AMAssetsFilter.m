//
//  AMAssetsFilter.m
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import "AMAssetsFilter.h"

@interface AMAssetsFilter ()

@end

@implementation AMAssetsFilter

+ (AMAssetsFilter *)allAssets
{
    AMAssetsFilter *filter = [[AMAssetsFilter alloc] init];
    filter.includeImage = YES;
    filter.includeVideo = YES;
    filter.includeAudio = YES;
    return filter;
}

+ (AMAssetsFilter *)allImages
{
    AMAssetsFilter *filter = [[AMAssetsFilter alloc] init];
    filter.includeImage = YES;
    filter.includeVideo = NO;
    filter.includeAudio = NO;
    return filter;
}

+ (AMAssetsFilter *)allVideos
{
    AMAssetsFilter *filter = [[AMAssetsFilter alloc] init];
    filter.includeImage = NO;
    filter.includeVideo = YES;
    filter.includeAudio = NO;
    return filter;
}

+ (AMAssetsFilter *)allAudios
{
    AMAssetsFilter *filter = [[AMAssetsFilter alloc] init];
    filter.includeImage = NO;
    filter.includeVideo = NO;
    filter.includeAudio = YES;
    return filter;
}

- (BOOL)isEqual:(id)object
{
    AMAssetsFilter *filter = (AMAssetsFilter *)object;
    return (self.includeImage == filter.includeImage) && (self.includeVideo == filter.includeVideo) && (self.includeAudio == filter.includeAudio);
}

@end

