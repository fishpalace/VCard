//
//  PostRepostCommentViewController.h
//  VCard
//
//  Created by 紫川 王 on 12-6-21.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PostViewController.h"

@interface PostRepostCommentViewController : PostViewController

- (id)initWithWeiboID:(NSString *)weiboID
              replyID:(NSString *)replyID
       weiboOwnerName:(NSString *)ownerName
          contentText:(NSString *)content;

@end
