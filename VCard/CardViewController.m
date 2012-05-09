//
//  CardViewController.m
//  VCard
//
//  Created by 海山 叶 on 12-4-14.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CardViewController.h"
#import "UIImageViewAddition.h"
#import "ResourceProvider.h"
#import "User.h"

#define MaxCardSize CGSizeMake(326,9999)
#define CardSizeUserAvatarHeight 25
#define CardSizeImageGap 22
#define CardSizeTextGap 20
#define CardSizeTopViewHeight 20
#define CardSizeBottomViewHeight 20
#define CardTextLineSpace 0

#define RegexColor [[UIColor colorWithRed:161.0/255 green:161.0/255 blue:161.0/255 alpha:1.0] CGColor]

static NSRegularExpression *__nameRegularExpression;
static inline NSRegularExpression * NameRegularExpression() {
    if (!__nameRegularExpression) {
        __nameRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"@([\u4e00-\u9fa5A-Za-z0-9_]*)?" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __nameRegularExpression;
}

static NSRegularExpression *__tagRegularExpression;
static inline NSRegularExpression * TagRegularExpression() {
    if (!__tagRegularExpression) {
        __tagRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"#.+?#" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __tagRegularExpression;
}

static NSRegularExpression *__urlRegularExpression;
static inline NSRegularExpression * UrlRegularExpression() {
    if (!__urlRegularExpression) {
        __urlRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"\\b(https?|ftp|file)://[-a-zA-Z0-9+&@#/%?=~_|!:,.;]*[-a-zA-Z0-9+&@#/%=~_|]" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __urlRegularExpression;
}


@interface CardViewController () {
    BOOL _doesImageExist;
    BOOL _isReposted;
    BOOL _alreadyConfigured;
    BOOL _imageAlreadyLoaded;
}

@end

@implementation CardViewController

@synthesize statusImageView = _statusImageView;
@synthesize repostUserAvatar = _repostUserAvatar;
@synthesize originalUserAvatar = _originalUserAvatar;
@synthesize favoredImageView = _favoredImageView;
@synthesize clipImageView = _clipImageView;
@synthesize commentButton = _commentButton;
@synthesize repostButton = _repostButton;
@synthesize originalUserNameButton = _originalUserNameButton;
@synthesize repostUserNameButton = _repostUserNameButton;
@synthesize statusInfoView = _statusInfoView;
@synthesize originalStatusLabel = _originalStatusLabel;
@synthesize repostStatusLabel = _repostStatusLabel;
@synthesize cardBackground = _cardBackground;
@synthesize repostCardBackground = _repostCardBackground;
@synthesize status = _status;
@synthesize imageHeight = _imageHeight;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _alreadyConfigured = NO;
        _imageAlreadyLoaded = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.originalStatusLabel.delegate = self;
    self.repostStatusLabel.delegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

#pragma mark - Functional Method

+ (CGFloat)heightForStatus:(Status*)status_ andImageHeight:(NSInteger)imageHeight_
{
    BOOL isReposted = status_.repostStatus != nil;
    Status *targetStatus = isReposted ? status_.repostStatus : status_;
    
    BOOL doesImageExist = targetStatus.bmiddlePicURL && ![targetStatus.bmiddlePicURL isEqualToString:@""];

    CGFloat height = CardSizeTopViewHeight + CardSizeBottomViewHeight + CardSizeUserAvatarHeight;
    height += [CardViewController heightForCellWithText:status_.text] + CardSizeTextGap;
        
    if (isReposted) {
        height +=  CardSizeTopViewHeight + CardSizeBottomViewHeight + CardSizeUserAvatarHeight - 8;
        height += [CardViewController heightForCellWithText:status_.repostStatus.text] + CardSizeTextGap;
    }
    
    if (doesImageExist) {
        height += imageHeight_ + CardSizeImageGap;
    }
    
    return height;
}

+ (CGFloat)heightForCellWithText:(NSString *)text {
    CGFloat height = 10.0f;
    height += ceilf([text sizeWithFont:[UIFont systemFontOfSize:17.0f] constrainedToSize:MaxCardSize lineBreakMode:UILineBreakModeWordWrap].height);
    CGFloat singleLineHeight = ceilf([@"测试单行高度" sizeWithFont:[UIFont systemFontOfSize:17.0f] constrainedToSize:MaxCardSize lineBreakMode:UILineBreakModeWordWrap].height);
    
    height += ceilf(height / singleLineHeight * CardTextLineSpace) - CardTextLineSpace;
        
    return height;
}

- (void)configureCardWithStatus:(Status*)status_ imageHeight:(CGFloat)imageHeight_
{
    if (_alreadyConfigured) {
        return;
    }
    
    _alreadyConfigured = YES;
    
    [self setUpStatus:status_];
    
    self.imageHeight = _doesImageExist ? imageHeight_ : 0.0;
    
    [self setUpStatusView];
    
    [self setUpRepostView];
    
    [self setUpStatusImageView];
    
    NSLog(@"%@", NSStringFromCGRect(self.view.frame));
    
}

- (void)setUpStatus:(Status*)status_
{
    self.status = status_;
    _isReposted = self.status.repostStatus != nil;
    
    Status *imageStatus = _isReposted ? self.status.repostStatus : self.status;
    _doesImageExist = imageStatus.bmiddlePicURL && ![imageStatus.bmiddlePicURL isEqualToString:@""];
    
}

- (void)setUpStatusImageView
{
    self.statusImageView.hidden = !_doesImageExist;
    self.clipImageView.hidden = !_doesImageExist;
    
    if (_doesImageExist) {
        
        CGRect frame = self.statusImageView.frame;
        frame.origin = CGPointMake(-4.0, 13.0);
        frame.size = CGSizeMake(StatusImageWidth, 200);
        
        self.statusImageView.frame = frame;
        
        [self.statusImageView resetHeight:self.imageHeight];
        
        [self.statusImageView clearCurrentImage];
    }
}

- (void)loadImage
{
    if (_doesImageExist && !_imageAlreadyLoaded) {
        
        _imageAlreadyLoaded = YES;
        
        Status *targetStatus = _isReposted ? self.status.repostStatus : self.status;
        
        [self.statusImageView loadTweetImageFromURL:targetStatus.bmiddlePicURL 
                                         completion:nil];
    }
}

- (void)prepareForReuse
{
    _alreadyConfigured = NO;
    _imageAlreadyLoaded = NO;
}

- (void)setUpStatusView
{
    self.favoredImageView.hidden = ![self.status.favorited boolValue];
    
    CGFloat originY = _doesImageExist ? self.imageHeight + 30 : 20;
    Status *targetStatus = _isReposted ? self.status.repostStatus : self.status;

    [self setStatusTextLabel:self.originalStatusLabel withText:targetStatus.text];
//    [self.originalUserAvatar loadImageFromURL:targetStatus.author.profileImageURL completion:nil];
    [self.originalUserNameButton setTitle:targetStatus.author.screenName forState:UIControlStateNormal];
    
//    CGFloat statusViewHeight = self.originalStatusLabel.frame.size.height + 90;
    
    CGFloat statusViewHeight = CardSizeTopViewHeight + CardSizeBottomViewHeight +
                            CardSizeUserAvatarHeight + CardSizeTextGap + 
                            self.originalStatusLabel.frame.size.height;
    if (_doesImageExist) {
        statusViewHeight += CardSizeImageGap;
    }
    
    CGRect statusInfoFrame;
    statusInfoFrame.origin = CGPointMake(0.0, originY);
    statusInfoFrame.size = CGSizeMake(self.view.frame.size.width, statusViewHeight);
    self.statusInfoView.frame = statusInfoFrame;
    
    [self.cardBackground resetHeight:self.imageHeight + statusViewHeight];
}

- (void)setUpRepostView
{
    self.repostCardBackground.hidden = !_isReposted;
    if (_isReposted) {
        self.repostCardBackground.hidden = NO;
        
        Status *targetStatus = self.status;
        
        [self setStatusTextLabel:self.repostStatusLabel withText:targetStatus.text];
//        [self.repostUserAvatar loadImageFromURL:targetStatus.author.profileImageURL completion:nil];
        [self.repostUserNameButton setTitle:targetStatus.author.screenName forState:UIControlStateNormal];
        
        CGRect bgFrame = self.repostCardBackground.frame;
        bgFrame.origin.x = self.cardBackground.frame.origin.x;
        bgFrame.origin.y = self.cardBackground.frame.origin.y + self.cardBackground.frame.size.height - 8;
  
        self.repostCardBackground.frame = bgFrame;
        
        CGFloat repostStatusViewHeight = CardSizeTopViewHeight + CardSizeBottomViewHeight +
                                        CardSizeUserAvatarHeight + CardSizeTextGap + 
                                        self.repostStatusLabel.frame.size.height;
        
        [self.repostCardBackground resetHeight:repostStatusViewHeight];

    }
}

- (void)setStatusTextLabel:(TTTAttributedLabel*)label withText:(NSString*)string
{
    CGRect frame = label.frame;
    frame.size.height = [CardViewController heightForCellWithText:string];
    label.frame = frame;
    
    label.font = [UIFont systemFontOfSize:17.0f];
    label.textColor = [UIColor colorWithRed:49.0/255 green:42.0/255 blue:37.0/255 alpha:1.0];
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.numberOfLines = 0;
    label.leading = CardTextLineSpace;
    
    label.highlightedTextColor = [UIColor whiteColor];
    label.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    
    [self setSummaryText:string toLabel:label];
}

- (void)setSummaryText:(NSString *)text toLabel:(TTTAttributedLabel*)label{
    
    [label setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        NSRange stringRange = NSMakeRange(0, [mutableAttributedString length]);

        NSRegularExpression *regexp = NameRegularExpression();
        
        [regexp enumerateMatchesInString:[mutableAttributedString string] options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            [self configureFontForAttributedString:mutableAttributedString withRange:result.range];
        }];
        
        regexp = TagRegularExpression();
        [regexp enumerateMatchesInString:[mutableAttributedString string] options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            [self configureFontForAttributedString:mutableAttributedString withRange:result.range];
        }];
        
        regexp = UrlRegularExpression();
        [regexp enumerateMatchesInString:[mutableAttributedString string] options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            [self configureFontForAttributedString:mutableAttributedString withRange:result.range];
        }];
        
        return mutableAttributedString;
    }];
    
    NSRegularExpression *regexp = NameRegularExpression();
    NSRange linkRange = [regexp rangeOfFirstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://en.wikipedia.org/wiki/"]];
    [label addLinkToURL:url withRange:linkRange];
}

- (void)configureFontForAttributedString:(NSMutableAttributedString *)mutableAttributedString withRange:(NSRange)stringRange
{
    CTFontRef systemFont = [ResourceProvider regexFont];
    if (systemFont) {
        [mutableAttributedString removeAttribute:(NSString *)kCTFontAttributeName range:stringRange];
        [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)systemFont range:stringRange];
        
        [mutableAttributedString removeAttribute:(NSString *)kCTForegroundColorAttributeName range:stringRange];
        [mutableAttributedString addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)RegexColor range:stringRange];
        
    }
}


@end
