//
//  UIView+Addition.h
//  WeTongji
//
//  Created by 紫川 王 on 12-4-10.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//



@interface UIView (Addition)

- (void)fadeIn;

- (void)fadeOut;

- (void)fadeInWithCompletion:(void (^)(void))completion;

- (void)fadeOutWithCompletion:(void (^)(void))completion;

- (void)transitionFadeIn;

- (void)transitionFadeOut;

@end
