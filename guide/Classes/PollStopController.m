#import "PollStopController.h"
#import "TapAppDelegate.h"

#define OVERLAY_VIEW_TAG    856
#define RESULTS_VIEW_TAG    857

#define POLL_URL_FORMAT @"http://athena.imamuseum.org/tap/tourml/vote/%@/%@"

@implementation PollStopController

@synthesize questionLabel;
@synthesize pickerView;
@synthesize submitButton;

@synthesize pollStop;
@synthesize responseData;
@synthesize delayTimer;

- (id)initWithPollStop:(PollStop*)stop
{
	if (self = [super initWithNibName:@"PollStop" bundle:[NSBundle mainBundle]]) {
		[self setPollStop:stop];
	}
	
	return self;
}

- (IBAction)submitPressed:(id)sender
{
	[(TapAppDelegate*)[[UIApplication sharedApplication] delegate] playClick];
	
	// Add a spinner overlay
	UIView *overlay = [[UIView alloc] initWithFrame:[self.view frame]];
    [overlay setTag:OVERLAY_VIEW_TAG];
	[overlay setBackgroundColor:[[[UIColor alloc] initWithWhite:0.0f alpha:0.7f] autorelease]];
	[overlay setAlpha:0.0f];
	[overlay setAutoresizesSubviews:YES];
	[overlay setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    CGRect resultFrame = CGRectMake(CGRectGetMinX([overlay frame]) + 10,
                                    CGRectGetMinY([overlay frame]) + 10,
                                    CGRectGetWidth([overlay frame]) - 30,
                                    CGRectGetHeight([overlay frame]) - 30);
    UIView *resultView = [[UIView alloc] initWithFrame:resultFrame];
    [resultView setTag:RESULTS_VIEW_TAG];
    [resultView setClipsToBounds:YES];
    [resultView setAutoresizesSubviews:YES];
	[resultView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [overlay addSubview:resultView];
	[resultView release];
    
    UILabel *submitLabel = [[UILabel alloc] initWithFrame:resultFrame];
//  [submitLabel setText:NSLocalizedString(@"Submitting", @"Poll response being sent")];
	[submitLabel setText:@"Submitting"];
    [submitLabel setFont:[UIFont boldSystemFontOfSize:28.0f]];
    [submitLabel setTextColor:[UIColor whiteColor]];
    [submitLabel setTextAlignment:UITextAlignmentCenter];
    [submitLabel setTransform:CGAffineTransformMakeTranslation(0.0f, -40.0f)];
    [submitLabel setBackgroundColor:[UIColor clearColor]];
    [submitLabel setShadowColor:[UIColor blackColor]];
    [submitLabel setShadowOffset:CGSizeMake(1, 1)];
    [resultView addSubview:submitLabel];
	[submitLabel release];
	
	UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[spinner setCenter:[resultView center]];
	[spinner startAnimating];
	[resultView addSubview:spinner];
	[spinner release];
	
	[self.view addSubview:overlay];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5f];
	[overlay setAlpha:1.0f];
	[UIView commitAnimations];
	[overlay release];
    
	responseData = [[NSMutableData data] retain];
    NSString *answer = [[pollStop getAnswers] objectAtIndex:[pickerView selectedRowInComponent:0]];
    NSString *reqUrl = [NSString stringWithFormat:POLL_URL_FORMAT, [pollStop getStopId], answer];
	NSString *reqUrlEsc = [reqUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"Submitting poll response to: %@", reqUrlEsc);
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:reqUrlEsc]
											 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
										 timeoutInterval:5];
	
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request 
                                                                  delegate:self 
                                                          startImmediately:YES];
    
    if (connection == nil) {
//        UIAlertView *alert = [[UIAlertView alloc]
//							  initWithTitle:nil
//							  message:NSLocalizedString(@"Sorry, but an error occurred.", @"General error message")
//							  delegate:nil
//							  cancelButtonTitle:@"OK"
//							  otherButtonTitles:nil];

        UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:nil
							  message:@"Sorry, but an error occurred."
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
	
	[connection release];
	[Analytics trackAction:@"voted" forStop:[pollStop getStopId]];
}

- (void)showResults:(NSTimer*)timer
{
    UIView *resultView = [self.view viewWithTag:RESULTS_VIEW_TAG];
    PollResults *results = (PollResults*)[timer userInfo];

    if (results == nil) // Handle empty results
    {
        // Remove the results view
        [resultView removeFromSuperview];
        
        // Show an alert
//        UIAlertView *alert = [[UIAlertView alloc]
//							  initWithTitle:nil
//							  message:NSLocalizedString(@"Thanks for your response! Please hit the back button.", @"Network error occured")
//							  delegate:nil
//							  cancelButtonTitle:@"OK"
//							  otherButtonTitles:nil];

		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:nil
							  message:@"Thanks for your response! Please hit the back button."
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		
		
        [alert show];
        [alert release];
    }
    else
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:1.0f];
        [UIView setAnimationDelegate:results];
        [UIView setAnimationDidStopSelector:@selector(flipAnimationDidStop:finished:context:)];
        
        for (UIView* child in [resultView subviews]) [child removeFromSuperview];
        [resultView addSubview:[results getResultsTableWithFrame:[resultView frame]]];
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:resultView cache:YES];
        
        [UIView commitAnimations];
    }
}

-(void) dealloc
{
	[pollStop release];
    if (delayTimer != nil) [delayTimer release];
    	
	[super dealloc];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
	// Set the question
	[questionLabel setText:[pollStop getQuestion]];
	
	// Layout poll
	[questionLabel setFrame:CGRectMake(10.0f, 0.0f, 300.0f, 102.0f)];
	[submitButton setFrame:CGRectMake(20.0f, 351.0f, 280.0f, 45.0f)];
	[pickerView setFrame:CGRectMake(0.0f, 110.0f, 320.0f, 216.0f)];
	[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-poll-portrait.png"]]];
	[self.view setNeedsLayout];
}

#pragma mark UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [pollStop numberOfAnswers];
}

#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	return (NSString*)[[pollStop getAnswers] objectAtIndex:row];
}

#pragma mark NSURLConnection

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"didRecieveResponse:");
	[responseData setLength:0];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSLog(@"didRecieveData:%d", [data length]);
	[responseData appendData:data];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSString *message = [NSString stringWithFormat:@"Error! %@", [error localizedDescription]];
	
	NSLog(@"didFailWithError:%@", message);
	
    // Try to display previous results
	PollResults *pollResults = [[PollResults alloc] initWithData:responseData pollStop:pollStop];
    delayTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                  target:self
                                                selector:@selector(showResults:)
                                                userInfo:pollResults
                                                 repeats:NO];
	[pollResults release];
	[responseData release];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSLog(@"connectionDidFinishLoading:%d", [responseData length]);
    
	PollResults *pollResults = [[PollResults alloc] initWithData:responseData pollStop:pollStop];
    delayTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                  target:self
                                                selector:@selector(showResults:)
                                                userInfo:pollResults
                                                 repeats:NO];
	[pollResults release];
	[responseData release];
}

@end
