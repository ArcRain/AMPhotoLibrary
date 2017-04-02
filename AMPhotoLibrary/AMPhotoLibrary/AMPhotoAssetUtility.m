//
//  AMPhotoAssetUtility.m
//  AMPhotoLibrary
//
//  Created by Sora Yang on 9/15/16.
//  Copyright © 2016 arcrain. All rights reserved.
//

#import "AMPhotoAssetUtility.h"

@implementation AMPhotoAssetUtility

+ (void)fetchAsset:(id<AMPhotoAsset>)asset rawData:(void(^)(NSData *rawData, AVPlayerItem *playerItem))resultBlock {
    [[asset class] fetchAsset:asset rawData:resultBlock];
}

+ (NSArray *)fetchPlayerItemURLs:(AVPlayerItem *)playerItem {
    AVAsset *videoAsset = playerItem.asset;
    NSMutableArray *URLs = [NSMutableArray array];
    if ([videoAsset isKindOfClass:[AVURLAsset class]]) {
        AVURLAsset *urlAsset = (AVURLAsset *)videoAsset;
        [URLs addObject: urlAsset.URL];
    }
    else if ([videoAsset isKindOfClass:[AVComposition class]]) {
        AVComposition *composition = (AVComposition *)videoAsset;
        AVCompositionTrack *videoTrack = nil;
        for (AVCompositionTrack *track in composition.tracks) {
            if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
                videoTrack = track;
                break;
            }
        }
        if (nil != videoTrack) {
            NSArray *segments = videoTrack.segments;
            for (AVCompositionTrackSegment *segment in segments) {
                if (NSNotFound == [URLs indexOfObject:segment.sourceURL]) {
                    [URLs addObject: segment.sourceURL];
                }
            }
        }
    }
    return URLs;
}

+ (void)fetchAsset:(id<AMPhotoAsset>)asset withImageType:(AMAssetImageType)imageType imageResult:(void(^)(UIImage *image))resultBlock {
    [[asset class] fetchAsset:asset withImageType:imageType imageResult:resultBlock];
}

@end
