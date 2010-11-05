//
//  SplashController.h
//  MFA Guide
//
//  Created by Robert Brecher on 9/21/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "TapDetectingImageView.h"

@interface SplashController : UIViewController <TapDetectingImageViewDelegate> {
	
	TapDetectingImageView *sponsorImage;
	NSTimer *sponsorTimer;
	
	AVAudioPlayer *player;
	
	IBOutlet UILabel *titleLabel;
	
	IBOutlet UIView *enterView;
	IBOutlet UIButton *enterButton;
	UIImageView *enterDisclosureView;
	
	IBOutlet UIView *welcomeView;
	IBOutlet UIButton *welcomeButton;
	UIImageView *welcomeDisclosureView;
	
	IBOutlet UIImageView *splashImage;
}

@property (nonatomic, retain) AVAudioPlayer *player;

- (IBAction)backTouchUpInside:(UIButton *)sender;
- (IBAction)enterTouchUpInside:(UIButton *)sender;
- (IBAction)welcomeTouchUpInside:(UIButton *)sender;

@end
