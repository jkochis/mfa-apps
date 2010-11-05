#import "StopGroupController.h"
#import "TapAppDelegate.h"
#import "TourController.h"

@interface StopGroupController (PrivateMethods)

- (void)showControls;
- (void)showControlsAndFadeOut:(NSTimeInterval)seconds;
- (void)hideControls;
- (void)cancelControlsTimer;

- (BOOL)audioStopIsVideo:(VideoStop *)audioStop;

- (void)playAudio:(NSString *)audioSrc;
- (void)stopAudio;
- (void)updateViewForAudioPlayerInfo;
- (void)updateViewForAudioPlayerState;
- (void)updateCurrentTimeForAudioPlayer;

- (void)playVideo:(NSString *)videoSrc;
- (void)stopVideo;
- (void)hideVideo;
- (void)updateViewForVideoPlayerInfo;
- (void)updateViewForVideoPlayerState;
- (void)updateCurrentTimeForVideoPlayer;

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center;

@end

#pragma mark -

@implementation StopGroupController

@synthesize stopTable, moviePlayerController, stopGroup;

- (id)initWithStopGroup:(StopGroup*)stop
{
	if ((self = [super initWithNibName:@"StopGroup" bundle:[NSBundle mainBundle]])) {
		[self setStopGroup:stop];
		[self setTitle:[stopGroup getTitle]];
		firstRun = YES;
	}
	return self;
}

- (void)dealloc
{
	[audioPlayer release];
	[updateTimer release];
	[progressView release];
	[currentTime release];
	[duration release];
	[progressBar release];
	[playButton release];
	[volumeView release];
	[volumeSlider release];
	[scrollView release];
	[stopTableShadow release];
	[stopTable release];
	[imageView release];
	[moviePlayerHolder release];
	[moviePlayerTapDetector release];
	[moviePlayerController release];
	[stopGroup release];
	[super dealloc];
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad
{	
	// Calculate table height
	UIImage *background = [UIImage imageNamed:@"table-cell-bg.png"];
	CGFloat tableHeight = [[self stopGroup] numberOfStops] * background.size.height;
	
	// Set up header image
	NSString *headerImageSrc = [stopGroup getHeaderPortraitImage];
	if (headerImageSrc == nil) {
		headerImageSrc = [stopGroup getHeaderLandscapeImage];
	}
	if (headerImageSrc != nil) {
		
		// Set up image
		NSBundle *tourBundle = [((TourController*)[self navigationController]) tourBundle];
		NSString *imagePath = [tourBundle pathForResource:[[headerImageSrc lastPathComponent] stringByDeletingPathExtension]
												   ofType:[[headerImageSrc lastPathComponent] pathExtension]
											  inDirectory:[headerImageSrc stringByDeletingLastPathComponent]];
		imageView = [[TapDetectingImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:imagePath]];
		[imageView setDelegate:self];
		
		// Calculate image scale
		CGFloat scale = scrollView.frame.size.width / imageView.image.size.width;
		
		// Setup scroll view
		if (self.view.frame.size.height - tableHeight > imageView.image.size.height * scale) {
			[scrollView setFrame:CGRectMake(0, 0, scrollView.frame.size.width, imageView.image.size.height * scale)];
			lastRowNeedsPadding = ((self.view.frame.size.height - tableHeight) - (imageView.image.size.height * scale)) > background.size.height;
		}
		else {
			[scrollView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - tableHeight)];
			lastRowNeedsPadding = YES;
		}
		[scrollView setBackgroundColor:[UIColor blackColor]];
		[scrollView setMinimumZoomScale: scale];
		[scrollView setMaximumZoomScale: scale];
		[scrollView setZoomScale:scale];
		[scrollView setContentSize:imageView.frame.size];
		if (imageView.frame.size.height > scrollView.frame.size.height) {
			[scrollView scrollRectToVisible:CGRectMake(0, (imageView.frame.size.height - scrollView.frame.size.height) / 2, scrollView.frame.size.width, scrollView.frame.size.height) animated:NO];
		}
		[scrollView addSubview:imageView];
	}
	else {
		
		// Hide scroll view
		[scrollView setFrame:CGRectMake(0, 0, self.view.frame.size.width, 0)];
		[scrollView setHidden:YES];
	}
	
	// Set up table
	[stopTableShadow setFrame:[stopTableShadow bounds]];
	[stopTable addSubview:stopTableShadow];
	[stopTable setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"table-bg.png"]]];
	[stopTable setRowHeight:[background size].height];
	[stopTable setFrame:CGRectMake(0, scrollView.frame.origin.y + scrollView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - scrollView.frame.size.height)];
	[stopTable setScrollEnabled:NO];
	
	// Setup audio controls
	[progressView setFlipped:YES];
	[progressBar setMaximumTrackImage:[UIImage imageNamed:@"audio-slider-minimum.png"] forState:UIControlStateNormal];
	[progressBar setMinimumTrackImage:[UIImage imageNamed:@"audio-slider-maximum.png"] forState:UIControlStateNormal];
	[progressBar setThumbImage:[UIImage imageNamed:@"audio-handle.png"] forState:UIControlStateNormal];
	[volumeView setFrame:CGRectMake(0, scrollView.frame.size.height - volumeView.frame.size.height, volumeView.frame.size.width, volumeView.frame.size.height)];
//	[volumeSlider setMaximumTrackImage:[UIImage imageNamed:@"audio-slider-minimum.png"] forState:UIControlStateNormal];
//	[volumeSlider setMinimumTrackImage:[UIImage imageNamed:@"audio-slider-maximum.png"] forState:UIControlStateNormal];
//	[volumeSlider setThumbImage:[UIImage imageNamed:@"audio-handle.png"] forState:UIControlStateNormal];
//	[volumeSlider setHidden:YES];

	// Replace volume slider with MPVolumeView so it's tied to the system audio
	MPVolumeView *systemVolumeSlider = [[MPVolumeView alloc] initWithFrame:[volumeSlider frame]];
	[[volumeSlider superview] addSubview:systemVolumeSlider];
	[volumeSlider removeFromSuperview];
	[volumeSlider release];
	[systemVolumeSlider release];
	
	// Setup up movie player
	moviePlayerHolder = [[UIView alloc] initWithFrame:[scrollView frame]];
	moviePlayerController = [[MPMoviePlayerController alloc] init];
	[[moviePlayerController view] setFrame:[imageView frame]];
	[moviePlayerController setShouldAutoplay:YES];
	[moviePlayerController setControlStyle:MPMovieControlStyleNone];
	[moviePlayerController setScalingMode:MPMovieScalingModeAspectFill];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayerDurationAvailable:) name:MPMovieDurationAvailableNotification object:moviePlayerController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayerPlaybackStateDidChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:moviePlayerController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlayerPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:moviePlayerController];
	[moviePlayerHolder addSubview:[moviePlayerController view]];
	moviePlayerTapDetector = [[TapDetectingView alloc] initWithFrame:[scrollView bounds]];
	[moviePlayerTapDetector setDelegate:self];
	[moviePlayerHolder addSubview:moviePlayerTapDetector];
	[moviePlayerHolder setAlpha:0.0f];
}

- (void)viewWillAppear:(BOOL)animated
{
	// Deselect anything from the table
	[stopTable deselectRowAtIndexPath:[stopTable indexPathForSelectedRow] animated:animated];
	[self willRotateToInterfaceOrientation:[self interfaceOrientation] duration:0.0];
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{	
	// Check for intro
	if (firstRun) {
		firstRun = NO;
		BaseStop *refStop = [[self stopGroup] stopAtIndex:0];
		if ([refStop isKindOfClass:[VideoStop class]] &&
			[(VideoStop *)refStop isAudio]) {
			VideoStop *audioStop = (VideoStop *)refStop;
			NSString *audioSrc = [audioStop getSourcePath];
			if ([self audioStopIsVideo:audioStop]) {
				[self playVideo:audioSrc];
			}
			else {
				[self playAudio:audioSrc];
				[self showControls];
			}
			[stopTable selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
		}
	}
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self stopAudio];
	[self stopVideo];
	[super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark TapDetectingImageViewDelegate

- (void)tapDetectingImageView:(TapDetectingImageView *)view gotSingleTapAtPoint:(CGPoint)tapPoint
{
	if ([progressView isHidden]) {
		[self showControls];
	}
	else {
		[self hideControls];
	}
}

#pragma mark -
#pragma mark TapDetectingViewDelegate

- (void)tapDetectingView:(TapDetectingView *)view gotSingleTapAtPoint:(CGPoint)tapPoint
{
	[self cancelControlsTimer];
	if ([progressView isHidden]) {
		[self showControls];
	}
	else {
		[self hideControls];
	}
}

#pragma mark -
#pragma mark Controls

- (void)showControls
{
	[progressView setHidden:NO];
	[progressView setAlpha:0.0f];
	[volumeView setHidden:NO];
	[volumeView setAlpha:0.0f];
	[UIView animateWithDuration:0.25f animations:^{
		[progressView setAlpha:1.0f];
		[volumeView setAlpha:1.0f];
	}];
	
}

- (void)showControlsAndFadeOut:(NSTimeInterval)seconds
{
	[self showControls];
	if (controlsTimer) {
		[controlsTimer invalidate];
	}
	controlsTimer = [[NSTimer scheduledTimerWithTimeInterval:2.5f target:self selector:@selector(hideControls) userInfo:nil repeats:NO] retain];
}

- (void)hideControls
{
	[UIView animateWithDuration:0.25f animations:^{
		[progressView setAlpha:0.0f];
		[volumeView setAlpha:0.0f];
	} completion:^(BOOL finished){
		[progressView setHidden:YES];
		[volumeView setHidden:YES];
	}];
}

- (void)cancelControlsTimer
{
	if (controlsTimer) {
		[controlsTimer invalidate];
		[controlsTimer release];
		controlsTimer = nil;
	}	
}

- (void)togglePlay
{
	[playButton setImage:[UIImage imageNamed:@"audio-play-up.png"] forState:UIControlStateNormal];
	[playButton setImage:[UIImage imageNamed:@"audio-play-down.png"] forState:UIControlStateSelected];
}

- (void)togglePause
{
	[playButton setImage:[UIImage imageNamed:@"audio-pause-up.png"] forState:UIControlStateNormal];
	[playButton setImage:[UIImage imageNamed:@"audio-pause-down.png"] forState:UIControlStateSelected];
}

- (IBAction)progressSliderTouchDown:(UISlider *)sender
{
	[self cancelControlsTimer];
	if ([[moviePlayerController view] isDescendantOfView:[self view]]) {
		[moviePlayerController pause];
		isSeeking = YES;
	}
}

- (IBAction)progressSliderTouchUp:(UISlider *)sender
{
	if ([[moviePlayerController view] isDescendantOfView:[self view]]) {
		if (moviePlayerIsPlaying && [moviePlayerController playbackState] != MPMoviePlaybackStatePlaying) {
			[moviePlayerController play];
		}
		isSeeking = NO;
	}
}

- (IBAction)progressSliderMoved:(UISlider *)sender
{
	if ([[moviePlayerController view] isDescendantOfView:[self view]]) {
		moviePlayerController.currentPlaybackTime = sender.value;
		[self updateCurrentTimeForVideoPlayer];
	}
	else {
		audioPlayer.currentTime = sender.value;
		[self updateCurrentTimeForAudioPlayer];
	}
}

- (IBAction)playButtonPressed:(UIButton *)sender
{
	[self cancelControlsTimer];
	if ([[moviePlayerController view] isDescendantOfView:[self view]]) {
		if ([moviePlayerController playbackState] == MPMoviePlaybackStatePlaying) {
			[moviePlayerController pause];
		}
		else {
			[moviePlayerController play];
		}
		[self updateViewForVideoPlayerState];
	}
	else {
		if (audioPlayer.playing) {
			[audioPlayer pause];
		}
		else {
			[audioPlayer play];
		}
		[self updateViewForAudioPlayerState];
	}
}

- (IBAction)volumeSliderMoved:(UISlider *)sender
{
	audioPlayer.volume = [sender value];
}

#pragma mark -
#pragma mark Audio Player

- (BOOL)audioStopIsVideo:(VideoStop *)audioStop
{
	NSString *audioSrc = [audioStop getSourcePath];
	NSString *audioExtension = [[audioSrc pathExtension] lowercaseString];
	if ([audioExtension isEqualToString:@"mp4"]) {
		return YES;
	}
	return NO;
}

- (void)playAudio:(NSString *)audioSrc
{	
	// Get path to sound
	NSBundle *tourBundle = [((TourController*)[self navigationController]) tourBundle];
	NSString *audioPath = [tourBundle pathForResource:[[audioSrc lastPathComponent] stringByDeletingPathExtension]
											   ofType:[[audioSrc lastPathComponent] pathExtension]
										  inDirectory:[audioSrc stringByDeletingLastPathComponent]];

	// Check to see if file exists in bundle
	if (!audioPath) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Loading Audio" message:@"The audio file for this stop could not be found." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
		[alertView release];
		[stopTable deselectRowAtIndexPath:[stopTable indexPathForSelectedRow] animated:YES];
		return;
	}
	
	// Check to see if it or anything is playing
	NSURL *audioUrl = [[NSURL alloc] initFileURLWithPath:audioPath];
	if (audioPlayer) {
		if ([audioUrl isEqual:[audioPlayer url]]) {
			[audioUrl release];
			return;
		}
		[audioPlayer stop];
	}
	
	// Play sound
	audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioUrl error:nil];
	if (audioPlayer) {
		[audioPlayer play];
		[self updateViewForAudioPlayerInfo];
		[self updateViewForAudioPlayerState];
		[audioPlayer setDelegate:self];
	}
	[audioUrl release];
}

- (void)stopAudio
{
	if (audioPlayer) {
		[audioPlayer stop];
		[audioPlayer release];
		audioPlayer = nil;
	}
}

- (void)updateViewForAudioPlayerInfo
{
	duration.text = [NSString stringWithFormat:@"%d:%02d", (int)audioPlayer.duration / 60, (int)audioPlayer.duration % 60, nil];
	progressBar.maximumValue = audioPlayer.duration;
}

- (void)updateViewForAudioPlayerState
{
	[self updateCurrentTimeForAudioPlayer];
	if (updateTimer) {
		[updateTimer invalidate];
		updateTimer = nil;
	}
	if (audioPlayer.playing) {
		[self togglePause];
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(updateCurrentTimeForAudioPlayer) userInfo:audioPlayer repeats:YES];
	}
	else {
		[self togglePlay];
	}
}

- (void)updateCurrentTimeForAudioPlayer
{
	currentTime.text = [NSString stringWithFormat:@"%d:%02d", (int)audioPlayer.currentTime / 60, (int)audioPlayer.currentTime % 60, nil];
	progressBar.value = audioPlayer.currentTime;
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	[audioPlayer setCurrentTime:0.0f];
	[self updateViewForAudioPlayerState];
}

- (void)playerDecodeErrorDidOccur:(AVAudioPlayer *)p error:(NSError *)error
{
	// Alert?
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)p
{
	[self updateViewForAudioPlayerState];
}

#pragma mark -
#pragma mark Video Player

- (void)playVideo:(NSString *)videoSrc
{
	// Get path to video
	NSBundle *tourBundle = [((TourController*)[self navigationController]) tourBundle];
	NSString *videoPath = [tourBundle pathForResource:[[videoSrc lastPathComponent] stringByDeletingPathExtension]
											   ofType:[[videoSrc lastPathComponent] pathExtension]
										  inDirectory:[videoSrc stringByDeletingLastPathComponent]];
	
	// Check to see if file exists in bundle
	if (!videoPath) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Loading Video" message:@"The video file for this stop could not be found." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
		[alertView release];
		[stopTable deselectRowAtIndexPath:[stopTable indexPathForSelectedRow] animated:YES];
		return;
	}
	
	// Load video
	NSURL *videoUrl = [NSURL fileURLWithPath:videoPath];
	if ([[moviePlayerController contentURL] isEqual:videoUrl]) {
		[moviePlayerController setCurrentPlaybackTime:0.0f];
		[moviePlayerController play];
	}
	else {
		[moviePlayerController setContentURL:videoUrl];
	}
	
	// Add video to stage if needed and fade in
	if (![moviePlayerHolder isDescendantOfView:[self view]]) {
		[[self view] insertSubview:moviePlayerHolder belowSubview:progressView];
	}
	if ([moviePlayerHolder alpha] < 1.0f) {
		[UIView animateWithDuration:0.5f animations:^{
			[moviePlayerHolder setAlpha:1.0f];
		}];
	}
	
	// Fade in controls
	[self showControlsAndFadeOut:4.0f];
}

- (void)stopVideo
{
	[moviePlayerController stop];
}

- (void)hideVideo
{
	[self stopVideo];
	if ([moviePlayerHolder isDescendantOfView:[self view]]) {
		[UIView animateWithDuration:0.5f animations:^{
			[moviePlayerHolder setAlpha:0.0f];
		} completion:^(BOOL finished) {
			[moviePlayerHolder removeFromSuperview];
		}];
	}
}

- (void)videoPlayerDurationAvailable:(NSNotification *)notification
{
	[self updateViewForVideoPlayerInfo];
}

- (void)videoPlayerPlaybackStateDidChange:(NSNotification *)notification
{
	[self updateViewForVideoPlayerState];
}

- (void)videoPlayerPlaybackDidFinish:(NSNotification *)notification
{
	[self updateViewForVideoPlayerState];
}

- (void)updateViewForVideoPlayerInfo
{
	duration.text = [NSString stringWithFormat:@"%d:%02d", (int)moviePlayerController.duration / 60, (int)moviePlayerController.duration % 60, nil];
	progressBar.maximumValue = moviePlayerController.duration;
}

- (void)updateViewForVideoPlayerState
{
	[self updateCurrentTimeForVideoPlayer];
	if (updateTimer) {
		[updateTimer invalidate];
		updateTimer = nil;
	}
	if ([moviePlayerController playbackState] == MPMoviePlaybackStatePlaying) {
		[self togglePause];
		moviePlayerIsPlaying = YES;
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(updateCurrentTimeForVideoPlayer) userInfo:moviePlayerController repeats:YES];
	}
	else {
		if (!isSeeking) {
			[self togglePlay];
			moviePlayerIsPlaying = NO;
		}
	}
}

- (void)updateCurrentTimeForVideoPlayer
{
	currentTime.text = [NSString stringWithFormat:@"%d:%02d", (int)moviePlayerController.currentPlaybackTime / 60, (int)moviePlayerController.currentPlaybackTime % 60, nil];
	if (!isSeeking) {
		progressBar.value = moviePlayerController.currentPlaybackTime;
	}
}

#pragma mark -
#pragma mark UIScrollViewDelegate 

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return imageView;
}

#pragma mark -
#pragma mark UITableViewDataSource

/**
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [[self stopGroup] getTitle];
}
**/

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self stopGroup] numberOfStops];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger idx = [indexPath row];
	BaseStop *refStop = [[self stopGroup] stopAtIndex:idx];
	static NSString *cellIdent = @"stop-group-cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdent];
	if (cell == nil) {
		
		// Create a new reusable table cell
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdent] autorelease];
		
		// Set the background
		UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table-cell-bg.png"]];
		[cell setBackgroundView:background];
		[background release];
		UIImageView *selectedBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table-cell-bg-selected.png"]];
		[cell setSelectedBackgroundView:selectedBackground];
		[selectedBackground release];
		
		// Init the label
		[[cell textLabel] setOpaque:NO];
		[[cell textLabel] setBackgroundColor:[UIColor clearColor]];
		[[cell textLabel] setFont:[UIFont systemFontOfSize:18]];
		[[cell textLabel] setTextColor:[UIColor whiteColor]];
		
		// Init the description
//		[[cell detailTextLabel] setFont:[UIFont systemFontOfSize:12]];
//		[[cell detailTextLabel] setTextColor:[UIColor whiteColor]];
//		[[cell detailTextLabel] setNumberOfLines:2];
		
		// Set the custom disclosure indicator
//		UIImageView *disclosure = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table-cell-disclosure.png"]];
//		[cell setAccessoryView:disclosure];
//		[disclosure release];
	}
	
	// Set the title
	[[cell textLabel] setText:[refStop getTitle]];
	if (idx == [[self stopGroup] numberOfStops] - 1 && lastRowNeedsPadding) {
		UIView *padding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width * 0.1, 10)];
		[cell setAccessoryView:padding];
		[padding release];
	}
	else {
		[cell setAccessoryView:nil];
	}
	
	// Set the description if available
	//[[cell detailTextLabel] setText:[refStop getDescription]];
	
	// Set the associated icon
	[[cell imageView] setImage:[UIImage imageWithContentsOfFile:[refStop getIconPath]]];
	
	return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

/**
 * ref: http://www.iphonedevsdk.com/forum/iphone-sdk-development/3739-how-should-i-display-detail-view-variable-length-strings.html
 */
/**
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger idx = [indexPath row];
	BaseStop *refStop = [[self stopGroup] stopAtIndex:idx];
		
	CGFloat result = 44.0f;
	NSString *text = [refStop getDescription];
	CGFloat width = 0;
	CGFloat tableViewWidth;
	CGRect bounds = [UIScreen mainScreen].bounds;
	
	if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
		tableViewWidth = bounds.size.width;
	} else {
		tableViewWidth = bounds.size.height;
	}
	width = tableViewWidth - 110;		// fudge factor
	
	if (text) {
		// The notes can be of any height
		// This needs to work for both portrait and landscape orientations.
		// Calls to the table view to get the current cell and the rect for the 
		// current row are recursive and call back this method.
		CGSize textSize = { width, 20000.0f };		// width and height of text area
		CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:17.0f] constrainedToSize:textSize lineBreakMode:UILineBreakModeWordWrap];
		
		size.height += 29.0f;			// top and bottom margin
		result = MAX(size.height, 44.0f);	// at least one row
	}
	
	NSLog(@"Calculated row height of %.0f for text: %@", result, text);
	
	return result;
}
 **/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
	// Stop any audio or video
	[self stopAudio];
	[self stopVideo];
	
	// Take action for selection
	NSUInteger idx = [indexPath indexAtPosition:1];
	BaseStop *refStop = [[self stopGroup] stopAtIndex:idx];
	if ([refStop isKindOfClass:[VideoStop class]] &&
		[(VideoStop *)refStop isAudio]) {
		VideoStop *audioStop = (VideoStop *)refStop;
		if ([self audioStopIsVideo:audioStop]) {
			[(TourController *)[self navigationController] loadStop:audioStop];
		}
		else {
			NSString *audioSrc = [audioStop getSourcePath];
			[self playAudio:audioSrc];
			[self showControls];
		}
	}
	else {
		[self hideControls];
		[(TourController *)[self navigationController] loadStop:refStop];
	}
}

@end
