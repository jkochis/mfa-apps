//
//  TourController.m
//  MFA Guide
//
//  Created by Robert Brecher on 9/15/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "TourController.h"

#import "Analytics.h"
#import "StopFactory.h"
#import "StopGroupController.h"
#import "TapAppDelegate.h"

@implementation TourController

@synthesize tourBundle, tourDoc;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// Set delegate
	[self setDelegate:self];
	
	// Init nav bar
	[[self navigationBar] setBarStyle:UIBarStyleBlack];
	
	// Add help
	helpBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"help-bg.png"]];
	[helpBg setUserInteractionEnabled:NO];
	[helpBg setFrame:CGRectMake(0, self.view.frame.size.height - helpBg.frame.size.height, helpBg.frame.size.width, helpBg.frame.size.height)];
	[[self view] addSubview:helpBg];
	helpButton = [UIButton buttonWithType:UIButtonTypeCustom];
	UIImage *helpButtonUp = [UIImage imageNamed:@"help-button-up.png"];
	[helpButton setImage:helpButtonUp forState:UIControlStateNormal];
	[helpButton setImage:[UIImage imageNamed:@"help-button-down.png"] forState:UIControlStateHighlighted];
	[helpButton setFrame:CGRectMake(276.0 / 320.0 * helpBg.frame.size.width, helpBg.frame.origin.y + 7.0 / 35.0 * helpBg.frame.size.height, helpButtonUp.size.width, helpButtonUp.size.height)];
	[helpButton addTarget:self action:@selector(helpTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
	[[self view] addSubview:helpButton];
	[helpBg release];
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
	[tourBundle release];
	xmlFreeDoc(tourDoc);
	[helpBg release];
	[helpButton release];
    [super dealloc];
}

- (BOOL)loadBundle:(NSString *)bundleName
{
	// Load the tour bundle so it is available by identifier
	NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [documentsPaths objectAtIndex:0];
	NSString *bundlePath = [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@.bundle", bundleName]];
	
    tourBundle = [NSBundle bundleWithPath:bundlePath];
    if (!tourBundle) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Unable to find the tour bundle, %@!", bundleName] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
		return NO;
    }
    else {
        // Load the bundle to register it
        [tourBundle load];
    }
	
	// Load the TourML file
	NSString *tourDataPath = [tourBundle pathForResource:TOUR_FILENAME ofType:@"xml"];
	if (!tourDataPath) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Unable to load the tour!"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
		return NO;
	}
	
	// Actually load the xml now
	tourDoc = xmlParseFile([tourDataPath UTF8String]);
	if (tourDoc == NULL) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Unable to load the tour!"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
		return NO;
	}
	return YES;
}

- (BOOL)loadStop:(BaseStop*)stop
{
	return [self loadStop:stop animated:YES];
}

- (BOOL)loadStop:(BaseStop *)stop animated:(BOOL)animated
{
	[Analytics trackAction:@"view" forStop:[stop getStopId]];
	if ([stop providesViewController]) {
		[self pushViewController:[stop newViewController] animated:animated];
		return YES; // success
	}
	else {
		// This stop controls itself
		return [stop loadStopView];
	}
}

- (void)showHelpButtonAnimated:(BOOL)animated
{
	if (animated) {
		[UIView animateWithDuration:0.5f animations:^{
			[helpBg setFrame:CGRectMake(0, self.view.frame.size.height - helpBg.frame.size.height, helpBg.frame.size.width, helpBg.frame.size.height)];
			[helpButton setFrame:CGRectMake(helpButton.frame.origin.x, helpBg.frame.origin.y + 7.0 / 35.0 * helpBg.frame.size.height, helpButton.frame.size.width, helpButton.frame.size.height)];
		}];
	}
	else {
		[helpBg setFrame:CGRectMake(0, self.view.frame.size.height - helpBg.frame.size.height, helpBg.frame.size.width, helpBg.frame.size.height)];
		[helpButton setFrame:CGRectMake(helpButton.frame.origin.x, helpBg.frame.origin.y + 7.0 / 35.0 * helpBg.frame.size.height, helpButton.frame.size.width, helpButton.frame.size.height)];
	}
}

- (void)hideHelpButtonAnimated:(BOOL)animated
{
	if (animated) {
		[UIView animateWithDuration:0.5f animations:^{
			[helpBg setFrame:CGRectMake(0, self.view.frame.size.height, helpBg.frame.size.width, helpBg.frame.size.height)];
			[helpButton setFrame:CGRectMake(helpButton.frame.origin.x, helpBg.frame.origin.y + 7.0 / 35.0 * helpBg.frame.size.height, helpButton.frame.size.width, helpButton.frame.size.height)];
		}];
	}
	else {
		[helpBg setFrame:CGRectMake(0, self.view.frame.size.height, helpBg.frame.size.width, helpBg.frame.size.height)];
		[helpButton setFrame:CGRectMake(helpButton.frame.origin.x, helpBg.frame.origin.y + 7.0 / 35.0 * helpBg.frame.size.height, helpButton.frame.size.width, helpButton.frame.size.height)];
	}
}

- (void)helpTouchUpInside:(UIButton *)sender
{
	xmlNodePtr stopNode = [TourMLUtils getStopInDocument:tourDoc withCode:TOUR_HELP_STOP];
	if (stopNode != NULL) {
		[self loadStop:[StopFactory stopForStopNode:stopNode]];
	}
}

#pragma mark -
#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if ([viewController isMemberOfClass:[StopGroupController class]]) {
		StopGroupController *stopGroupController = (StopGroupController *)viewController;
		if ([[[stopGroupController stopGroup] getStopCode] isEqualToString:TOUR_HELP_STOP]) {
			[self hideHelpButtonAnimated:YES];
			return;
		}
	}
	[self showHelpButtonAnimated:YES];
}

@end
