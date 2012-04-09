#import "KeypadController.h"
#import "TapAppDelegate.h"
#import "TourController.h"
#import "StopFactory.h"

@implementation KeypadController

#pragma mark -
#pragma mark UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		TourController *tourController = [(TapAppDelegate *)[[UIApplication sharedApplication] delegate] currentTourController];
		xmlNodePtr enterStopTextNode = [TourMLUtils getLocalizationInDocument:[tourController tourDoc] withName:@"EnterStopText"];
		if (enterStopTextNode) {
			char* enterStopTextChars = (char*)xmlNodeGetContent(enterStopTextNode);
			[self setTitle:[NSString stringWithUTF8String:enterStopTextChars]];
			free(enterStopTextChars);
		}
		else {
			[self setTitle:@"Find an Artwork"];
		}
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Localization
	TourController *tourController = (TourController *)[self navigationController];
	xmlNodePtr keypadEnterButtonNode = [TourMLUtils getLocalizationInDocument:[tourController tourDoc] withName:@"KeypadEnterButton"];
	if (keypadEnterButtonNode) {
		char* keypadEnterButtonChars = (char*)xmlNodeGetContent(keypadEnterButtonNode);
		[buttonGo setTitle:[NSString stringWithUTF8String:keypadEnterButtonChars] forState:UIControlStateNormal];
		[buttonGo setTitle:[NSString stringWithUTF8String:keypadEnterButtonChars] forState:UIControlStateDisabled];
		free(keypadEnterButtonChars);
	}
	xmlNodePtr keypadInstructionsNode = [TourMLUtils getLocalizationInDocument:[tourController tourDoc] withName:@"KeypadInstructions"];
	if (keypadInstructionsNode) {
		char* keypadInstructionChars = (char*)xmlNodeGetContent(keypadInstructionsNode);
		[lblHelp setText:[NSString stringWithUTF8String:keypadInstructionChars]];
		free(keypadInstructionChars);
	}
	
	// Keypad
    [self clearCode];
	[[self view] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-main.png"]]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self clearCode];
	[self willRotateToInterfaceOrientation:[self interfaceOrientation] duration:0.0];
}

- (void)viewDidAppear:(BOOL)animated
{
//	[[self navigationController] setNavigationBarHidden:NO animated:NO];
}

- (void)dealloc
{	
	[super dealloc];
}

- (UINavigationItem *)navigationItem
{	
	UINavigationItem *theNavigationItem = [[[UINavigationItem alloc] initWithTitle:[self title]] autorelease];
	UIBarButtonItem *backButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"keypad-back-icon.png"] style:UIBarButtonItemStylePlain target:nil action:nil] autorelease];
	[theNavigationItem setBackBarButtonItem:backButton];
	UIBarButtonItem *homeButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"keypad-home-icon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(returnToMenu)] autorelease];
	[theNavigationItem setLeftBarButtonItem:homeButton];
	return theNavigationItem;
}

#pragma mark -
#pragma mark NIB Actions

- (IBAction)buttonDown:(id)sender
{
	[(TapAppDelegate*)[[UIApplication sharedApplication] delegate] playClick];
}

- (IBAction)buttonUpInside:(id)sender
{
	if (sender == buttonClear) {
		if ([lblCode.text length] > 1) {
			[lblCode setText:[lblCode.text substringToIndex:[lblCode.text length] - 1]];
			if ([lblCode.text length] < MINIMUM_CODE_LENGTH) {
				buttonGo.enabled = NO;
			}
		}
		else if ([lblCode.text length] == 1) {
			[self clearCode];
		}
		return;
	}
	
	// Don't allow code to exceed max length
	if ([lblCode.text length] >= MAXIMUM_CODE_LENGTH) {
		return;
	}
	
	// Append the corresponding number to the code
	if (sender == button0) [lblCode setText:[lblCode.text stringByAppendingString:@"0"]];
	else if (sender == button1) [lblCode setText:[lblCode.text stringByAppendingString:@"1"]];
	else if (sender == button2) [lblCode setText:[lblCode.text stringByAppendingString:@"2"]];
	else if (sender == button3) [lblCode setText:[lblCode.text stringByAppendingString:@"3"]];
	else if (sender == button4) [lblCode setText:[lblCode.text stringByAppendingString:@"4"]];
	else if (sender == button5) [lblCode setText:[lblCode.text stringByAppendingString:@"5"]];
	else if (sender == button6) [lblCode setText:[lblCode.text stringByAppendingString:@"6"]];
	else if (sender == button7) [lblCode setText:[lblCode.text stringByAppendingString:@"7"]];
	else if (sender == button8) [lblCode setText:[lblCode.text stringByAppendingString:@"8"]];
	else if (sender == button9) [lblCode setText:[lblCode.text stringByAppendingString:@"9"]];
	
	// Hide the help label
	lblHelp.hidden = YES;
	
	// If the code meets the minimum length, enable the button
	if ([lblCode.text length] >= MINIMUM_CODE_LENGTH) {
		buttonGo.enabled = YES;
	}
}

- (IBAction)goUpInside:(id)sender
{
	// Grab the stop code
	NSString *stopCode = [lblCode text];
	if ([stopCode length] < MINIMUM_CODE_LENGTH) {
		return;
	}
	
	// Check for the kill code
	if ([stopCode isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"killCode"]]) {
		exit(0); // NOTE: This is not allowed for AppStore apps
	}
	
	// Check for the update code
	if ([stopCode isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"updateCode"]]) {
		[(TapAppDelegate *)[[UIApplication sharedApplication] delegate] closeTourAndShowUpdater];
		return;
	}
	
    // Load the StopNavigation view
	TourController *tourController = (TourController *)[self navigationController];
	xmlNodePtr stopNode = [TourMLUtils getStopInDocument:[tourController tourDoc] withCode:stopCode];
	if (stopNode == NULL) {
		
		// Play error sound
		[(TapAppDelegate*)[[UIApplication sharedApplication] delegate] playError];
		
		// Track in analytics
		[Analytics trackAction:@"bad-code" forStop:[NSString stringWithFormat:@"<%@>", stopCode]];
		
		// Alert user
		NSString *message = @"Stop [code] is not available on this tour. Please return to the list of available tours and select a different tour.";
		xmlNodePtr keypadInvalidCodeNode = [TourMLUtils getLocalizationInDocument:[tourController tourDoc] withName:@"KeypadInvalidCode"];
		if (keypadInvalidCodeNode) {
			char* keypadInvalidCodeChars = (char*)xmlNodeGetContent(keypadInvalidCodeNode);
			message = [NSString stringWithUTF8String:keypadInvalidCodeChars];
			free(keypadInvalidCodeChars);
		}
		message = [message stringByReplacingOccurrencesOfString:@"[code]" withString:stopCode];
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:nil
							  message:message
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
        [alert show];
        [alert release];
		
		[self clearCode];
		
		return; // failed
	}
	if ([tourController loadStop:[StopFactory stopForStopNode:stopNode]]) {
		// Stop loaded successfully
	} 
	else {
		// Failed to load stop
		[self clearCode];
	}
}

- (void)clearCode
{
	[lblCode setText:@""];
	lblHelp.hidden = NO;
	buttonGo.enabled = NO;
}

- (void)returnToMenu
{
	if ([[[UIDevice currentDevice] systemVersion] doubleValue] < 5.0) {
		[[self parentViewController] dismissModalViewControllerAnimated:YES];
	}
	else {
		[[self presentingViewController] dismissModalViewControllerAnimated:YES];
	}
}

@end
