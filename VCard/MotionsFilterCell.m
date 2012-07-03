//
//  MotionsFilterCell.m
//  WeTongji
//
//  Created by 紫川 王 on 12-5-10.
//  Copyright (c) 2012年 Tongji Apple Club. All rights reserved.
//

#import "MotionsFilterCell.h"

@implementation MotionsFilterCell

@synthesize thumbnailImageView = _thumbnailImageView;
@synthesize activityIndicator = _activityIndicator;

- (void)awakeFromNib {
    [self.activityIndicator startAnimating];
}

- (void)setThumbnailImage:(UIImage *)image {
    if(image) {
        self.thumbnailImageView.image = image;
        self.activityIndicator.hidden = YES;
        [self.activityIndicator stopAnimating];
    }
}

- (void)loadThumbnailImage:(UIImage *)image
            withFilterInfo:(MotionsFilterInfo *)info
                completion:(void (^)(void))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *filteredImage = [info processImage:image];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setThumbnailImage:filteredImage];
            if(completion)
                completion();
        });  
    });
}

@end
