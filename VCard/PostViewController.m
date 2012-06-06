//
//  PostViewController.m
//  VCard
//
//  Created by 紫川 王 on 12-5-26.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import "PostViewController.h"
#import "UIApplication+Addition.h"
#import "PostAtHintView.h"
#import "PostTopicHintView.h"
#import "EmoticonsViewController.h"
#import "UIView+Addition.h"
#import "WBClient.h"

#define WEIBO_TEXT_MAX_LENGTH   140
#define HINT_VIEW_OFFSET    CGSizeMake(-16, 27)
#define HINT_VIEW_ORIGIN_MIN_Y  108
#define HINT_VIEW_ORIGIN_MAX_Y  234
#define HINT_VIEW_BORDER_MAX_Y  (self.postView.frame.size.height - 10)
#define HINT_VIEW_BORDER_MAX_X  self.postView.frame.size.width

static NSString *weiboAtRegEx = @"[[a-z][A-Z][0-9][\\u4E00-\\u9FA5]-_\\s]*";
static NSString *weiboTopicRegEx = @"[[a-z][A-Z][0-9][\\u4E00-\\u9FA5]-_]*";

typedef enum {
    HintViewTypeNone,
    HintViewTypeAt,
    HintViewTypeTopic,
} HintViewType;

@interface PostViewController ()

@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, strong) PostHintView *currentHintView;
@property (nonatomic, readonly) CGPoint cursorPos;
@property (nonatomic, assign) NSRange currentHintStringRange;
@property (nonatomic, readonly) NSString *currentHintString;
@property (nonatomic, assign) HintViewType currentHintViewType;
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, strong) EmoticonsViewController *emoticonsViewController;

@end

@implementation PostViewController

@synthesize motionsImageView = _motionsImageView;
@synthesize textView = _textView;
@synthesize textCountLabel = _textCountLabel;
@synthesize postView = _postView;
@synthesize textContainerView = _textContainerView;
@synthesize navButton = _navButton;
@synthesize atButton = _atButton;
@synthesize emoticonsButton = _emoticonsButton;
@synthesize topicButton = _topicButton;
@synthesize navActivityView = _navActivityView;
@synthesize navLabel = _navLabel;
@synthesize functionLeftView = _functionLeftView;
@synthesize functionRightView = _functionRightView;

@synthesize keyboardHeight = _keyboardHeight;
@synthesize currentHintView = _currentHintView;
@synthesize currentHintStringRange = _currentHintStringRange;
@synthesize currentHintString = _currentHintString;
@synthesize currentHintViewType = _currentHintViewType;
@synthesize locationManager = locationManager;
@synthesize emoticonsViewController = _emoticonsViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self configureViewFrame];
    [self configureMotionsImageView];
    [self configureTextView];
    self.navActivityView.hidden = YES;
    self.navLabel.text = @"";
    _functionRightViewInitFrame = self.functionRightView.frame;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.motionsImageView = nil;
    self.textView = nil;
    self.textCountLabel = nil;
    self.postView = nil;
    self.textContainerView = nil;
    self.navButton = nil;
    self.atButton = nil;
    self.emoticonsButton = nil;
    self.topicButton = nil;
    self.navActivityView = nil;
    self.navLabel = nil;
    self.functionLeftView = nil;
    self.functionRightView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Notification handlers

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGRect keyboardBounds = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGFloat keyboardHeight;
    switch ([UIApplication sharedApplication].statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            keyboardHeight = keyboardBounds.size.height;
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            keyboardHeight = keyboardBounds.size.width;
            break;
    }
    
    CGSize screenSize = [UIApplication sharedApplication].screenSize;
    if(_keyboardHidden) {
        float animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        [UIView animateWithDuration:animationDuration animations:^{
            self.postView.center = CGPointMake(self.postView.center.x, (screenSize.height - keyboardHeight) / 2);
        } completion:^(BOOL finished) {
            _keyboardHidden = !finished;
        }];
    } else 
        self.postView.center = CGPointMake(self.postView.center.x, (screenSize.height - keyboardHeight) / 2);
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    float animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGSize screenSize = [UIApplication sharedApplication].screenSize;
    [UIView animateWithDuration:animationDuration animations:^{
        self.postView.center = CGPointMake(self.postView.center.x, screenSize.height / 2);
    } completion:^(BOOL finished) {
        _keyboardHidden = finished;
    }];
}

#pragma mark - Logic methods

- (EmoticonsViewController *)emoticonsViewController {
    if(!_emoticonsViewController) {
        _emoticonsViewController = [[EmoticonsViewController alloc] init];
    }
    return _emoticonsViewController;
}

- (NSString *)currentHintString {
    return [self.textView.text substringWithRange:self.currentHintStringRange];
}

- (int)weiboTextBackwardsCount:(NSString*)text
{
    int i, n = [text length],l = 0, a = 0, b = 0;
    unichar c;
    for(i = 0;i < n; i++) {
        c = [text characterAtIndex:i];
        if(isblank(c))
            b++;
        else if(isascii(c))
            a++;
        else
            l++;
    }
    int textLength = l + (int)floorf((float)(a + b) / 2.0f);
    return WEIBO_TEXT_MAX_LENGTH - textLength;
    
}

- (CGPoint)cursorPos {
    CGPoint cursorPos = CGPointZero;
    if(self.textView.selectedTextRange.empty && self.textView.selectedTextRange) {
        cursorPos = [self.textView caretRectForPosition:self.textView.selectedTextRange.start].origin;
        cursorPos.x += self.textContainerView.frame.origin.x + self.textView.frame.origin.x + HINT_VIEW_OFFSET.width;
        CGFloat textScrollViewOffsetY = self.textView.contentOffset.y;
        //NSLog(@"text scroll view offset y:%f", textScrollViewOffsetY);
        cursorPos.y += self.textContainerView.frame.origin.y + self.textView.frame.origin.y + HINT_VIEW_OFFSET.height - textScrollViewOffsetY;
    }
    return cursorPos;
}

- (BOOL)isAtHintStringValid {
    NSLog(@"is at (%@) valid?", self.currentHintString);
    NSRange range = [self.currentHintString rangeOfString:weiboAtRegEx options:NSRegularExpressionSearch];
    return range.length == self.currentHintString.length;
}

- (BOOL)isTopicHintStringValid {
    return YES; // no limit
    NSLog(@"is topic (%@) valid?", self.currentHintString);
    NSRange range = [self.currentHintString rangeOfString:weiboTopicRegEx options:NSRegularExpressionSearch];
    return range.length == self.currentHintString.length;
}

- (void)replaceHintWithResult:(NSString *)text {
    int location = self.currentHintStringRange.location;
    NSString *replaceText = text;
    if([self.currentHintView isMemberOfClass:[PostAtHintView class]]) {
        replaceText = [NSString stringWithFormat:@"%@ ", replaceText];
    } else if(_needFillPoundSign) {
        replaceText = [NSString stringWithFormat:@"%@#", replaceText];
    }
    
    UITextPosition *beginning = self.textView.beginningOfDocument;
    UITextPosition *start = [self.textView positionFromPosition:beginning offset:self.currentHintStringRange.location];
    UITextPosition *end = [self.textView positionFromPosition:start offset:self.currentHintStringRange.length];
    UITextRange *textRange = [self.textView textRangeFromPosition:start toPosition:end];
    [self.textView replaceRange:textRange withText:replaceText];
    
    NSRange range = NSMakeRange(location + text.length + 1, 0);
    self.textView.selectedRange = range;
    [self dismissHintView];
}

#pragma mark - UI methods

- (void)configureTextView {
    self.textView.text = @"";
    [self updateTextCount];
    [self.textView becomeFirstResponder];
}

- (void)configureViewFrame {
    CGRect frame = CGRectZero;
    frame.size = [UIApplication sharedApplication].screenSize;
    self.view.frame = frame;
}

- (void)configureMotionsImageView {
    self.motionsImageView.transform = CGAffineTransformMakeRotation(6 * M_PI / 180);
}

- (void)dismissView {
    [UIApplication dismissModalViewController];
    [self.textView resignFirstResponder];
}

- (void)updateTextCount {
    NSString *text = self.textView.text;
    self.textCountLabel.text = [NSString stringWithFormat:@"%d", [self weiboTextBackwardsCount:text]];
}

- (void)presentAtHintView {
    [self dismissHintView];
    CGPoint cursorPos = self.cursorPos;
    if(CGPointEqualToPoint(cursorPos, CGPointZero))
        return;
    PostAtHintView *atView = [[PostAtHintView alloc] initWithCursorPos:cursorPos];
    self.currentHintView = atView;
    self.currentHintView.delegate = self;
    [self checkCurrentHintViewFrame];
    [self.postView addSubview:atView];
}

- (void)presentTopicHintView {
    [self dismissHintView];
    CGPoint cursorPos = self.cursorPos;
    if(CGPointEqualToPoint(cursorPos, CGPointZero))
        return;
    PostTopicHintView *topicView = [[PostTopicHintView alloc] initWithCursorPos:cursorPos];
    self.currentHintView = topicView;
    self.currentHintView.delegate = self;
    [self checkCurrentHintViewFrame];
    [self.postView addSubview:topicView];
    [topicView updateHint:@""];
}

- (void)updateCurrentHintView {
    [self updateCurrentHintViewFrame];
    [self updateCurrentHintViewContent];
}

- (void)updateCurrentHintViewContent {
    if(!self.currentHintView)
        return;
    if([self.currentHintView isMemberOfClass:[PostAtHintView class]]) {
        if([self isAtHintStringValid])
            [self.currentHintView updateHint:self.currentHintString];
        else {
            NSLog(@"at hint not valid");
            [self dismissHintView]; 
        }
    } else if([self.currentHintView isMemberOfClass:[PostTopicHintView class]]) {
        if([self isTopicHintStringValid])
            [self.currentHintView updateHint:self.currentHintString];
        else {
            NSLog(@"topic hint not valid");
            [self dismissHintView]; 
        }    
    }
}

- (void)updateCurrentHintViewFrame {
    if(!self.currentHintView)
        return;
    CGPoint cursorPos = self.cursorPos;
    if(!CGPointEqualToPoint(cursorPos, CGPointZero)) {
        CGRect frame = self.currentHintView.frame;
        frame.origin = cursorPos;
        self.currentHintView.frame = frame;
        //NSLog(@"cursor pos:(%f, %f)", cursorPos.x, cursorPos.y);
        [self checkCurrentHintViewFrame];
    }
}

- (void)checkCurrentHintViewFrame {
    CGPoint pos = self.currentHintView.frame.origin;
    CGSize size = self.currentHintView.frame.size;
    
    pos.y = pos.y > HINT_VIEW_ORIGIN_MIN_Y ? pos.y : HINT_VIEW_ORIGIN_MIN_Y;
    pos.y = pos.y < HINT_VIEW_ORIGIN_MAX_Y ? pos.y : HINT_VIEW_ORIGIN_MAX_Y;
    pos.x = pos.x + size.width > HINT_VIEW_BORDER_MAX_X ? HINT_VIEW_BORDER_MAX_X - size.width : pos.x;
    
    self.currentHintView.frame = CGRectMake(pos.x, pos.y, size.width, size.height);
    self.currentHintView.maxViewHeight = HINT_VIEW_BORDER_MAX_Y - pos.y;
}

- (void)dismissHintView {
    NSLog(@"dismiss hint view");
    self.currentHintStringRange = NSMakeRange(0, 0);
    UIView *currentHintView = self.currentHintView;
    self.currentHintView = nil;
    [currentHintView fadeOutWithCompletion:^{
        [currentHintView removeFromSuperview];
    }];
    [self.atButton setSelected:NO];
    [self.topicButton setSelected:NO];
    _needFillPoundSign = NO;
}

- (void)showNavLocationLabel:(NSString *)place {
    self.navLabel.text = place;
    [self.navLabel sizeToFit];
    __block CGRect frame = self.navLabel.frame;
    CGFloat width = frame.size.width;
    frame.size.width = 0;
    self.navLabel.frame = frame;
    self.navButton.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.3f animations:^{
        frame.size.width = width;
        self.navLabel.frame = frame;
        
        CGRect rightFuncViewFrame = self.functionRightView.frame;
        rightFuncViewFrame.origin.x = _functionRightViewInitFrame.origin.x + width;
        self.functionRightView.frame = rightFuncViewFrame;
    } completion:^(BOOL finished) {
        self.navButton.userInteractionEnabled = YES;
    }];
}

- (void)hideNavLocationLabel {
    if(self.navLabel.text.length == 0)
        return;
    __block CGRect frame = self.navLabel.frame;
    self.navLabel.frame = frame;
    self.navButton.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.3f animations:^{
        frame.size.width = 0;
        self.navLabel.frame = frame;
        
        CGRect rightFuncViewFrame = self.functionRightView.frame;
        rightFuncViewFrame.origin.x = _functionRightViewInitFrame.origin.x;
        self.functionRightView.frame = rightFuncViewFrame;
    } completion:^(BOOL finished) {
        self.navLabel.text = @"";
        self.navButton.userInteractionEnabled = YES;
    }];
}

#pragma mark - IBActions

- (IBAction)didClickMotionsButton:(UIButton *)sender {
    MotionsViewController *vc = [[MotionsViewController alloc] init];
    vc.delegate = self;
    [[UIApplication sharedApplication].rootViewController presentModalViewController:vc animated:YES];
}

- (IBAction)didClickReturnButton:(UIButton *)sender {
    [self dismissView];
}

- (IBAction)didClickAtButton:(UIButton *)sender {
    BOOL select = !sender.isSelected;
    if(select) {
        [self.textView insertText:@"@"];
        [self presentAtHintView];
        NSInteger location = self.textView.selectedRange.location;
        NSRange range = NSMakeRange(location, 0);
        self.currentHintStringRange = range;
    } else {
        [self dismissHintView];
    }
    sender.selected = select;
}

- (IBAction)didClickTopicButton:(UIButton *)sender {
    BOOL select = !sender.isSelected;
    if(select) {
        [self.textView insertText:@"##"];
        [self presentTopicHintView];
        NSInteger location = self.textView.selectedRange.location;
        NSRange range = NSMakeRange(location - 1, 0);
        self.currentHintStringRange = range;
        self.textView.selectedRange = range;
        NSLog(@"hint range:(%d, %d)", self.currentHintStringRange.location, self.currentHintStringRange.length);
    } else {
        self.textView.selectedRange = NSMakeRange(self.textView.selectedRange.location + 1, 0);
        [self dismissHintView];
    }
    sender.selected = select;
}

- (IBAction)didClickEmoticonsButton:(UIButton *)sender {
    BOOL select = !sender.isSelected;
    if(select) {
        EmoticonsViewController *vc = self.emoticonsViewController;
        CGRect frame = vc.view.frame;
        frame.origin = self.cursorPos;
        vc.view.frame = frame;
        [self.postView addSubview:vc.view];
    } else {
        [self.emoticonsViewController.view fadeOutWithCompletion:^{
            [self.emoticonsViewController.view removeFromSuperview];
        }];
    }
    sender.selected = select;
}

- (IBAction)didClickNavButton:(UIButton *)sender {
    BOOL select = !sender.isSelected;
    if(select) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        [self.locationManager startUpdatingLocation];
        
        self.navButton.hidden = YES;
        self.navActivityView.hidden = NO;
        [self.navActivityView startAnimating];
    } else {
        _located = NO;
        [self hideNavLocationLabel];
    }
    
}

- (IBAction)didClickPostButton:(UIButton *)sender {
    sender.userInteractionEnabled = NO;
    WBClient *client = [WBClient client];
    [client setCompletionBlock:^(WBClient *client) {
        NSLog(@"post finish:%@", client.responseJSONObject);
        [sender setTitle:@"发表" forState:UIControlStateNormal];
        if(!client.hasError) {
            NSLog(@"post succeeded");
        } else {
            NSLog(@"post failed");
        }
    }];
    if(!_located)
        [client sendWeiBoWithText:self.textView.text image:self.motionsImageView.image];
    else {
        NSString *lat = [NSString stringWithFormat:@"%f", _location2D.latitude];
        NSString *lon = [NSString stringWithFormat:@"%f", _location2D.longitude];
        [client sendWeiBoWithText:self.textView.text image:self.motionsImageView.image longtitude:lon latitude:lat];
    }
    [self dismissView];
}

#pragma mark - MotionsViewController delegate

- (void)motionViewControllerDidCancel {
    [[UIApplication sharedApplication].rootViewController dismissModalViewControllerAnimated:YES];
}

- (void)motionViewControllerDidFinish:(UIImage *)image {
    self.motionsImageView.image = image;
    [[UIApplication sharedApplication].rootViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITextView delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSLog(@"change text in range(%d, %d), replace text:%@", range.location, range.length, text);
    if(self.currentHintView) {
        if([self.currentHintView isMemberOfClass:[PostAtHintView class]] && [text isEqualToString:@" "]) {
            [self dismissHintView];
            return YES;
        }
    } else if([text isEqualToString:@"@"]) {
        [self presentAtHintView];
        self.atButton.selected = YES;
        self.currentHintStringRange = NSMakeRange(range.location + text.length - range.length, 0);
    } else if([text isEqualToString:@"#"]) {
        [self presentTopicHintView];
        self.topicButton.selected = YES;
        self.currentHintStringRange = NSMakeRange(range.location + text.length - range.length, 0);
        _needFillPoundSign = YES;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    if(self.currentHintView) {
        NSLog(@"text view selected range:%@", NSStringFromRange(self.textView.selectedRange));
        NSInteger length = self.textView.selectedRange.location - self.currentHintStringRange.location;
        if(length < 0)
            [self dismissHintView];
        else {
            self.currentHintStringRange = NSMakeRange(self.currentHintStringRange.location, length);
            NSLog(@"hint range:(%d, %d)", self.currentHintStringRange.location, self.currentHintStringRange.length);
        }
    }
    [self updateTextCount];
    [self updateCurrentHintView];
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    NSLog(@"change selection:(%d, %d)", textView.selectedRange.location, textView.selectedRange.length);
    if(self.currentHintView) {
        if(textView.selectedRange.location < self.currentHintStringRange.location
           || textView.selectedRange.location > self.currentHintStringRange.location + self.currentHintStringRange.length) {
            [self dismissHintView];
        }
    }
}

#pragma mark - PostHintView delegate

- (void)postHintView:(PostHintView *)hintView didSelectHintString:(NSString *)text {
    [self replaceHintWithResult:text];
}

#pragma mark - UIScrollView delegate 

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(scrollView == self.textView) {
        [self updateCurrentHintViewFrame];
    }
}

#pragma mark - CLLocationManager delegate

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    self.navButton.hidden = NO;
    self.navActivityView.hidden = YES;
    [self.navActivityView stopAnimating];
    self.navButton.selected = NO;
}

- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    [manager stopUpdatingLocation];
    self.locationManager = nil;
    _location2D = newLocation.coordinate; 

    if(_located)
        return;
    
    WBClient *client = [WBClient client];
    [client setCompletionBlock:^(WBClient *client) {
        if(!client.hasError) {
            NSString *locationString;
            NSArray* array = (NSArray*)client.responseJSONObject;
            if (array.count > 0) {
                NSDictionary *dict = [array objectAtIndex:0];
                NSLog(@"location dict:%@", dict);
                locationString = [NSString stringWithFormat:@"%@%@%@", [dict objectForKey:@"city_name"], [dict objectForKey:@"district_name"], [dict objectForKey:@"name"]];
            }
            [self showNavLocationLabel:locationString];
        } else {
            self.navButton.selected = NO;
        }
        
        [self.navActivityView stopAnimating];
        self.navButton.hidden = NO;
        self.navActivityView.hidden = YES;
    }];
    
    float lat = _location2D.latitude;
    float lon = _location2D.longitude;
    [client getAddressFromGeoWithCoordinate:[[NSString alloc] initWithFormat:@"%f,%f", lon, lat]];
    
    _located = YES;
}

@end
