//
//  UpdaterController.m
//  MFA Guide
//
//  Created by Robert Brecher on 9/20/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "UpdaterController.h"

#import "CoreDataManager.h"
#import "UpdaterControllerCell.h"
#import "ToursXMLTour.h"

enum {
	kDataProviderErrorAlert = 0,
	kBundleManagerErrorAlert = 1,
	kCheckingForUpdatesAlert = 2,
	kUpdatesAvailableAlert = 3,
	kNoUpdatesAvailableAlert = 4
};

enum {
	kCheckForUpdatesAction = 0,
	kUpdateAction = 1,
	kCancelAction = 2,
	kNoAction = 3
};

#pragma mark -
#pragma mark UpdaterController

@interface UpdaterController (PrivateMethods)

- (void)getToursFromCoreData;
- (void)updateAll;
- (void)updateProgressForCurrentBundle:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles;
- (void)setCurrentBundleAsUpdated;
- (UpdaterControllerCell *)cellForBundleName:(NSString *)bundleName;
- (void)completeUpdate;
- (void)addToConsole:(NSString *)text;

@end

@implementation UpdaterController

@synthesize currentViewContainer, currentView, tours, availableTours, currentBundle, updater;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	// init tours
	[self getToursFromCoreData];
	[self setAvailableTours:[NSMutableArray array]];
	[self setCurrentView:toursView];
	
	// init console
	[consoleView setFont:[UIFont fontWithName:@"Helvetica" size:12.0]];
	[consoleView removeFromSuperview];
	
	// create updater
	updater = [[Updater alloc] init];
	[updater setDelegate:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
	[backButton release];
	[utilityButton release];
	[toggleButton release];
	[currentViewContainer release];
	[currentView release];
	[toursView release];
	[tours release];
	[consoleView release];
	[progress release];
	[progressFilename release];
	[progressView release];
	[updater release];
    [super dealloc];
}

#pragma mark -
#pragma mark View Events

- (void)viewDidAppear:(BOOL)animated
{	
	[updater checkForUpdates];
	[self addToConsole:@"Checking for updates..."];
	[super viewDidAppear:animated];
}

#pragma mark -
#pragma mark Data

- (void)getToursFromCoreData
{
	NSArray *coreDataTours = [CoreDataManager getTours];
	if (tours) {
		[tours removeAllObjects];
		[tours release];
	}
	tours = [[NSMutableArray alloc] init];
	for (NSUInteger i = 0; i < [coreDataTours count]; i++)
	{
		NSMutableDictionary *tourLookup = [[NSMutableDictionary alloc] init];
		[tourLookup setObject:[coreDataTours objectAtIndex:i] forKey:@"tour"];
		[tours addObject:tourLookup];
		[tourLookup release];
	}
}

- (void)checkUpdatableTours:(NSArray *)updatableTours
{
	if ([availableTours count]) {
		[availableTours removeAllObjects];
	}
	for (NSUInteger i = 0; i < [updatableTours count]; i++) {
		ToursXMLTour *updatableTour = [updatableTours objectAtIndex:i];
		NSNumber *updatableTourId = [updatableTour id];
		NSUInteger tourIndex = [tours indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
			NSDictionary *tourLookup = (NSDictionary *)obj;
			Tour *tour = [tourLookup objectForKey:@"tour"];
			if ([updatableTourId isEqual:[tour id]]) {
				return YES;
			}
			return NO;
		}];
		if (tourIndex != NSNotFound) {
			NSDictionary *tourLookup = [tours objectAtIndex:tourIndex];
			[tourLookup setValue:updatableTour forKey:@"xml"];
		}
		else {
			[availableTours addObject:updatableTour];
		}
	}
	[toursView reloadData];
}

#pragma mark -
#pragma mark UI

- (IBAction)backSelected:(id)sender
{
	[updater cancel];
	[[self parentViewController] dismissModalViewControllerAnimated:YES];
}

- (void)toggleDisplay:(id)sender
{
	if ([currentView isEqual:toursView]) {
		[UIView transitionFromView:toursView toView:consoleView duration:1.0f options:UIViewAnimationOptionTransitionFlipFromLeft completion:nil];
		[self setCurrentView:consoleView];
		[toggleButton setTitle:@"List"];
	}
	else {
		[UIView transitionFromView:consoleView toView:toursView duration:1.0f options:UIViewAnimationOptionTransitionFlipFromRight completion:nil];
		[self setCurrentView:toursView];
		[toggleButton setTitle:@"Console"];
	}
}

- (IBAction)utilityButtonSelected:(id)sender
{
	switch (utilityButtonAction) {
		case kCheckForUpdatesAction: {
			[updater checkForUpdates];
			break;
		}
		case kUpdateAction: {
			[self updateAll];
			break;
		}
		case kCancelAction: {
			[updater cancel];
			[self completeUpdate];
			[progress setHidden:YES];
			[utilityButton setEnabled:YES];
			[utilityButton setTitle:@"Update"];
			utilityButtonAction = kUpdateAction;
			break;
		}
		default: {
			break;
		}
	}
}

- (void)updateAll
{
	encounteredErrors = NO;
	[updater performUpdate];
	[utilityButton setEnabled:YES];
	[utilityButton setTitle:@"Cancel"];
	utilityButtonAction = kCancelAction;
}

- (void)updateProgressForCurrentBundle:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles
{
	// Update progress
	UpdaterControllerCell *cell = [self cellForBundleName:currentBundle];
	if (cell) {
		[[cell detailTextLabel] setHidden:YES];
		[[cell progressView] setHidden:NO];
		[[cell progressView] setProgress:(float)fileNumber / (float)totalFiles];
		[[cell fileCount] setHidden:NO];
		[[cell fileCount] setText:[NSString stringWithFormat:@"%lu / %lu", fileNumber, totalFiles]];
	}
}

- (void)setCurrentBundleAsUpdated
{
	UpdaterControllerCell *cell = [self cellForBundleName:currentBundle];
	if (cell) {
		[[cell progressView] setHidden:YES];
		[[cell fileCount] setHidden:YES];
		[[cell detailTextLabel] setHidden:NO];
		[[cell detailTextLabel] setTextColor:[UIColor grayColor]];
		[[cell detailTextLabel] setText:@"Updated!"];
	}
}

- (UpdaterControllerCell *)cellForBundleName:(NSString *)bundleName
{
	// Check current tours first
	NSUInteger tourIndex = [tours indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
		NSDictionary *tourLookup = (NSDictionary *)obj;
		Tour *tour = [tourLookup objectForKey:@"tour"];
		if ([currentBundle isEqual:[tour bundleName]]) {
			return YES;
		}
		return NO;
	}];
	if (tourIndex != NSNotFound) {
		return (UpdaterControllerCell *)[toursView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:tourIndex inSection:0]];
	}
		
	// Check available tours next
	tourIndex = [availableTours indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
		ToursXMLTour *xml = (ToursXMLTour *)obj;
		if ([currentBundle isEqual:[xml bundleName]]) {
			return YES;
		}
		return NO;
	}];
	if (tourIndex != NSNotFound) {
		return (UpdaterControllerCell *)[toursView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:tourIndex inSection:1]];
	}
	return nil;
}

- (void)completeUpdate
{	
	[self getToursFromCoreData];
	[self checkUpdatableTours:[updater updatableTours]];
	[toursView reloadData];
}

- (void)addToConsole:(NSString *)text
{
	[consoleView setText:[NSString stringWithFormat:@"%@\n%@", text, [consoleView text]]];
}

- (NSString *)stringForFileSize:(NSInteger)bytes
{
	if (bytes < 1024) {
        return [NSString stringWithFormat:@"%ldB", bytes];
    }
	if (bytes < (1024.0 * 1024.0 * 0.1)) {
		return [NSString stringWithFormat:@"%0.1fKB", (float)bytes / 1024.0];
    }
	if (bytes < (1024.0 * 1024.0 * 1024.0 * 0.1)) {
		return [NSString stringWithFormat:@"%0.1fMB", (float)bytes / (1024.0 * 1024.0)];
    }
	return [NSString stringWithFormat:@"%0.1fGB", (float)bytes / (1024.0 * 1024.0 * 1024.0)];
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return @"Installed Tours";
		case 1:
			return @"Available Tours";
		default:
			return @"";
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{	
	switch (section) {
		case 0:
			return [tours count];
		case 1:
			return [availableTours count];
		default:
			return 0;
	}	
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Get reusable cell
	static NSString *cellIdent = @"updater-cell";
	UpdaterControllerCell *cell = (UpdaterControllerCell *)[tableView dequeueReusableCellWithIdentifier:cellIdent];
	if (cell == nil) {
		NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"UpdaterCell" owner:self options:nil];
		cell = [nibContents objectAtIndex:0];
	}
	
	// Setup cell
	switch ([indexPath section]) {
		case 0: {
			NSDictionary *tourLookup = [tours objectAtIndex:[indexPath row]];
			Tour *tour = [tourLookup objectForKey:@"tour"];
			[[cell textLabel] setText:[tour title]];
			if (!updater || [updater isChecking]) {
				[[cell detailTextLabel] setText:@"Checking for updates..."];
				[[cell detailTextLabel] setTextColor:[UIColor grayColor]];
			}
			else {
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
				ToursXMLTour *xml = [tourLookup objectForKey:@"xml"];
				if (xml) {
					[[cell detailTextLabel] setText:[NSString stringWithFormat:@"Updated on %@", [xml updatedDate]]];
					[[cell detailTextLabel] setTextColor:[UIColor greenColor]];
				}
				else if ([[tour errors] boolValue]) {
					[[cell detailTextLabel] setText:[NSString stringWithFormat:@"Errors on %@", [dateFormatter stringFromDate:[tour updatedDate]]]];
					[[cell detailTextLabel] setTextColor:[UIColor redColor]];
				}
				else {
					[[cell detailTextLabel] setText:[NSString stringWithFormat:@"Last Updated on %@", [dateFormatter stringFromDate:[tour updatedDate]]]];
					[[cell detailTextLabel] setTextColor:[UIColor grayColor]];
				}
				[dateFormatter release];
			}
			break;
		}
		case 1: {
			ToursXMLTour *xml = [availableTours objectAtIndex:[indexPath row]];
			[[cell textLabel] setText:[xml title]];
			[[cell detailTextLabel] setText:[NSString stringWithFormat:@"Updated on %@", [xml updatedDate]]];
			[[cell detailTextLabel] setTextColor:[UIColor greenColor]];
			[[cell detailTextLabel] setHidden:NO];
			[[cell progressView] setHidden:YES];
			[[cell fileCount] setHidden:YES];
			break;
		}
		default: {
			break;
		}
	}
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate Methods

#pragma mark -
#pragma mark UpdaterDelegate Methods

- (void)updater:(Updater *)theUpdater didFailWithError:(NSError *)error
{
	[self addToConsole:[NSString stringWithFormat:@"Error: %@", [error localizedDescription]]];
}

- (void)updaterDidFailToRetrieveToursXML:(Updater *)updater
{
	[self addToConsole:@"Failed to retrieve tours.xml"];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error with tours.xml" 
														message:@"Failed to retrieve tours.xml, would you like to try again?" 
													   delegate:self 
											  cancelButtonTitle:@"No" 
											  otherButtonTitles:@"Yes", nil];
	[alertView setTag:kDataProviderErrorAlert];
	[alertView show];
	[alertView release];
}

- (void)updater:(Updater *)theUpdater hasAvailableUpdates:(NSUInteger)availableUpdates
{
	if (availableUpdates) {
		[self checkUpdatableTours:[theUpdater updatableTours]];
		[self addToConsole:[NSString stringWithFormat:@"%lu updates available", availableUpdates]];
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Available Updates" 
															message:@"Would you like to update now?" 
														   delegate:self 
												  cancelButtonTitle:@"No" 
												  otherButtonTitles:@"Yes", nil];
		[alertView setTag:kUpdatesAvailableAlert];
		[alertView show];
		[alertView release];
	}
	else {
		[self addToConsole:@"No updates available"];
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Updates Available" 
															message:@"There are no updates available at this time." 
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
		[alertView setTag:kNoUpdatesAvailableAlert];
		[alertView show];
		[alertView release];
	}
}

- (void)updater:(Updater *)theUpdater didStartUpdatingBundle:(NSString *)bundleName
{
	[self setCurrentBundle:bundleName];
	[self addToConsole:[NSString stringWithFormat:@"Starting Bundle: %@", bundleName]];
}

- (void)updater:(Updater *)theUpdater didFinishUpdatingBundle:(NSString *)bundleName
{
	if ([updater didEncounterErrors]) {
		encounteredErrors = YES;
	}
	[self setCurrentBundleAsUpdated];
	[self addToConsole:[NSString stringWithFormat:@"Finished Bundle: %@", bundleName]];
}

- (void)updater:(Updater *)theUpdater didStartUpdatingFile:(NSString *)pathToFile fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles
{
	if (fileNumber == 1) {
		[self updateProgressForCurrentBundle:0 outOf:totalFiles];
	}
	[progress setHidden:NO];
	[progressFilename setText:[pathToFile lastPathComponent]];
	[progressView setProgress:0.0f];
}

- (void)updater:(Updater *)theUpdater didRecieveBytes:(NSInteger)bytes outOfTotalBytes:(NSInteger)totalBytes forFile:(NSString *)pathToFile
{
	[progressView setProgress:(float)bytes/(float)totalBytes];
	[progressAmount setText:[NSString stringWithFormat:@"%@ / %@", [self stringForFileSize:bytes], [self stringForFileSize:totalBytes]]];
}

- (void)updater:(Updater *)theUpdater didFinishUpdatingFile:(NSString *)pathToFile fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles
{	
	[self updateProgressForCurrentBundle:fileNumber outOf:totalFiles];
	[self addToConsole:[NSString stringWithFormat:@"Updated: %@", pathToFile]];
}

- (void)updaterDidFinish:(Updater *)theUpdater
{	
	if (encounteredErrors) {
		
		// alert for errors
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Errors Encountered" 
															message:@"Please check the console for details." 
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
		[alertView setTag:kBundleManagerErrorAlert];
		[alertView show];
		[alertView release];
		
		// enable update button
		[utilityButton setEnabled:YES];
		[utilityButton setTitle:@"Check for Updates"];
		utilityButtonAction = kCheckForUpdatesAction;
	}
	else {
		
		// disable update button
		[utilityButton setEnabled:NO];
		[utilityButton setTitle:@"Update"];
		utilityButtonAction = kNoAction;
	}
	
	// complete update
	[self completeUpdate];
	[self addToConsole:@"Done!"];
	[progress setHidden:YES];
}

#pragma mark -
#pragma mark UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch ([alertView tag]) {
		case kDataProviderErrorAlert: {
			if (buttonIndex == 1) {
				[updater checkForUpdates];
			}
			else {
				[utilityButton setEnabled:YES];
				[utilityButton setTitle:@"Check for Updates"];
				utilityButtonAction = kCheckForUpdatesAction;
			}
			break;
		}
		case kBundleManagerErrorAlert: {
			break;
		}
		case kUpdatesAvailableAlert: {
			if (buttonIndex == 1) {
				[self updateAll];
			}
			else {
				[utilityButton setEnabled:YES];
				[utilityButton setTitle:@"Update"];
				utilityButtonAction = kUpdateAction;
			}
			break;
		}
		case kNoUpdatesAvailableAlert: {
			break;
		}
		default: {
			break;
		}
	}
}

@end
