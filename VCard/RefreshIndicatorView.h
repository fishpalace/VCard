//
//  RefreshIndicatorView.h
//  VCard
//
//  Created by 海山 叶 on 12-5-25.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RefreshIndicatorView : UIView {
    UIImageView *_refreshCircleImageView;
    UIImageView *_refreshHoleImageView;
}

- (void)startLoadingAnimation;
- (void)stopLoadingAnimation;

@end
