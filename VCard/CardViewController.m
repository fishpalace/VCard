//
//  CardViewController.m
//  VCard
//
//  Created by 海山 叶 on 12-4-14.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CardViewController.h"
#import "UIImageView+Addition.h"
#import "UIApplication+Addition.h"
#import "NSDateAddition.h"
#import "ResourceProvider.h"
#import "User.h"
#import "Comment.h"
#import "WBClient.h"
#import "UIApplication+Addition.h"
#import "UIView+Resize.h"
#import "EmoticonsInfoReader.h"
#import "InnerBrowserViewController.h"

#define MaxCardSize CGSizeMake(326,9999)

#define kActionSheetRepostIndex     0
#define kActionSheetFavorIndex      1
#define kActionSheetViewRepostIndex 2
#define kActionSheetViewCopyIndex   3
#define kActionSheetShareIndex      4
#define kActionSheetDeleteIndex     5

#define RegexColor [[UIColor colorWithRed:161.0/255 green:161.0/255 blue:161.0/255 alpha:1.0] CGColor]

static NSRegularExpression *__nameRegularExpression;
static inline NSRegularExpression * NameRegularExpression() {
    if (!__nameRegularExpression) {
        __nameRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"@[[a-z][A-Z][0-9][\\u4E00-\\u9FA5]-_]*" options:NSRegularExpressionCaseInsensitive error:nil];
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
        __urlRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"https?://[[a-z][A-Z][0-9]\?/%&=.]+" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __urlRegularExpression;
}

static NSRegularExpression *__emotionRegularExpression;
static inline NSRegularExpression * EmotionRegularExpression() {
    if (!__emotionRegularExpression) {
        __emotionRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"\\[[[\\u4E00-\\u9FA5][a-z]]*\\]" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __emotionRegularExpression;
}

static NSRegularExpression *__emotionIDRegularExpression;
static inline NSRegularExpression * EmotionIDRegularExpression() {
    if (!__emotionIDRegularExpression) {
        __emotionIDRegularExpression = [[NSRegularExpression alloc] initWithPattern:@" \\[[[a-e][0-9] ]*\\] " options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __emotionIDRegularExpression;
}


@interface CardViewController () {
    BOOL _doesImageExist;
    BOOL _alreadyConfigured;
    BOOL _imageAlreadyLoaded;
    CGFloat _scale;
    CGFloat _lastScale;
    CGFloat _currentScale;
    CGPoint _lastPoint;
    UIPinchGestureRecognizer *_pinchGestureRecognizer;
    UIRotationGestureRecognizer *_rotationGestureRecognizer;
    UITapGestureRecognizer *_tapGestureRecognizer;
}

@end

@implementation CardViewController

@synthesize statusImageView = _statusImageView;
@synthesize repostUserAvatar = _repostUserAvatar;
@synthesize originalUserAvatar = _originalUserAvatar;
@synthesize favoredImageView = _favoredImageView;
@synthesize clipImageView = _clipImageView;
@synthesize locationPinImageView = _locationPinImageView;
@synthesize locationLabel = _locationLabel;
@synthesize timeStampLabel = _timeStampLabel;
@synthesize commentButton = _commentButton;
@synthesize repostButton = _repostButton;
@synthesize originalUserNameButton = _originalUserNameButton;
@synthesize repostUserNameButton = _repostUserNameButton;
@synthesize statusInfoView = _statusInfoView;
@synthesize repostStatusInfoView = _repostStatusInfoView;
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
    
    self.statusInfoView.clipsToBounds = NO;
    self.repostStatusInfoView.clipsToBounds = NO;
    
    self.locationLabel.hidden = YES;
    self.locationPinImageView.hidden = YES;
    self.clipImageView.layer.anchorPoint = CGPointMake(0.9, 0.05);
    [self.clipImageView resetOrigin:CGPointMake(300.0, -4.0)];
    
    self.repostUserNameButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    UITapGestureRecognizer *originalTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewUserInfo)];
    [self.originalUserAvatar addGestureRecognizer:originalTapGesture];
    
    UITapGestureRecognizer *repostTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewUserInfo)];
    [self.originalUserAvatar addGestureRecognizer:repostTapGesture];
    
    _rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotationGesture:)];
    _rotationGestureRecognizer.delegate = self;
    [self.statusImageView addGestureRecognizer:_rotationGestureRecognizer];
    
    _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    _pinchGestureRecognizer.delegate = self;
//    _pinchGestureRecognizer.delaysTouchesEnded = YES;
    [self.statusImageView addGestureRecognizer:_pinchGestureRecognizer];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    _tapGestureRecognizer.numberOfTouchesRequired = 1;
    _tapGestureRecognizer.delegate = self;
    [self.statusImageView addGestureRecognizer:_tapGestureRecognizer];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(recoverFromPause)
                   name:UIApplicationDidBecomeActiveNotification
                 object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

#pragma mark - Functional Method

+ (CGFloat)heightForStatus:(Status *)status_ andImageHeight:(NSInteger)imageHeight_
{
    BOOL isReposted = status_.repostStatus != nil;
    BOOL hasCardTail = [status_ hasLocationInfo] || YES;
    Status *targetStatus = isReposted ? status_.repostStatus : status_;
    
    BOOL doesImageExist = targetStatus.bmiddlePicURL && ![targetStatus.bmiddlePicURL isEqualToString:@""];

    CGFloat height = CardSizeTopViewHeight + CardSizeBottomViewHeight + CardSizeUserAvatarHeight;
    height += [CardViewController heightForCellWithText:status_.text] + CardSizeTextGap;
        
    if (isReposted) {
        height +=  CardSizeTopViewHeight + CardSizeBottomViewHeight + CardSizeUserAvatarHeight + CardSizeRepostHeightOffset;
        height += [CardViewController heightForCellWithText:status_.repostStatus.text] + CardSizeTextGap;
    }
    
    if (doesImageExist) {
        height += imageHeight_ + CardSizeImageGap;
    }
    
    if (hasCardTail) {
        height += CardTailHeight;
    }
    
    return height;
}

+ (CGFloat)heightForTextContent:(NSString *)text
{
    CGFloat height = 0.0;
    height +=  CardSizeTopViewHeight + CardSizeBottomViewHeight + CardSizeUserAvatarHeight + CardSizeRepostHeightOffset;
    height += [CardViewController heightForCellWithText:text] + CardSizeTextGap + 24.0;
    
    return height;
}

+ (CGFloat)heightForCellWithText:(NSString *)text {
    CGFloat height = 10.0f;
    height += ceilf([text sizeWithFont:[UIFont systemFontOfSize:17.0f] constrainedToSize:MaxCardSize lineBreakMode:UILineBreakModeWordWrap].height);
    CGFloat singleLineHeight = ceilf([@"测试单行高度" sizeWithFont:[UIFont systemFontOfSize:17.0f] constrainedToSize:MaxCardSize lineBreakMode:UILineBreakModeWordWrap].height);
    
    height += ceilf(height / singleLineHeight * CardTextLineSpace);
        
    return height;
}

- (void)configureCardWithStatus:(Status*)status_ imageHeight:(CGFloat)imageHeight_ pageIndex:(NSInteger)pageIndex_ currentUser:(User *)user
{
    if (_alreadyConfigured) {
        return;
    }
    
    _alreadyConfigured = YES;
    _imageViewMode = CastViewImageViewModeNormal;
    _pageIndex = pageIndex_;
    
    [self setUpStatus:status_];
    
    self.imageHeight = _doesImageExist ? imageHeight_ : 0.0;
    
    [self setUpStatusView];
    
    [self setUpRepostView];
    
    [self setUpStatusImageView];
    
    [self setUpButtonPosition];
    
    [self setUpCardTail];
        
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
        
        NSString *imageURL = [UIApplication isRetinaDisplayiPad] ? targetStatus.originalPicURL : targetStatus.bmiddlePicURL;
        
        [self.statusImageView loadImageFromURL:imageURL completion:nil];
    }
}

- (void)prepareForReuse
{
    _alreadyConfigured = NO;
    _imageAlreadyLoaded = NO;
    
    self.locationPinImageView.hidden = YES;
    self.locationLabel.hidden = YES;
    self.locationLabel.text = @"";
    
    [self.originalUserAvatar reset];
    [self.repostUserAvatar reset];
    [self.statusImageView reset];
}

- (void)setUpStatusView
{
    self.favoredImageView.hidden = ![self.status.favorited boolValue];
    
    CGFloat originY = _doesImageExist ? self.imageHeight + 30 : 20;
    Status *targetStatus = _isReposted ? self.status.repostStatus : self.status;
    
    [CardViewController setStatusTextLabel:self.originalStatusLabel withText:targetStatus.text];
    
    [self.originalUserAvatar loadImageFromURL:targetStatus.author.profileImageURL completion:nil];
    [self.originalUserAvatar setVerifiedType:[targetStatus.author verifiedTypeOfUser]];
    
    [self.originalUserNameLabel setText:targetStatus.author.screenName];
    
    //Save the screen name
    [self.originalUserNameButton setTitle:targetStatus.author.screenName forState:UIControlStateDisabled];
        
    CGFloat statusViewHeight = CardSizeTopViewHeight + CardSizeBottomViewHeight +
                            CardSizeUserAvatarHeight + CardSizeTextGap + 
                            self.originalStatusLabel.frame.size.height;
    if (_doesImageExist) {
        statusViewHeight += CardSizeImageGap;
    }
    
    if (!_isReposted) {
        statusViewHeight += CardTailHeight;
    }
    
    [self.statusInfoView resetFrameWithOrigin:CGPointMake(0.0, originY) 
                                         size:CGSizeMake(self.view.frame.size.width, statusViewHeight)];
    
    [self.cardBackground resetHeight:self.imageHeight + statusViewHeight];
    
}

- (void)setUpRepostView
{
    self.repostCardBackground.hidden = !_isReposted;
    if (_isReposted) {
        self.repostCardBackground.hidden = NO;
        
        Status *targetStatus = self.status;
        
        [CardViewController setStatusTextLabel:self.repostStatusLabel withText:targetStatus.text];
        [self.repostUserAvatar loadImageFromURL:targetStatus.author.profileImageURL completion:nil];
        [self.repostUserAvatar setVerifiedType:[targetStatus.author verifiedTypeOfUser]];
        
        NSString *screenName = [NSString stringWithFormat:@"%@ 转发并评论了以上卡片", targetStatus.author.screenName];
        
        [self.repostUserNameLabel setText:screenName];
        
        //Save the screen name
        [self.repostUserNameButton setTitle:targetStatus.author.screenName forState:UIControlStateDisabled];
        
        
        CGPoint newOrigin = CGPointMake(self.cardBackground.frame.origin.x, self.cardBackground.frame.origin.y + self.cardBackground.frame.size.height - 8);
        [self.repostCardBackground resetOrigin:newOrigin];
        
        CGFloat repostStatusViewHeight = CardSizeTopViewHeight + CardSizeBottomViewHeight +
                                        CardSizeUserAvatarHeight + CardSizeTextGap + 
                                        self.repostStatusLabel.frame.size.height;
        
        repostStatusViewHeight += CardTailHeight;
        
        [self.repostCardBackground resetHeight:repostStatusViewHeight];
        [self.repostStatusInfoView resetHeight:repostStatusViewHeight];

    }
}

- (void)setUpButtonPosition
{
    CGPoint origin = _isReposted ? self.repostCardBackground.frame.origin : self.statusInfoView.frame.origin;
    CGFloat offset = _isReposted ? 7.0 : -8.0;
    
    [self.repostButton resetOriginY:origin.y + offset];
    [self.commentButton resetOriginY:origin.y + offset];
    
}

- (void)setUpCardTail
{
    CGFloat cardTailOriginY = self.view.frame.size.height + CardTailOffset;
    
    [self.locationPinImageView resetOriginY:cardTailOriginY + 2];
    [self.locationLabel resetOriginY:cardTailOriginY];
    [self.timeStampLabel resetOriginY:cardTailOriginY];

    [self.timeStampLabel setText:[self.status.createdAt stringRepresentation]];
    
    [self setUpLocationInfo];
}

- (void)setUpLocationInfo
{
    if ([self.status locationInfoAlreadyLoaded]) {
        [self showLocationInfo];
    }
    
    if ([self.status hasLocationInfo]) {
        
        WBClient *client = [WBClient client];
        [client setCompletionBlock:^(WBClient *client) {
            if (!client.hasError) {
                
                NSString *locationString;
                NSArray* array = (NSArray*)client.responseJSONObject;
                if (array.count > 0) {
                    NSDictionary *dic = (NSDictionary *)[array objectAtIndex:0];
                    locationString = [NSString stringWithFormat:@"在 %@%@%@", [dic objectForKey:@"city_name"], [dic objectForKey:@"district_name"], [dic objectForKey:@"name"]];
                }
                
                if ([self.status.statusID isEqualToString:_previousStatus.statusID]) {
                    self.status.location = locationString;
                } else {
                    if (_previousStatus) {
                        _previousStatus.location = locationString;
                    }
                }
                
                [self showLocationInfo];
            }
        }];
        float lat = [self.status.lat floatValue];
        float lon = [self.status.lon floatValue];
        
        _previousStatus = self.status;
        [client getAddressFromGeoWithCoordinate:[[NSString alloc] initWithFormat:@"%f,%f", lon, lat]];
    }
}

- (void)showLocationInfo
{
    self.locationPinImageView.hidden = NO;
    self.locationLabel.hidden = NO;
    self.locationLabel.text = self.status.location;
}

+ (void)setStatusTextLabel:(TTTAttributedLabel*)label withText:(NSString*)string
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

+ (void)setSummaryText:(NSString *)originalText toLabel:(TTTAttributedLabel*)label
{
    NSString *text = originalText;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    NSRange stringRange = NSMakeRange(0, [text length]);
    NSRegularExpression *regexp = EmotionRegularExpression();
    [regexp enumerateMatchesInString:text options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange range = result.range;
        if (range.length != 1) {
            NSString *string = [text substringWithRange:range];
            [array addObject:string];
        }
    }];
    
    for (NSString *ketString in array) {
        NSString *key = [ketString substringWithRange:NSMakeRange(1, ketString.length - 2)];
        EmoticonsInfo *info = [[EmoticonsInfoReader sharedReader] emoticonsInfoForKey:key];
        if (info) {
            NSString *string = [NSString stringWithFormat:@" %@ ", info.emoticonIdentifier];
            text = [text stringByReplacingOccurrencesOfString:ketString withString:string];
        }
    }
    
    stringRange = NSMakeRange(0, [text length]);
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
        
        regexp = EmotionIDRegularExpression();
        [regexp enumerateMatchesInString:[mutableAttributedString string] options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            [self configureEmotionsForAttributedString:mutableAttributedString withRange:result.range];
        }];
        
        return mutableAttributedString;
    }];
    
    regexp = NameRegularExpression();
    [regexp enumerateMatchesInString:text options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange range = result.range;
        if (range.length != 1) {
            range.location++;
            range.length--;
            NSString *string = [text substringWithRange:range];
            [label addLinkToPhoneNumber:string withRange:result.range];
        }
    }];
    
    regexp = TagRegularExpression();
    [regexp enumerateMatchesInString:text options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange range = result.range;
        if (range.length != 1) {
            range.location++;
            range.length -= 2;
            NSString *string = [text substringWithRange:range];
            [label addQuoteToString:string withRange:result.range];
        }
    }];
    
    regexp = UrlRegularExpression();
    [regexp enumerateMatchesInString:text options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange range = result.range;
        if (range.length != 1) {
            NSString *string = [text substringWithRange:range];
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@", string]];
            [label addLinkToURL:url withRange:result.range];
        }
    }];
    
    regexp = EmotionIDRegularExpression();
    [regexp enumerateMatchesInString:text options:0 range:stringRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange range = result.range;
        if (range.length != 1) {
            NSString *string = [text substringWithRange:range];
            EmoticonsInfo *info = [[EmoticonsInfoReader sharedReader] emoticonsInfoForIdentifier:string];
            if (info) {
                [label addEmotionToString:info.imageFileName withRange:range];
            }
        }
    }];
    
}

+ (void)configureFontForAttributedString:(NSMutableAttributedString *)mutableAttributedString withRange:(NSRange)stringRange
{
    CTFontRef systemFont = [ResourceProvider regexFont];
    if (systemFont) {
        [mutableAttributedString removeAttribute:(NSString *)kCTFontAttributeName range:stringRange];
        [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)systemFont range:stringRange];
        
        [mutableAttributedString removeAttribute:(NSString *)kCTForegroundColorAttributeName range:stringRange];
        [mutableAttributedString addAttribute:(NSString*)kCTForegroundColorAttributeName value:(id)RegexColor range:stringRange];
        
    }
}

+ (void)configureEmotionsForAttributedString:(NSMutableAttributedString *)mutableAttributedString withRange:(NSRange)stringRange
{
    UIFont *font = [UIFont boldSystemFontOfSize:8.0f];
    CTFontRef systemFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    [mutableAttributedString removeAttribute:(NSString *)kCTFontAttributeName range:stringRange];
    [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)systemFont range:stringRange];
}

#pragma mark - IBActions

- (IBAction)nameButtonClicked:(id)sender
{
    NSString *userName = [((UIButton *)sender) titleForState:UIControlStateDisabled];
    [self sendUserNameClickedNotificationWithName:userName];
}

- (IBAction)didClickCommentButton:(UIButton *)sender
{
    [self sendCommentButtonClickedNotification];
}

- (IBAction)didClickRepostButton:(UIButton *)sender
{
    NSString *favourTitle = self.status.favorited.boolValue ? @"取消收藏" : @"收藏";
    NSString *deleteTitle = [self.status.author isEqualToUser:self.currentUser] ? @"删除" : nil;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                              delegate:self 
                                     cancelButtonTitle:nil 
                                destructiveButtonTitle:nil
                                     otherButtonTitles:@"转发", favourTitle, @"查看转发", @"复制微博", @"邮件分享", deleteTitle, nil];
    actionSheet.destructiveButtonIndex = kActionSheetDeleteIndex;
    actionSheet.delegate = self;
    [actionSheet showFromRect:sender.bounds inView:sender animated:YES];
}

#pragma mark - TTTAttributedLabel Delegate
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)userName
{
    [self sendUserNameClickedNotificationWithName:userName];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithQuate:(NSString *)quate
{
    [self sendShowTopicNotification:quate];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    [InnerBrowserViewController loadLinkWithURL:url];
}


#pragma mark - Send Notification
- (void)sendUserNameClickedNotificationWithName:(NSString *)userName
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNameShouldShowUserByName object:[NSDictionary dictionaryWithObjectsAndKeys:userName, kNotificationObjectKeyUserName, [NSString stringWithFormat:@"%i", self.pageIndex], kNotificationObjectKeyIndex, nil]];
}

- (void)sendCommentButtonClickedNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNameShouldShowCommentList object:[NSDictionary dictionaryWithObjectsAndKeys:self.status, kNotificationObjectKeyStatus, [NSString stringWithFormat:@"%i", self.pageIndex], kNotificationObjectKeyIndex, nil]];
}

- (void)sendShowRepostListNotification
{
    Status *targetStatus = _isReposted ? self.status.repostStatus : self.status;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNameShouldShowRepostList object:[NSDictionary dictionaryWithObjectsAndKeys:targetStatus, kNotificationObjectKeyStatus, [NSString stringWithFormat:@"%i", self.pageIndex], kNotificationObjectKeyIndex, nil]];
}

- (void)sendShowTopicNotification:(NSString *)searchKey
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNameShouldShowTopic object:[NSDictionary dictionaryWithObjectsAndKeys:searchKey, kNotificationObjectKeySearchKey, [NSString stringWithFormat:@"%i", self.pageIndex], kNotificationObjectKeyIndex, nil]];
}

#pragma mark - PostViewController Delegate

- (void)postViewController:(PostViewController *)vc willPostMessage:(NSString *)message {
    [vc dismissViewUpwards];
}

- (void)postViewController:(PostViewController *)vc didPostMessage:(NSString *)message {
    
}

- (void)postViewController:(PostViewController *)vc didFailPostMessage:(NSString *)message {
    
}

- (void)postViewController:(PostViewController *)vc willDropMessage:(NSString *)message {
    if(vc.type == PostViewControllerTypeRepost)
        [vc dismissViewToRect:[self.view convertRect:self.repostButton.frame toView:[UIApplication sharedApplication].rootViewController.view]];
    else
        [vc dismissViewToRect:[self.view convertRect:self.commentButton.frame toView:[UIApplication sharedApplication].rootViewController.view]];
}

#pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {

    if(buttonIndex == kActionSheetRepostIndex) {
        [self repostStatus];
    } else if(buttonIndex == kActionSheetViewRepostIndex) {
        [self sendShowRepostListNotification];
    } else if(buttonIndex == kActionSheetFavorIndex) {
        //TODO:
    } else if(buttonIndex == kActionSheetShareIndex) {
        [self shareStatusByMail];
    } else if(buttonIndex == kActionSheetViewCopyIndex){
        [self copyStatus];
    } else if(buttonIndex == kActionSheetDeleteIndex){
        [self deleteStatus];
    }
}

#pragma mark - ActionSheet Operations

- (void)repostStatus
{
    NSString *targetUserName = self.status.author.screenName;
    NSString *targetStatusID = self.status.statusID;
    NSString *targetStatusContent = nil;
    if(self.status.repostStatus)
        targetStatusContent = self.status.text;
    CGRect frame = [self.view convertRect:self.repostButton.frame toView:[UIApplication sharedApplication].rootViewController.view];
    PostViewController *vc = [PostViewController getRepostViewControllerWithWeiboID:targetStatusID
                                                                     weiboOwnerName:targetUserName
                                                                            content:targetStatusContent
                                                                           delegate:self];
    [vc showViewFromRect:frame];
}

- (void)copyStatus
{
    NSString *statusText = [NSString stringWithFormat:@"%@", self.status.text];
    if (_isReposted) {
        statusText = [statusText stringByAppendingFormat:@":@%@:%@", self.status.repostStatus.author.screenName, self.status.repostStatus.text];
    }
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:statusText];
}

- (void)shareStatusByMail
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    picker.modalPresentationStyle = UIModalPresentationPageSheet;
    
    NSString *subject = [NSString stringWithFormat:@"分享一条来自新浪的微博，作者：%@", self.status.author.screenName];
    
    [picker setSubject:subject];
    
    NSString *emailBody = [NSString stringWithFormat:@"%@", self.status.text];
    if (_isReposted) {
        emailBody = [emailBody stringByAppendingFormat:@" %@", self.status.repostStatus.text];
    }
    [picker setMessageBody:emailBody isHTML:NO];
    
    if (_doesImageExist) {
        NSData *imageData = UIImageJPEGRepresentation(self.statusImageView.image, 0.8);
        [picker addAttachmentData:imageData mimeType:@"image/jpeg" fileName:NSLocalizedString(@"微博图片", nil)];
    }
    
    [[[UIApplication sharedApplication] rootViewController] presentModalViewController:picker animated:YES];
}


- (void)deleteStatus
{
    WBClient *client = [WBClient client];
    [client setCompletionBlock:^(WBClient *client) {
        if (!client.hasError) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNameShouldDeleteStatus object:self.status.statusID];
        } else {
            //TODO: Handle Error
        }
    }];
    
    [client deleteStatus:self.status.statusID];
}


#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController*)controller
		  didFinishWithResult:(MFMailComposeResult)result 
						error:(NSError*)error
{
	NSString *message = nil;
	switch (result)
	{
		case MFMailComposeResultSaved:
			message = NSLocalizedString(@"保存成功", nil);
            [[[UIApplication sharedApplication] rootViewController] dismissModalViewControllerAnimated:YES];
			break;
		case MFMailComposeResultSent:
			message = NSLocalizedString(@"发送成功", nil);
            [[[UIApplication sharedApplication] rootViewController] dismissModalViewControllerAnimated:YES];
			break;
		case MFMailComposeResultFailed:
			message = NSLocalizedString(@"发送失败", nil);
			break;
		default:
            [[[UIApplication sharedApplication] rootViewController] dismissModalViewControllerAnimated:YES];
			return;
	}
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:message 
														message:nil
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"确定", nil)
											  otherButtonTitles:nil];
	[alertView show];
}

#pragma mark - Handle Pinch Gesture
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // if the gesture recognizers are on different views, don't allow simultaneous recognition
    if (gestureRecognizer.view != otherGestureRecognizer.view)
        return NO;
    
    // if either of the gesture recognizers is the long press, don't allow simultaneous recognition
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] || [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
        return NO;
    
    return YES;
}

#pragma mark Pinch
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)sender
{
    [self recordPinchGestureInitialStatus:sender];
    
    [self handleImageViewPinchWithGesture:sender];
}

- (void)recordPinchGestureInitialStatus:(UIPinchGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        _lastScale = 1.0;
        _currentScale = 1.0;
        _scale = 1.0;
        _lastPoint = [sender locationInView:[UIApplication sharedApplication].rootViewController.view];
        
        [self.statusImageView resetCurrentScale];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
                
        if (_imageViewMode == CastViewImageViewModeNormal) {
            if (sender.velocity > 2.0) {
                [self willOpenDetailImageViewDirectly];
            } else {
                [self willOpenDetailImageView];
            }
            return;
        }
    }
}

- (void)handleImageViewPinchWithGesture:(UIPinchGestureRecognizer *)sender
{
    BOOL gestureEnd = [self checkAndHanlePinchGestureEnd:sender];
    
    if (!gestureEnd) {
        [self resetScaleWithPinchGesture:sender];
        
        [self resetPositionWithPinchGesture:sender];
        
        [self.statusImageView pinchResizeToScale:self.statusImageView.currentScale];
        
        if ([_delegate respondsToSelector:@selector(didChangeImageScale:)]) {
            [_delegate didChangeImageScale:sender.scale];
        }
    }
}

- (BOOL)checkAndHanlePinchGestureEnd:(UIPinchGestureRecognizer *)sender
{
    BOOL result = NO;
    if (sender.state == UIGestureRecognizerStateEnded || (sender.state == UIGestureRecognizerStateChanged && sender.numberOfTouches < 2) || sender.numberOfTouches > 2) {
        
        self.statusImageView.userInteractionEnabled = NO;
        _pinchGestureRecognizer.enabled = NO;
        _rotationGestureRecognizer.enabled = NO;
        
        BOOL shouldReturn = YES;
        
        shouldReturn = [self.statusImageView scaleOffset] < 0.2 && sender.velocity < 2;
        
        if (shouldReturn) {
            [self returnToInitialImageView];
        } else {
            if ([_delegate respondsToSelector:@selector(enterDetailedImageViewMode)]) {
                [_delegate enterDetailedImageViewMode];
            }
        }
        
        result = YES;
    }
    return result;
}

- (void)resetScaleWithPinchGesture:(UIPinchGestureRecognizer *)sender
{
    CGFloat scale = 1.0 - (_lastScale - sender.scale);
    [self.statusImageView setTransform:CGAffineTransformScale(self.statusImageView.transform, scale, scale)];
    self.statusImageView.currentScale += sender.scale - _lastScale;
    _lastScale = sender.scale;
}

- (void)resetPositionWithPinchGesture:(UIPinchGestureRecognizer *)sender
{
    CGPoint point = [sender locationInView:[UIApplication sharedApplication].rootViewController.view];
    
    if (point.x == 0.0 && point.y == 0.0) {
        return;
    }
    
    CGFloat deltaX = point.x - _lastPoint.x;
    CGFloat deltaY = point.y - _lastPoint.y;
        
    CGPoint _lastCenter = self.statusImageView.center;
    _lastCenter.x += deltaX;
    _lastCenter.y += deltaY;
    
    self.statusImageView.center = _lastCenter;
    _lastPoint = [sender locationInView:[UIApplication sharedApplication].rootViewController.view];
}

#pragma mark Rotation
- (void)handleRotationGesture:(UIRotationGestureRecognizer *)sender
{
    if (_imageViewMode == CastViewImageViewModeDetailedZooming || _imageViewMode == CastViewImageViewModeDetailedNormal) {
        return;
    }
    
    if ([sender state] == UIGestureRecognizerStateBegan) {
        if (_imageViewMode == CastViewImageViewModeNormal) {
            [self playClipLooseAnimation];
            [self willOpenDetailImageView];
        }
    }
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        sender.view.transform = CGAffineTransformRotate(sender.view.transform, sender.rotation);
        sender.rotation = 0;
    }
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    if (_imageViewMode == CastViewImageViewModeNormal) {
        [self willOpenDetailImageViewDirectly];
    } else if (_imageViewMode != CastViewImageViewModePinchingOut){
        if ([_delegate respondsToSelector:@selector(imageViewTapped)]) {
            [_delegate imageViewTapped];
        }
    }
}

- (void)returnToInitialImageView
{
    [UIView animateWithDuration:0.3 animations:^{
        [self.statusImageView playReturnAnimation];
        self.statusImageView.gifIcon.alpha = 1.0;
        [_delegate willReturnImageView];
    } completion:^(BOOL finished) {
        if ([_delegate respondsToSelector:@selector(didReturnImageView)]) {
            [_delegate didReturnImageView];
        }
        [self.statusImageView returnToInitialPosition];
        [self.cardBackground insertSubview:self.statusImageView belowSubview:self.clipImageView];
        [self playClipTightenAnimation];
        _imageViewMode = CastViewImageViewModeNormal;
        self.statusImageView.userInteractionEnabled = YES;
        _pinchGestureRecognizer.enabled = YES;
        _rotationGestureRecognizer.enabled = YES;
    }];
}

- (void)resetFailedImageView
{
    [UIView animateWithDuration:0.3 animations:^{
        self.statusImageView.transform = CGAffineTransformIdentity;
        [self.statusImageView playReturnAnimation];
        [self.statusImageView returnToInitialPosition];
        self.statusImageView.gifIcon.alpha = 1.0;
    }];
    [self playClipTightenAnimation];
    _imageViewMode = CastViewImageViewModeNormal;
    self.statusImageView.userInteractionEnabled = YES;
    _pinchGestureRecognizer.enabled = NO;
    _rotationGestureRecognizer.enabled = NO;
    _pinchGestureRecognizer.enabled = YES;
    _rotationGestureRecognizer.enabled = YES;
}

- (void)recoverFromPause
{
    if (_imageViewMode == CastViewImageViewModePinchingOut) {
        [self returnToInitialImageView];
    }
}

- (void)willOpenDetailImageViewDirectly
{
    _imageViewMode = CastViewImageViewModeDetailedNormal;
    [self sendShowDetailImageViewNotification];
    
}

- (void)willOpenDetailImageView
{
    _imageViewMode = CastViewImageViewModePinchingOut;
    [self sendShowDetailImageViewNotification];
}

- (void)sendShowDetailImageViewNotification
{
    self.statusImageView.gifIcon.alpha = 0.0;
    [self playClipLooseAnimation];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNameShouldShowDetailImageView object:[NSDictionary dictionaryWithObjectsAndKeys:self, kNotificationObjectKeyStatus,self.statusImageView, kNotificationObjectKeyImageView, nil]];
}

#pragma mark Adjust Clip Behavior

- (void)playClipLooseAnimation
{
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:0.0];
    rotationAnimation.toValue = [NSNumber numberWithFloat:0.7];
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    rotationAnimation.fillMode = kCAFillModeForwards;
    rotationAnimation.removedOnCompletion = NO;
    rotationAnimation.duration = 0.3;
    
    [self.clipImageView.layer removeAllAnimations];
    [self.clipImageView.layer addAnimation:rotationAnimation forKey:@"rotation"];
    
    CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOutAnimation.fromValue = [NSNumber numberWithFloat:1];
    fadeOutAnimation.toValue = [NSNumber numberWithFloat:0];
    fadeOutAnimation.duration = 0.3;
    fadeOutAnimation.removedOnCompletion = NO;
    
    [self.clipImageView.layer addAnimation:fadeOutAnimation forKey:@"opacity"];
    self.clipImageView.layer.opacity = 0;
}

- (void)playClipTightenAnimation
{
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:0.7];
    rotationAnimation.toValue = [NSNumber numberWithFloat:0.0];
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    rotationAnimation.fillMode = kCAFillModeForwards;
    rotationAnimation.removedOnCompletion = NO;
    rotationAnimation.duration = 0.3;
    
    [self.clipImageView.layer removeAllAnimations];
    [self.clipImageView.layer addAnimation:rotationAnimation forKey:@"rotation"];
    
    CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeOutAnimation.fromValue = [NSNumber numberWithFloat:0];
    fadeOutAnimation.toValue = [NSNumber numberWithFloat:1];
    fadeOutAnimation.duration = 0.3;
    fadeOutAnimation.removedOnCompletion = NO;
    
    [self.clipImageView.layer addAnimation:fadeOutAnimation forKey:@"opacity"];
    self.clipImageView.layer.opacity = 1;
}

@end
