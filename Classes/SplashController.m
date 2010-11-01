//
//  SplashController.m
//  MFA Guide
//
//  Created by Robert Brecher on 9/21/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "SplashController.h"

#import "StopFactory.h"
#import "TapAppDelegate.h"
#import "TourController.h"
#import "VideoStop.h"

@implementation SplashController

@synthesize player;

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Set title
	xmlDocPtr tourDoc = [[(TapAppDelegate*)[[UIApplication sharedApplication] delegate] currentTourController] tourDoc];
	xmlNodePtr titleNode = [TourMLUtils getTitleInDocument:tourDoc];
	if (titleNode) {
		char* titleChars = (char*)xmlNodeGetContent(titleNode);
		[titleLabel setFont:[UIFont fontWithName:@"HelveticaNeueLTStd-MdCn" size:30.0f]];
		[titleLabel setText:[NSString stringWithUTF8String:titleChars]];
		free(titleChars);
	}
	
    // Set image
	xmlNodePtr imageNode = [TourMLUtils getImageInDocument:tourDoc];
	if (imageNode) {
		char* imageChars = (char*)xmlNodeGetContent(imageNode);
		NSString *imageSrc = [NSString stringWithUTF8String:imageChars];
		NSBundle *tourBundle = [[(TapAppDelegate*)[[UIApplication sharedApplication] delegate] currentTourController] tourBundle];
		NSString *imagePath = [tourBundle pathForResource:[[imageSrc lastPathComponent] stringByDeletingPathExtension]
												   ofType:[[imageSrc lastPathComponent] pathExtension]
											  inDirectory:[imageSrc stringByDeletingLastPathComponent]];
		[splashImage setImage:[UIImage imageWithContentsOfFile:imagePath]];
		free(imageChars);
	}
	
	// Setup buttons
	xmlNodePtr showKeypadTextNode = [TourMLUtils getLocalizationInDocument:tourDoc withName:@"ShowKeypadText"];
	if (showKeypadTextNode) {
		char* showKeypadTextChars = (char*)xmlNodeGetContent(showKeypadTextNode);
		[enterButton setTitle:[NSString stringWithUTF8String:showKeypadTextChars] forState:UIControlStateNormal];
		free(showKeypadTextChars);
	}
	UIColor *backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"splash-button-bg-tile.png"]];
	UIView *enterBackgroundView = [[UIView alloc] initWithFrame:[enterButton frame]];
	[enterBackgroundView setBackgroundColor:backgroundColor];
	[enterBackgroundView setOpaque:NO];
	[enterBackgroundView addSubview:enterButton];
	[enterButton setBackgroundColor:[UIColor clearColor]];
	[enterButton setFrame:[enterButton bounds]];	
	enterDisclosureView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"splash-button-disclosure.png"]];
	[enterDisclosureView setFrame:CGRectMake(enterBackgroundView.frame.size.width - enterDisclosureView.frame.size.width * 1.3,
											 (enterBackgroundView.frame.size.height - enterDisclosureView.frame.size.height) / 2, 
											 enterDisclosureView.frame.size.width,
											 enterDisclosureView.frame.size.height)];
	[enterBackgroundView addSubview:enterDisclosureView];
	[[self view] addSubview:enterBackgroundView];
	
	UIView *welcomeBackgroundView = [[UIView alloc] initWithFrame:[welcomeButton frame]];
	[welcomeBackgroundView setBackgroundColor:backgroundColor];
	[welcomeBackgroundView setOpaque:NO];
	[welcomeBackgroundView addSubview:welcomeButton];
	[welcomeButton setBackgroundColor:[UIColor clearColor]];
	[welcomeButton setFrame:[welcomeButton bounds]];
	welcomeDisclosureView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"splash-button-disclosure.png"]];
	[welcomeDisclosureView setFrame:CGRectMake(welcomeBackgroundView.frame.size.width - welcomeDisclosureView.frame.size.width * 1.3,
											   (welcomeBackgroundView.frame.size.height - welcomeDisclosureView.frame.size.height) / 2, 
											   welcomeDisclosureView.frame.size.width,
											   welcomeDisclosureView.frame.size.height)];
	[welcomeBackgroundView addSubview:welcomeDisclosureView];
	[[self view] addSubview:welcomeBackgroundView];
	
	TourController *tourController = [(TapAppDelegate*)[[UIApplication sharedApplication] delegate] currentTourController];	
	xmlNodePtr stopNode = [TourMLUtils getStopInDocument:[tourController tourDoc] withCode:TOUR_WELCOME_STOP];
	if (stopNode != NULL) {
		BaseStop *stop = [StopFactory stopForStopNode:stopNode];
		[welcomeButton setTitle:[stop getTitle] forState:UIControlStateNormal]; 
	}
	else {
		[enterBackgroundView setFrame:[welcomeBackgroundView frame]];
		[welcomeBackgroundView setHidden:YES];
	}
	
	[enterBackgroundView release];
	[welcomeBackgroundView release];
	
	// Add help
	UIImageView *helpBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"help-bg.png"]];
	[helpBg setUserInteractionEnabled:NO];
	[helpBg setFrame:CGRectMake(0, self.view.frame.size.height - helpBg.frame.size.height, helpBg.frame.size.width, helpBg.frame.size.height)];
	[[self view] addSubview:helpBg];
	UIButton *helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
	UIImage *helpButtonUp = [UIImage imageNamed:@"help-button-up.png"];
	[helpButton setImage:helpButtonUp forState:UIControlStateNormal];
	[helpButton setImage:[UIImage imageNamed:@"help-button-down.png"] forState:UIControlStateHighlighted];
	[helpButton setFrame:CGRectMake(277.0 / 320.0 * helpBg.frame.size.width, helpBg.frame.origin.y + 6.0 / 35.0 * helpBg.frame.size.height, helpButtonUp.size.width, helpButtonUp.size.height)];
	[helpButton addTarget:self action:@selector(helpTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
	[[self view] addSubview:helpButton];
	[helpBg release];
	
	// Set sponsor image
	xmlNodePtr sponsorImageNode = [TourMLUtils getSponsorImageInDocument:tourDoc];
	if (sponsorImageNode) {
		char *sponsorImageChars = (char*)xmlNodeGetContent(sponsorImageNode);
		NSString *sponsorImageSrc = [NSString stringWithUTF8String:sponsorImageChars];
		NSBundle *tourBundle = [[(TapAppDelegate*)[[UIApplication sharedApplication] delegate] currentTourController] tourBundle];
		NSString *sponsorImagePath = [tourBundle pathForResource:[[sponsorImageSrc lastPathComponent] stringByDeletingPathExtension]
														  ofType:[[sponsorImageSrc lastPathComponent] pathExtension]
													 inDirectory:[sponsorImageSrc stringByDeletingLastPathComponent]];
		sponsorImage = [[TapDetectingImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:sponsorImagePath]];
		[sponsorImage setDelegate:self];
		[[self view] addSubview:sponsorImage];
		sponsorTimer = [[NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(hideSponsorImage) userInfo:nil repeats:NO] retain];
	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)dealloc
{
	[sponsorImage release];
	[sponsorTimer release];
	[player release];
	[titleLabel release];
	[enterView release];
	[enterButton release];
	[enterDisclosureView release];
	[welcomeView release];
	[welcomeButton release];
	[welcomeDisclosureView release];
	[splashImage release];
    [super dealloc];
}

#pragma mark -
#pragma mark View Events

- (void)viewWillAppear:(BOOL)animated
{
//	[[self navigationController] setNavigationBarHidden:YES animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
	if (player) {
		[player stop];
	}
}

#pragma mark -
#pragma mark Sponsor Image

- (void)hideSponsorImage
{
	if (sponsorImage) {
		[UIView animateWithDuration:1.0 animations:^{
			[sponsorImage setAlpha:0.0f];
		} completion:^(BOOL finished){
			[sponsorImage removeFromSuperview];
			[sponsorImage release];
			sponsorImage = nil;
		}];
	}
}

#pragma mark -
#pragma mark Buttons

- (IBAction)backTouchUpInside:(UIButton *)sender
{
	[[self parentViewController] dismissModalViewControllerAnimated:YES];
}

- (IBAction)enterTouchUpInside:(UIButton *)sender
{
	TourController *tourController = [(TapAppDelegate*)[[UIApplication sharedApplication] delegate] currentTourController];
	[tourController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
	[self presentModalViewController:tourController animated:YES];
}

- (IBAction)welcomeTouchUpInside:(UIButton *)sender
{
	// Check for playing audio first
	if (player && [player isPlaying]) {
		[player stop];
		[welcomeDisclosureView setImage:[UIImage imageNamed:@"splash-button-disclosure.png"]];
		return;
	}
	
	// Otherwise get correct stop and display
	TourController *tourController = [(TapAppDelegate*)[[UIApplication sharedApplication] delegate] currentTourController];	
	xmlNodePtr stopNode = [TourMLUtils getStopInDocument:[tourController tourDoc] withCode:TOUR_WELCOME_STOP];
	if (stopNode != NULL) {
		BaseStop *stop = [StopFactory stopForStopNode:stopNode];
		if ([stop isMemberOfClass:[VideoStop class]]) {
			
			// Audio stop
			if ([(VideoStop *)stop isAudio]) {
				
				// Get path to audio
				NSBundle *tourBundle = [tourController tourBundle];
				NSString *audioSrc = [(VideoStop *)stop getSourcePath];
				NSString *audioPath = [tourBundle pathForResource:[[audioSrc lastPathComponent] stringByDeletingPathExtension]
														   ofType:[[audioSrc lastPathComponent] pathExtension]
													  inDirectory:[audioSrc stringByDeletingLastPathComponent]];
				NSURL *audioUrl = [[NSURL alloc] initFileURLWithPath:audioPath];
				
				// Play sound
				player = [[AVAudioPlayer alloc] initWithContentsOfURL:audioUrl error:nil];
				if (player) {
					[player play];
					[welcomeDisclosureView setImage:[UIImage imageNamed:@"splash-button-disclosure-stop.png"]];
				}
				[audioUrl release];
			}
			
			// Video stop
			else {
				[stop loadStopView];
			}
		}
		
		// All other stops
		else {
			[tourController loadStop:stop animated:NO];
			[tourController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
			[self presentModalViewController:tourController animated:YES];
		}
	}
}

- (void)helpTouchUpInside:(UIButton *)sender
{	
	TourController *tourController = [(TapAppDelegate*)[[UIApplication sharedApplication] delegate] currentTourController];	
	xmlNodePtr stopNode = [TourMLUtils getStopInDocument:[tourController tourDoc] withCode:TOUR_HELP_STOP];
	if (stopNode != NULL) {
		[tourController loadStop:[StopFactory stopForStopNode:stopNode]];
		[tourController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
		[self presentModalViewController:tourController animated:YES];
	}
}

#pragma mark -
#pragma mark TapDetectingImageViewDelegate

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotSingleTapAtPoint:(CGPoint)tapPoint
{
	if (sponsorTimer) {
		[sponsorTimer invalidate];
		[sponsorTimer release];
		sponsorTimer = nil;
	}
	[self hideSponsorImage];
}

@end
