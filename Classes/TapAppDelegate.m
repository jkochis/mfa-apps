#import "TapAppDelegate.h"
#import "BackgroundUpdater.h"
#import "KeypadController.h"
#import "SplashController.h"
#import "StopGroupController.h"
#import "TourController.h"

@interface TapAppDelegate (PrivateMethods)

- (void)scheduleBackgroundUpdates;

@end


@implementation TapAppDelegate

@synthesize menuController, currentTourController, backgroundUpdater;

@synthesize clickFileURLRef;
@synthesize clickFileObject;
@synthesize errorFileURLRef;
@synthesize errorFileObject;

- (BackgroundUpdater *)backgroundUpdater
{
	if (!backgroundUpdater) {
		backgroundUpdater = [[BackgroundUpdater alloc] init];
		[backgroundUpdater setDelegate:self];
	}
	return backgroundUpdater;
}

- (void)dealloc 
{
	[window release];
	[menuController release];
	
	[currentTourController release];
	
	AudioServicesDisposeSystemSoundID(clickFileObject);
    CFRelease(clickFileURLRef);
	AudioServicesDisposeSystemSoundID(errorFileObject);
    CFRelease(errorFileURLRef);
	
    [super dealloc];
}

#pragma mark -
#pragma mark UI Sound Effects

- (void)playClick
{
	AudioServicesPlaySystemSound(clickFileObject);
}

- (void)playError
{
	AudioServicesPlaySystemSound(errorFileObject);
}

- (BOOL)loadTourWithBundleName:(NSString *)bundleName
{
	// Setup tour controller for later, also catch any errors now
	currentTourController = [[TourController alloc] init];
	[currentTourController loadBundle:bundleName];
	KeypadController *keypadController = [[KeypadController alloc] initWithNibName:@"Keypad" bundle:[NSBundle mainBundle]];
	[currentTourController pushViewController:keypadController animated:NO];
	[keypadController release];
	
	// Setup splash controller and present
	SplashController *splashController = [[SplashController alloc] initWithNibName:@"Splash" bundle:[NSBundle mainBundle]];
	[splashController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
	[menuController presentModalViewController:splashController animated:YES];
	[splashController release];
	
	return YES;
}

- (void)closeTour
{
	[menuController dismissModalViewControllerAnimated:YES];
	currentTourController = nil;
}

#pragma mark -
#pragma mark UIApplicationDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	// Disable idle timer
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	
    // Allocate the sounds
	CFBundleRef mainBundle = CFBundleGetMainBundle();
	clickFileURLRef = CFBundleCopyResourceURL(mainBundle, CFSTR("click"), CFSTR("aif"), NULL);
    AudioServicesCreateSystemSoundID(clickFileURLRef, &clickFileObject);
	errorFileURLRef = CFBundleCopyResourceURL(mainBundle, CFSTR("error"), CFSTR("aif"), NULL);
    AudioServicesCreateSystemSoundID(errorFileURLRef, &errorFileObject);
	
	// Add the navigation controller to the window
	[window addSubview:[menuController view]];

	// Split
//	// Add overlay images
//	UIImageView *splashTop = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tap-title-screen-top.png"]];
//	UIImageView *splashBtm = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tap-title-screen-btm.png"]];
//	[window addSubview:splashTop];
//	[window addSubview:splashBtm];
//	
//	// Slide apart images
//	[UIView beginAnimations:nil context:nil];
//	[UIView setAnimationDuration:1.0f];
//	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
//	[UIView setAnimationDelegate:self];
//	[UIView setAnimationDidStopSelector:@selector(splashSlideAnimationDidStop:finished:context:)];
//	[splashTop setFrame:CGRectMake(0.0f, -480.0f, CGRectGetWidth([splashTop frame]), CGRectGetHeight([splashTop frame]))];
//	[splashBtm setFrame:CGRectMake(0.0f, 480.0f, CGRectGetWidth([splashBtm frame]), CGRectGetHeight([splashBtm frame]))];
//	[UIView commitAnimations];
//
//	// Clean up
//	[splashTop release];
//	[splashBtm release];
	
	// Fade
//	UIImageView *splash = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]];
//	[window addSubview:splash];
//	[UIView animateWithDuration:0.5f animations:^{
//		[splash setAlpha:0.0f];
//	} completion:^(BOOL finished){
//		[splash removeFromSuperview];
//		[splash release];
//	}];
	
	// Slide
	UIImageView *splash = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]];
	[window addSubview:splash];
	[UIView animateWithDuration:0.75f animations:^{
		[splash setFrame:CGRectMake(0, -480.0f, splash.frame.size.width, splash.frame.size.height)];
	} completion:^(BOOL finished){
		[splash removeFromSuperview];
		[splash release];
	}];
	
	// Record the launch event
	[Analytics trackAction:NSLocalizedString(@"launch - en", @"App starting") forStop:@"tap"];
	
	// Start updates
//	[self scheduleBackgroundUpdates];
	
	
	[[NSUserDefaults standardUserDefaults] setObject:@"99999" forKey:@"killCode"];
	[[NSUserDefaults standardUserDefaults] setObject:@"11111" forKey:@"updateCode"];
	
	
	
    [window makeKeyAndVisible];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	if ([[[notification userInfo] objectForKey:@"action"] isEqualToString:@"update"]) {
		if (![[self backgroundUpdater] isUpdating]) {
			[backgroundUpdater update];
		}
	}
}

#pragma mark -
#pragma mark Background Updater

- (void)scheduleBackgroundUpdates
{	
	if (![[[UIApplication sharedApplication] scheduledLocalNotifications] count]) {
		unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
		NSDate *date = [NSDate date];
		NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:date];
		[dateComponents setHour:0];
		[dateComponents setMinute:0];
		[localNotification setFireDate:[[NSCalendar currentCalendar] dateFromComponents:dateComponents]];
		[localNotification setRepeatInterval:NSDayCalendarUnit];
		[localNotification setAlertBody:@"Perform automatic update for MFA Tours?"];
		[localNotification setAlertAction:@"Update"];
		[localNotification setUserInfo:[NSDictionary dictionaryWithObject:@"update" forKey:@"action"]];
		[[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
	}
}

#pragma mark -
#pragma mark BackgroundUpdaterDelegate Methods

- (void)backgroundUpdaterDidFinishUpdating:(BackgroundUpdater *)backgroundUpdater
{
	[menuController refresh];
}

- (void)backgroundUpdater:(BackgroundUpdater *)backgroundUpdater didFailWithError:(NSError *)error
{
	
}

#pragma mark -
#pragma mark UIView Animation Delegate Methods

- (void)splashSlideAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	[[window viewWithTag:SPLASH_SLIDE_IMAGE_TOP_TAG] removeFromSuperview];
	[[window viewWithTag:SPLASH_SLIDE_IMAGE_BTM_TAG] removeFromSuperview];
	
	// Show a prompt for the help video
//	UIAlertView *helpPrompt = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Watch help video?", @"Prompt header")
//														 message:NSLocalizedString(@"Get an overview of how to use and make the most of TAP.", @"Prompt message")
//														delegate:self
//											   cancelButtonTitle:NSLocalizedString(@"Skip", @"Skip the video")
//											   otherButtonTitles:nil];
//	[helpPrompt addButtonWithTitle:NSLocalizedString(@"Yes", @"Confirm to watch video")];
//	[helpPrompt show];
//	[helpPrompt release];
}

#pragma mark -
#pragma mark UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
//	if (buttonIndex == 1)
//	{
//		// Play the help video
//		xmlNodePtr helpVideoNode = [TourMLUtils getStopInDocument:tourDoc withCode:TAP_HELP_VIDEO_CODE];
//
//		if (helpVideoNode == NULL)
//		{
//			[self playError];
//			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
//															message:NSLocalizedString(@"Unable to load the help video!", @"Missing video error")
//														   delegate:nil
//												  cancelButtonTitle:@"OK"
//												  otherButtonTitles:nil];
//			[alert show];
//			[alert release];
//			return; // failed
//		}
//		
//		[self loadStop:[StopFactory stopForStopNode:helpVideoNode]];
//	}
}

@end
