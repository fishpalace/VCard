//
//  CardViewController.h
//  VCard
//
//  Created by 海山 叶 on 12-4-14.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataViewController.h"
#import "BaseCardBackgroundView.h"
#import "CardImageView.h"
#import "TTTAttributedLabel.h"
#import "UserAvatarImageView.h"
#import "Status.h"
#import "PostViewController.h"
#import <MessageUI/MessageUI.h>
#import "ActionPopoverViewController.h"

#define CardSizeUserAvatarHeight 25
#define CardSizeImageGap 22
#define CardSizeTextGap 20
#define CardSizeTopViewHeight 20
#define CardSizeBottomViewHeight 20
#define CardSizeRepostHeightOffset -8
#define CardTextLineSpace 8
#define CardTailHeight 24
#define CardTailOffset -55
#define CardSourceTagHeight 22
#define kCardGapOffset          8.0
#define MaxCardSize CGSizeMake(326,9999)

@protocol CardViewControllerDelegate <NSObject>

- (void)didChangeImageScale:(CGFloat)scale;
- (void)didReturnImageView;
- (void)willReturnImageView;
- (void)enterDetailedImageViewMode;
- (void)imageViewTapped;

@end

@interface CardViewController : CoreDataViewController <TTTAttributedLabelDelegate, PostViewControllerDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, ActionPopoverViewControllerDelegate> {
    
    NSInteger _imageHeight;
}

@property (nonatomic, weak) IBOutlet CardImageView *statusImageView;
@property (nonatomic, weak) IBOutlet UserAvatarImageView *repostUserAvatar;
@property (nonatomic, weak) IBOutlet UserAvatarImageView *originalUserAvatar;
@property (nonatomic, weak) IBOutlet UIImageView *favoredImageView;
@property (nonatomic, weak) IBOutlet UIImageView *clipImageView;
@property (nonatomic, weak) IBOutlet UIImageView *locationPinImageView;

@property (nonatomic, weak) IBOutlet UILabel *locationLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeStampLabel;
@property (nonatomic, weak) IBOutlet UILabel *deviceLabel;

@property (nonatomic, weak) IBOutlet UIButton *commentButton;
@property (nonatomic, weak) IBOutlet UIButton *originalCommentButton;
@property (nonatomic, weak) IBOutlet UIButton *repostButton;
@property (nonatomic, weak) IBOutlet UIButton *originalUserNameButton;
@property (nonatomic, weak) IBOutlet UIButton *repostUserNameButton;
@property (nonatomic, weak) IBOutlet UILabel *originalUserNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *repostUserNameLabel;

@property (nonatomic, weak) IBOutlet UIView *statusInfoView;
@property (nonatomic, weak) IBOutlet UIView *repostStatusInfoView;
@property (nonatomic, weak) IBOutlet TTTAttributedLabel *originalStatusLabel;
@property (nonatomic, weak) IBOutlet TTTAttributedLabel *repostStatusLabel;
@property (nonatomic, weak) IBOutlet BaseCardBackgroundView *cardBackground;
@property (nonatomic, weak) IBOutlet BaseCardBackgroundView *repostCardBackground;
@property (nonatomic, weak) Status *status;
@property (nonatomic, assign) NSInteger imageHeight;
@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, assign) BOOL isReposted;
@property (nonatomic, assign) BOOL isWaterflowCard;
@property (nonatomic, assign) BOOL mustShowPic;

@property (nonatomic, weak) id<CardViewControllerDelegate> delegate;

@property (nonatomic, strong) ActionPopoverViewController *actionPopoverViewController;

- (IBAction)nameButtonClicked:(id)sender;
- (IBAction)didClickCommentButton:(UIButton *)sender;
- (IBAction)didClickRepostButton:(UIButton *)sender;
- (IBAction)didClickOriginalCommentButton:(UIButton *)sender;

+ (CGFloat)heightForStatus:(Status *)status_ andImageHeight:(NSInteger)imageHeight_ timeStampEnabled:(BOOL)timeStampEnabled picEnabled:(BOOL)picEnabled;
+ (CGFloat)heightForTextContent:(NSString *)text;

- (void)configureCardWithStatus:(Status*)status_
                    imageHeight:(CGFloat)imageHeight_
                      pageIndex:(NSInteger)pageIndex_
                    currentUser:(User *)user
             coreDataIdentifier:(NSString *)identifier;

- (void)loadImage;
- (void)prepareForReuse;
- (void)returnToInitialImageView;
- (void)handleRotationGesture:(UIRotationGestureRecognizer *)sender;
- (void)resetFailedImageView;
- (void)recognizerLinkType:(NSString *)url;

@end
