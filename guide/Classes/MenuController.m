//
//  MenuController.m
//  MFA Guide
//
//  Created by Robert Brecher on 9/20/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "MenuController.h"

#import "CoreDataManager.h"
#import "LoadingView.h"
#import "TapAppDelegate.h"
#import "Tour.h"
#import "Tour+SortWeightCompare.h"
#import "UpdaterController.h"

@interface MenuController (PrivateMethods)

- (void)updateButtonSelected:(id)sender;

@end


@implementation MenuController

@synthesize tours;

- (void)viewDidLoad {
    [super viewDidLoad];
	[toursView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"table-bg.png"]]];
}

#pragma mark -
#pragma mark View Events

- (void)viewWillAppear:(BOOL)animated
{
	[self refresh];
	[super viewWillAppear:animated];
}

#pragma mark -
#pragma mark Updater

- (void)refresh
{
	[self setTours:[[CoreDataManager getTours] sortedArrayUsingSelector:@selector(sortWeightCompare:)]];
	if ([tours count]) {
		[toursView reloadData];
	}
//	else {
		UIBarButtonItem *updateButton = [[UIBarButtonItem alloc] initWithTitle:@"Update" style:UIBarButtonItemStylePlain target:self action:@selector(updateButtonSelected:)];
		[[navigationBar topItem] setRightBarButtonItem:updateButton];
		[updateButton release];
//	}
}

- (void)showUpdater
{
	UpdaterController *updaterController = [[UpdaterController alloc] init];
	[updaterController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
	[self presentModalViewController:updaterController animated:YES];
}

- (IBAction)updateButtonSelected:(id)sender
{
	[self showUpdater];
}

#pragma mark -
#pragma mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tours count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    
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
		
		// Set the custom disclosure indicator
		UIImageView *disclosure = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"table-cell-disclosure.png"]];
		[cell setAccessoryView:disclosure];
		[disclosure release];
	}
	
	Tour *tour = [tours objectAtIndex:[indexPath row]];
    cell.textLabel.text = [tour title];
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	Tour *tour = [tours objectAtIndex:[indexPath row]];
    [(TapAppDelegate *)[[UIApplication sharedApplication] delegate] loadTourWithBundleName:[tour bundleName]];
}

#pragma mark -
#pragma mark Memory Management

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
	[tours release];
    [super dealloc];
}


@end
